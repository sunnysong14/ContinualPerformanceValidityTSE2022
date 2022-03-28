import numpy as np
from math import sqrt


def pf_evaluation(y_true, y_predict):
    """
    Performance evaluation in the parameter tuning process with the first 500 test steps.
    Practically, the first 500 software changes have already been available altogether,
    and so the PF can be calculated in the conventional way.
    However, this function cannot be used in practice when the true labels of test data arrived with delay
    as the scenario investigated in this work.

    Parameters y_true and y_predict should be numpy.ndarray, and the values are {0, 1}.
    
    Liyan Song, Nov. 2019
    """

    # guarantee the data format of numpy
    y_true = np.array(y_true)
    y_predict = np.array(y_predict)
    is_defect = y_true == 1

    p = y_true[is_defect].shape[0]
    n = y_true[~is_defect].shape[0]
    N = p + n

    tp = np.sum(y_true[is_defect] == y_predict[is_defect])
    tn = np.sum(y_true[~is_defect] == y_predict[~is_defect])
    fp = n - tn
    fn = p - tp

    # evaluation metrics
    tpr = tp / p
    tnr = tn / n
    fnr = 1 - tpr
    fpr = 1 - tnr
    sensitivity = recall = tpr
    specificity = tnr
    acc = (tp + tn) / N
    prec = tp / (tp + fp)
    fmeas = 2 * (prec * recall) / (prec + recall)
    gmean = sqrt(tpr * tnr)

    return gmean

