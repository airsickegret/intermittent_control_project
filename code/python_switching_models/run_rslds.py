# -*- coding: utf-8 -*-
"""
Created on Mon August 8th 2021.

@author: calebsponheim
"""

import os
import csv
from import_matlab_data import import_matlab_data
from assign_trials_to_HMM_group import assign_trials_to_HMM_group
import pandas as pd

from train_rslds import train_rslds
# from analyze_params import analyze_params
from train_HMM import train_HMM
# from LL_curve_fitting import LL_curve_fitting
import numpy as np
from numpy.linalg import eig
from rslds_cosmoothing import rslds_cosmoothing
import pickle
# from plot_continuous_states import plot_continuous_states
# from state_prob_over_time import state_prob_over_time
# import autograd.numpy.random as npr


def run_rslds(
    subject,
    task,
    train_portion,
    model_select_portion,
    test_portion,
    hidden_max_state_range,
    hidden_state_skip,
    number_of_discrete_states,
    rslds_ll_analysis,
    number_of_latent_dimensions,
    midway_run,
    fold_number,
    num_neuron_folds,
    train_model
):
    """
    Summary: Function is the main script for running rslds analysis.

    Returns.
    -------
    None. Writes out data to files.

    """
    # %%
    current_working_directory = os.getcwd()
    if "calebsponheim" in current_working_directory:
        folderpath_base_base = "C:/Users/calebsponheim/Documents/git/intermittent_control_project/"
    elif "dali" in current_working_directory:
        folderpath_base_base = "/dali/nicho/caleb/git/intermittent_control_project/"
    elif "project/nicho/projects/caleb" in current_working_directory:
        folderpath_base_base = "/project/nicho/projects/caleb/git/intermittent_control_project/"
    elif "Caleb (Work)" in current_working_directory:
        folderpath_base_base = "C:/Users/Caleb (Work)/Documents/git/intermittent_control_project/"
    folderpath_base = folderpath_base_base + "data/python_switching_models/"
    figurepath_base = folderpath_base_base + "figures/"

    if subject == "bx":
        if task == "CO":
            folderpath = folderpath_base + "Bxcenter_out1902280.05sBins/"
            # folderpath = (
            #     folderpath_base + "Bxcenter_out1902280.05_sBins_move_window_only/"
            # )
            figurepath = figurepath_base + "Bx/CO_CT0/rslds/"
        elif task == "CO+RTP":
            folderpath = folderpath_base + "Bxcenter_out_and_RTP1902280.05sBins/"
            figurepath = figurepath_base + "Bx/CO+RTP_CT0/rslds/"
        elif task == "RTP":
            folderpath = folderpath_base + "BxRTP0.05sBins/"
            figurepath = figurepath_base + "Bx/RTP/rslds/"
    elif subject == "bx18":
        folderpath = folderpath_base + "Bx18CO0.05sBins/"
        figurepath = figurepath_base + "Bx/CO18_CT0/rslds/"
    elif subject == "rs":
        if task == "CO":
            # folderpath = folderpath_base + "RSCO0.05sBins/"
            folderpath = folderpath_base + "RSCO_move_window0.05sBins/"
            figurepath = figurepath_base + "RS/CO_CT0_move_only/rslds/"

        elif task == "RTP":
            folderpath = folderpath_base + "RSRTP0.05sBins/"
            figurepath = figurepath_base + "RS/RTP_CT0/rslds/"
    elif subject == "rj":
        folderpath = folderpath_base + "RJRTP0.05sBins_1031126/"
        figurepath = figurepath_base + "RJ/RTP_CT0/rslds/"
    else:
        print("BAD, NO")

    temp_folderlist = os.listdir(folderpath)
    temp_figurelist = os.listdir(figurepath)
    if str(number_of_discrete_states) + "_states_" + str(number_of_latent_dimensions) + "_dims" not in temp_folderlist:
        os.mkdir(folderpath + str(number_of_discrete_states) +
                 "_states_" + str(number_of_latent_dimensions) + "_dims/")
    if str(number_of_discrete_states) + "_states_" + str(number_of_latent_dimensions) + "_dims" not in temp_figurelist:
        os.mkdir(figurepath + str(number_of_discrete_states) +
                 "_states_" + str(number_of_latent_dimensions) + "_dims/")

    folderpath_out = folderpath + str(number_of_discrete_states) + \
        "_states_" + str(number_of_latent_dimensions) + "_dims/"
    figurepath = figurepath + str(number_of_discrete_states) + \
        "_states_" + str(number_of_latent_dimensions) + "_dims/"

    class meta:
        def __init__(self, train_portion, model_select_portion, test_portion):
            self.train_portion = train_portion
            self.model_select_portion = model_select_portion
            self.test_portion = test_portion

    bin_size = 50  # in milliseconds
    meta = meta(train_portion, model_select_portion, test_portion)

    data = import_matlab_data(folderpath)

    # %%

    trial_classification, neuron_classification = assign_trials_to_HMM_group(
        data, meta, midway_run, fold_number, folderpath_out, num_neuron_folds)

    # %% Running HMM
    if midway_run == 0:
        hmm_storage, select_ll, state_range = train_HMM(
            data,
            trial_classification,
            meta,
            bin_size,
            hidden_max_state_range,
            hidden_state_skip,
            number_of_discrete_states
        )

    # %% Running Co-Smoothing
    # 1. Set up file directory and folder structure for given log_likelihood files
        #  1a. bring in datapath
        #  1b. see if co-smoothing data folder already exists
        # 1bi. if doesn't exist, make it
        # 1c. see if fold number exists
    # 2. calculate log-likelihood based on held-out test data

    if midway_run == 1:
        log_likelihood_emissions_sum = rslds_cosmoothing(data, trial_classification, meta, bin_size,
                                                         number_of_discrete_states, figurepath,
                                                         rslds_ll_analysis, number_of_latent_dimensions,
                                                         neuron_classification, folderpath_out,
                                                         fold_number, train_model)
        # test_bits_sum = pd.DataFrame(test_bits_sum)
        # latent_dims = pd.DataFrame([number_of_latent_dimensions])
        # frames = [test_bits_sum, latent_dims]
        # test_bits_sum = pd.concat(frames, axis=1)
        # first_file = 1
        # for file in os.listdir(folderpath_out):
        #     if file.endswith(str(number_of_discrete_states) + "_states_test_bits.csv"):
        #         first_file = 0

        # if first_file == 1:
        #     test_bits_sum.to_csv(folderpath_out + str(number_of_discrete_states) +
        #                          "_states_test_bits.csv", index=False, header=False)
        # elif first_file == 0:
        #     test_bits_sum.to_csv(folderpath_out + str(number_of_discrete_states) +
        #                          "_states_test_bits.csv", mode='a', index=False, header=False)

        #############
        # Emissions
        #############
        # log_likelihood_emissions_sum = sum(log_likelihood_emissions_sum)
        if train_model == 0:
            log_likelihood_emissions_sum = pd.DataFrame([log_likelihood_emissions_sum])
            latent_dims = pd.DataFrame([number_of_latent_dimensions])
            frames = [log_likelihood_emissions_sum, latent_dims]
            log_likelihood_emissions_sum = pd.concat(frames, axis=1)

            log_likelihood_emissions_sum.to_csv(folderpath_out + str(number_of_discrete_states) +
                                                "_states_test_emissions_ll_fold_" + str(fold_number) + ".csv", index=False, header=False)

    # %% Running RSLDS
    if midway_run == 0:
        model, xhat_lem, fullset, model_params = train_rslds(
            data, trial_classification, meta, bin_size,
            number_of_discrete_states, figurepath, rslds_ll_analysis,
            number_of_latent_dimensions
        )

        # %%

        filename = folderpath_out + 'fold_' + str(fold_number) + '_model'
        outfile = open(filename, 'wb')
        pickle.dump(model, outfile)
        outfile.close()

        # %%

        decoded_data_rslds = []
        discrete_states_full = []
        latent_states_full = []
        for iTrial in range(len(fullset)):
            decoded_data_rslds.append(model.most_likely_states(xhat_lem[iTrial], fullset[iTrial]))
            discrete_states_full.extend(
                model.most_likely_states(xhat_lem[iTrial], fullset[iTrial]))
            latent_states_full.extend(xhat_lem[iTrial])

        # rslds_likelihood = model.emissions.log_likelihoods(
        #     data=y, input=np.zeros([y[0].shape[0], 0]), mask=None, tag=[], x=xhat_lem)

        real_eigenvalues = []
        imaginary_eigenvalues = []
        real_eigenvectors = []
        imaginary_eigenvectors = []
        dynamics = []
        for iLatentDim in np.arange(model.dynamics.As.shape[0]):
            eigenvalues_temp, eigenvectors_temp = eig(model.dynamics.As[iLatentDim, :, :])
            dynamics.append(model.dynamics.As[iLatentDim, :, :])
            real_eigenvalues.append(np.around(eigenvalues_temp.real, 3))
            imaginary_eigenvalues.append(np.around(eigenvalues_temp.imag, 3))
            real_eigenvectors.append(np.around(eigenvectors_temp.real, 3))
            imaginary_eigenvectors.append(np.around(eigenvectors_temp.imag, 3))
        # %% HMM state decoding

        decoded_data_hmm = []
        for iTrial in range(len(fullset)):
            decoded_data_hmm.append(hmm_storage[0].most_likely_states(fullset[iTrial]))

        # %%

        # plot_continuous_states(xhat_lem, number_of_latent_dimensions, decoded_data_rslds)
        # %% Plot State Probabilities

        # state_prob_over_time(model, xhat_lem, y, number_of_discrete_states, figurepath)

        # %% write data for matlab

        decoded_data_hmm_out = pd.DataFrame(decoded_data_hmm)
        decoded_data_hmm_out.to_csv(folderpath_out + "decoded_data_hmm.csv", index=False)

        decoded_data_rslds_out = pd.DataFrame(decoded_data_rslds)
        decoded_data_rslds_out.to_csv(
            folderpath_out + "decoded_data_rslds.csv", index=False)

        discrete_states_full_out = pd.DataFrame(discrete_states_full)
        discrete_states_full_out.to_csv(
            folderpath_out + "discrete_states_full.csv", index=False, header=False)

        latent_states_full_out = pd.DataFrame(latent_states_full)
        latent_states_full_out.to_csv(
            folderpath_out + "latent_states_full.csv", index=False, header=False)

        with open(folderpath_out + "trial_classifiction.csv", "w", newline="") as f:
            write = csv.writer(f, delimiter=" ", quotechar="|",
                               quoting=csv.QUOTE_MINIMAL)
            for iTrial in range(len(trial_classification)):
                write.writerow(trial_classification[iTrial])

        for iTrial in range(len(xhat_lem)):
            continuous_states_temp = pd.DataFrame(xhat_lem[iTrial])
            continuous_states_temp.to_csv(folderpath_out + "continuous_states_trial_" +
                                          str(iTrial+1) + ".csv", index=False, header=False)

        real_eigenvalues_out = pd.DataFrame(real_eigenvalues)
        real_eigenvalues_out.to_csv(folderpath_out + "real_eigenvalues.csv", index=False)
        imaginary_eigenvalues_out = pd.DataFrame(imaginary_eigenvalues)
        imaginary_eigenvalues_out.to_csv(folderpath_out + "imaginary_eigenvalues.csv", index=False)

        biases_out = pd.DataFrame(model.dynamics.bs)
        biases_out.to_csv(folderpath_out + "biases.csv", index=False)

        for iState in range(len(real_eigenvectors)):
            real_eigenvectors_out = pd.DataFrame(real_eigenvectors[iState])
            real_eigenvectors_out.to_csv(folderpath_out + "real_eigenvectors_state_" +
                                         str(iState+1) + ".csv", index=False)
            imaginary_eigenvectors_out = pd.DataFrame(imaginary_eigenvectors[iState])
            imaginary_eigenvectors_out.to_csv(folderpath_out + "imaginary_eigenvectors_state_" +
                                              str(iState+1) + ".csv", index=False)

            dynamics_out = pd.DataFrame(dynamics[iState])
            dynamics_out.to_csv(folderpath_out + "dynamics_state_" +
                                str(iState+1) + ".csv", index=False)

        # %%
    if midway_run == 0:
        return model, xhat_lem, fullset, model_params, real_eigenvectors_out, imaginary_eigenvectors_out, real_eigenvalues_out, imaginary_eigenvalues_out
