import numpy as np
import os
from skmultiflow.data.file_stream import FileStream
from skmultiflow.trees import HoeffdingTreeClassifier
from pf_eval_conventional import pf_evaluation
from oza_bagging_oob import OzaBagging_OOB


# overall setup
pre_train_num = 500


def oob_training_1data(model, stream_train, train_1data, y_1train, theta, rho0_ths, rho1_ths):
    """
    Update JIT-SDP model with the 1 training sample.
    """
    X_1train = train_1data[:, 1:]  # (timestamp, X)
    # compute rho1_tt and rho0_tt
    rho1_nxt = theta * rho1_ths + (1 - theta) * (1 if y_1train == 1 else 0)
    rho0_nxt = theta * rho0_ths + (1 - theta) * (1 if y_1train == 0 else 0)
    # update
    model, k_oob = model.partial_fit(X_1train, y_1train, rho0_nxt, rho1_nxt, classes=stream_train.target_values)
    [data_train_next, y_train_next] = stream_train.next_sample()
    return model, data_train_next, y_train_next, rho0_nxt, rho1_nxt, k_oob


def sdp_1call(wait_days=15, data_name="brackets", theta=0.99, M=20, T=5000, seed=0):
    """
    Run the JIT-SDP process with a given waiting time and parameter setting.
    The training and test data streams had been prepared in Matlab, which have been sorted ascendingly
    according to the training and evaluation timestamps, respectively.
    The package scikit-multiflow used in this experiment is Version 0.4.1.

    Parameters
        wait_days -- waiting time for training (evaluation waiting time is not handled as input para here)
        theta -- the time decay factor, OOB parameter
        M -- the number of base learners, OOB parameter
        T -- the number of test steps investigated in the experiments.

    A data stream scenario of the JIT-SDP process.
        Train              U1           U2    U3
        Timeline ....____|_*__|______|__*_____*__|____....
        Test            T1   T2     T3          T4

        "*" is a timestamp a training example is received, and denoted by lowercase "U".
        "|" is a timestamp a test example is about to predict, and denoted by uppercase "T".

        We can see that:
        1) There may be multiple test timestamps such as T2 and T3 to be predicted by the same JIT-SDP model.
            The model is updated at U1, when training example U2 is not available.
        2) The model updated at U3 would be used to predict the test data committed at test timestamp T4.
            That being said, the model updated at U2 is not actually used for prediction
            as U3 comes earlier than the most recent test timestamp T4.

    A data stream scenario showing that more than one training data between two test steps.
        train       U1  U2      U3       U4         training instances at U1 ~ U3 became available before T2
           -----|---*---*-------*---|----*-------   the timeline
        test   T1                  T2               T1 and T2 are test timestamps

    A data stream scenario showing that there are multiple invalid evaluation steps
        train                   U0         U1       U0 is the 1st training timestamp
           ----|--|----|-----|--*--|-------*-----   the timeline
        test  T0 T1   T2    T3    T4                test data at T4 is the first valid test step for prediction

    Liyan Song on 2019/11/, cleaned on Mar.2022
    """

    assert T > 0, "T denotes the length of the test data stream and thus be non-negative int"
    dir_data = "../data/"
    dir_rslt = "../rslt.python/rslt.save/%s/%dd/theta%.2f_M%d/T%d/" % (data_name, wait_days, theta, M, T)
    os.makedirs(dir_rslt, exist_ok=True)
    to_flnm_jit = dir_rslt + "oob_result.s%d" % seed
    if T == pre_train_num:
        exist_rslt = os.path.exists(to_flnm_jit)

    else:
        """for investigation of evaluation waiting times
        Note that please delete the folder entitled such as ".../T5000/evaluation_wait_time/result.s0"
        if the process is interrupted. That being said, we cannot keep part of the evaluation results, 
        otherwise, we cannot get the complete results to analyse the evaluation waiting time in RQ2 and RQ3.
        This procedure will take some time as we have to make predictions to test examples of various waiting times.
        """
        dir_rslt_eval = dir_rslt + "evaluation_wait_time/result.s%d/" % seed
        exist_rslt_eval = os.path.exists(dir_rslt_eval)
        exist_rslt = os.path.exists(to_flnm_jit) and exist_rslt_eval
        if not exist_rslt_eval:
            os.makedirs(dir_rslt_eval, exist_ok=True)

    # load the result or compute the JIT-SDP process
    if exist_rslt:  # load
        test_result = np.loadtxt(to_flnm_jit)
        test_y_tru, test_y_pre = test_result[:, 0], test_result[:, 1]

    else:  # compute
        print("%s: wtt=%d, sd=%d, (M=%d, theta=%.3f)." % (data_name, wait_days, seed, M, theta))

        rho0, rho1 = 0.5, 0.5  # OOB's ini para, fix
        model = OzaBagging_OOB(base_estimator=HoeffdingTreeClassifier(), n_estimators=M, random_state=seed)

        # training data stream, [time, X, y]
        stream_train = FileStream(dir_data + data_name + "_train_wait_days%d.csv" % wait_days)
        [train_1X, train_1y] = stream_train.next_sample()

        # test data stream, [time, X, y]
        stream_test = FileStream(dir_data + data_name + "_test.csv")
        # the first and the last test timestamps
        Data_tset_all, y_test_all = stream_test.next_sample(T)
        time_test_all = Data_tset_all[:, 0]
        X_test_all = Data_tset_all[:, 1:]
        time_tst_stt, time_tst_end = time_test_all[0], time_test_all[-1]
        np.savetxt(dir_rslt + "time_test_start", [time_tst_stt], fmt="%d")
        np.savetxt(dir_rslt + "time_test_end", [time_tst_end], fmt="%d")

        # the 1st test data
        stream_test.restart()
        [test_1X, test_1y] = stream_test.next_sample()
        assert train_1X[0, 0] < time_tst_end, \
            "The 1st training data %d comes later than the last test data %d." % (train_1X[0, 0], time_tst_end)

        # the JIT-SDP process
        test_y_tru, test_y_pre = [], []
        test_count, train_count = 0, 0
        while test_1X[0, 0] <= time_tst_end:
            # train process
            # check if new train data become available before a new prediction
            while train_1X[0, 0] <= test_1X[0, 0]:
                train_1X_latest = train_1X
                model, train_1X, train_1y, rho0, rho1, k_oob = \
                    oob_training_1data(model, stream_train, train_1X, train_1y, theta, rho0, rho1)
                train_count += 1

            # predict, skip invalid test steps
            if train_count > 0:
                y_tst_pre_ths = model.predict(test_1X[:, 1:])
                test_count += 1
                test_y_pre.append(y_tst_pre_ths[0])
                test_y_tru.append(test_1y[0])

                # for investigation of evaluation waiting times
                if T > pre_train_num:
                    use_steps = time_test_all >= train_1X_latest[0, 0]
                    time_test_all_surrogate = time_test_all[use_steps]
                    X_test_all_surrogate = X_test_all[use_steps, :]
                    y_test_all_tru_surrogate = y_test_all[use_steps]
                    # predict all the available test steps
                    y_test_all_pre_surrogate = model.predict(X_test_all_surrogate)

                    # for investigating evaluation waiting time, (test_time, y_true, y_pred)
                    results_surrogate = np.vstack(
                        (time_test_all_surrogate, y_test_all_tru_surrogate, y_test_all_pre_surrogate)).T
                    # save for investigating RQs
                    np.savetxt(dir_rslt_eval + str(int(train_1X_latest[0, 0])),
                               results_surrogate, fmt="%d, %d, %d", header="(test_time, y_true, y_pred)", comments="%")
            [test_1X, test_1y] = stream_test.next_sample()

        # save
        test_result = np.column_stack((test_y_tru, test_y_pre))
        np.savetxt(to_flnm_jit, test_result, fmt='%d\t %d', header="y_tru, y_pre)")
    return test_y_tru, test_y_pre


def sdp_para_tune(wait_days=15, data_name="brackets", theta_lst=[0.9, 0.99], M_lst=[5, 10, 20], seed_lst=range(30)):
    """
    Conduct parameter tuning of OOB ensemble with Hoeffding trees.
    Tuning parameters are (theta, M).

    Specifically,
    a grid search based on the first 500 (out of the total 5000) software changes in the test data stream
    was conducted to choose the parameter settings based on G-mean.
    The parameter settings include the decay factor theta {0.9, 0.99} and the ensemble size M {5, 10, 20}.
    Given a software project, the parameter combination leading to the best average G-mean across 30 runs
    at the first 500 time steps was chosen as the best parameter setting.
    The JIT-SDP process was then proceeded with the best parameter setting throughout the whole data stream.

    Liyan Song, Nov. 2019
    """

    if isinstance(seed_lst, int):
        seed_lst = [seed_lst]
    if isinstance(theta_lst, int):
        theta_lst = [theta_lst]
    if isinstance(M_lst, int):
        M_lst = [M_lst]

    # grid search based on the first 500 test steps
    Gmean_paras = np.empty((len(theta_lst), len(M_lst)))
    for th, theta in enumerate(theta_lst):
        for mm, M in enumerate(M_lst):
            Gmean_1para = np.empty((len(seed_lst)))
            for ss in range(len(seed_lst)):
                seed = seed_lst[ss]
                y_tru_ss, y_pre_ss = sdp_1call(wait_days, data_name, theta, M, pre_train_num, seed)
                Gmean_1para[ss] = pf_evaluation(y_tru_ss, y_pre_ss)
            Gmean_paras[th, mm] = np.mean(Gmean_1para)

    # the best para (theta,M)
    Gmean_ave_best = np.amax(Gmean_paras)
    rr, cc = np.where(Gmean_ave_best == Gmean_paras)
    # when more than one parameter settings can achieve the best G-mean, choose the 1st pair
    rr, cc = rr[0], cc[0]
    theta_best, M_best = theta_lst[int(rr)], M_lst[int(cc)]

    # save the best para (theta,M)
    todir_para = "../rslt.python/para.bst/%dd/" % wait_days
    os.makedirs(todir_para, exist_ok=True)
    to_flnm = todir_para + data_name
    np.savetxt(to_flnm, np.column_stack((theta_best, M_best)), fmt="%f %d",
               header="(theta_best, M_best)", comments="%")
    # theta_best, M_best = np.loadtxt(todir_para + data_name)

    print("\nThe best parameter setting is printed to %s" % to_flnm)
    return theta_best, M_best, Gmean_ave_best


def sdp_best_para(wait_days=15, data_name="brackets"):
    """
    Run JIT-SDP 30 times with the chosen parameter settings for a given project.
    Liyan Song, March 2022
    """
    theta_bst, M_bst, _ = sdp_para_tune(wait_days, data_name)
    for _, seed in enumerate(range(30)):
        sdp_1call(wait_days, data_name, theta_bst, M_bst, 5000, seed)
    print("\nSucceed in sdp_best_para()!\n")


if __name__ == "__main__":
    sdp_1call()
    # sdp_para_tune(wait_days=15, data_name="brackets")
    sdp_best_para(wait_days=15, data_name="brackets")  # run the whole process with the best para

