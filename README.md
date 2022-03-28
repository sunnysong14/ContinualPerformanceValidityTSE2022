# ContinualPerformanceValidityTSE2022
 
This repository contains the Python and Matlab codes used for the paper: 
```
Liyan Song, Leandro L. Minku. “A Procedure to Continuously Evaluate Predictive Performance of Just-In-Time Software Defect Prediction Models During Software Development”, IEEE Transactions on Software Engineering, 2022
```

The Python part is used to implement the JIT-SDP process with various training waiting times along with all possible evaluation waiting times. Experimental results in Python are stored in the folder “rslt.python”, among which the best parameters are stored in the folder “rslt.python/para.bst/ and experimental results of software projects with various parameter settings and different length of the data streams are stored in the folder (e.g.) “rslt.python/rslt.save/brackets/15d/theta0.99_M20/T5000”. 

As presented in the last paragraph of Section 7 in the left column of page 12 of TSE’22 paper, a grid search based on the first 500 (out of the total 5000) software changes in the data stream of a software project is conducted to choose the parameter settings based on G-mean. The parameters of the investigated JIT-SDP model include the decay factor of 0.9 and 0.99, and the ensemble size of 5, 10 and 20. Given a software project, the parameter combination leading to the best average G-mean across 30 runs at the first 500 time steps is adopted. This is implemented in the method of “main_jit_sdp.sdp_para_tune()”.

Then, the predictive performance of the JIT-SDP model with the best parameter setting is evaluated based on the whole data stream of a software project, which is implemented in “main_jit_sdp. sdp_best_para()”. We stored the results of the Bracket project in “rslt.python/” in order to demonstrate how to analyze the four RQs in Matlab later on. 

The Matlab part is used to conduct the analyses of the four research questions of the TSE’22 paper by making use of the results obtained in Python. The codes are stored in the folder of “matlab/”. To run the Matlab codes, one needs to configurate it by running the script MAKEUP.m or typing in the command window the following line: 

    >> MAKEUP()

This function configures the directories between code scripts and the datasets and among all scripts, so that the scripts can call each other and load the dataset as if they are in a single one-layer directory. The four RQs are implemented in the three scripts starting with “RQ1_...”, “RQ23_...”, and “RQ4_...”, respectively. One can run these three scripts to conduct the analysis of the four RQs. 

The folder “matlab/data_streams” contains the functions and scripts that analyze and create the data streams for training and evaluation. The script “analyse_project_tail.m” simulates the process of finding the 99% quantile of the verification latency , as discussed in Section 6 of the TSE’22 paper. The script “create_data_streams.m” implements the production of the training and evaluation data streams. Moreover, the folder “matlab/for_RQs/” contains the methods required to make the analyses for RQs. 


<p align="right">Enjoy~</p>
<p align="right">Liyan Song, March 2022</p>
<p align="right">Email: songly@sustech.edu.cn</p>
<p align="right">Southern University of Science and Technology, China</p>


