# coding: utf-8

##Import Library
import pandas as pd
import numpy as np
from glob import glob
import os

##Functions

def data_BL_corrected(df, BL):
    """ Baseline corrects participant data
        Inputs: video dataframe, Baseline dataframe
        1. Creates a new dataframe with the same column names as df
        2. Itterating over each column label (participant) and the "data" (series of ppt data) in the dataframe, df
        3. Column of BL means = BL[key].mean()
        4. In the new dataframe created in (1), given the key, create the series: ("data"-BL_mean)/BL_mean  
        5. Return new dataframe
        Notes: key = column label; data = series (column of data)"""
    
    return_df = pd.DataFrame(columns=df.columns)           # Creating the new dataframe; "columns = column labels"

    for key,data in df.iteritems():                        # Itterating over each column in the DF i,e NN001, NN002
        BL_mean = BL[key].mean()                           # Getting the mean for that column, i.e mean(NN001)
        return_df[key] = (data-BL_mean)/BL_mean            # Creates a new series where each value is (x-mean)/mean
    
    return return_df

def ppts_averages_i(df):
    """ Averages the row of data for all ppts except i
        Input: Baseline corrected ppt data (from data_BL_corrected())
        1. Creates a new dataframe
        2. Itterating over each row number(i) in each row, iterating over each column(j)
        3. In loc[i,j] - from the row, return the row with the datapoint removed, then take the mean of that row
        4. Return new dataframe
    """
    
    return_df = pd.DataFrame()
    
    for i, row in df.iterrows():                          # Each row
        for j, value in row.iteritems():                  # Each value/item in each row
            return_df.loc[i,j] = row[row != value].mean() # In loc[i,j] - from the row, return the row with the datapoint removed, then take the mean of that row           
    
    return return_df


##Cleaning

# list files in isc directory
mypath = '/Users/drwilliams/Documents/barraza/CRA/data/for_ICA/merged/2members'
filename = '/Users/drwilliams/Documents/barraza/CRA/data/Team_ICA_avg3.csv'
os.chdir(mypath)

excel_files = glob('*.xlsx')
  
sheet_names = ['team_nirs','team_resp','team_card']     
df = pd.DataFrame()
 
# ##Reading in Excel Files
for i in range(1,len(excel_files)):
    #Importing all excel files
    this_data_file = excel_files[i]
    excel_file = pd.read_excel(this_data_file, sheetname=sheet_names)

    #nirs data
    print('reading nirs data')
    nirs_data = excel_file['team_nirs']
    print('reading resp data')
    resp_data = excel_file['team_resp']
    print('reading card data')
    card_data = excel_file['team_card']
    #Baseline
    nirs_BL = nirs_data[1:(30*60*5)] # Hz*secs*mins
    resp_BL = resp_data[1:(30*60*5)] # Hz*secs*mins
    card_BL = card_data[1:(30*60*5)] # Hz*secs*mins

    ##Baseline Correcting

    print('baseline correcting nirs')
    nirs_data_corrected = data_BL_corrected(nirs_data, nirs_BL)
    print('baseline correcting resp')
    resp_data_corrected = data_BL_corrected(resp_data, resp_BL)
    print('baseline correcting cardiac')    
    card_data_corrected = data_BL_corrected(card_data, card_BL)

    # ##ISC

    print('running ppt averages: nirs')
    nirs_data_avg = ppts_averages_i(nirs_data_corrected)
    print('running ppt averages: resp')
    resp_data_avg = ppts_averages_i(resp_data_corrected) 
    print('running ppt averages: card')
    card_data_avg = ppts_averages_i(card_data_corrected)  

    # rolling correlation
    hz = 30
    secs = 60
    mins = 5
    print 'rolling correlation: nirs'
    ISC_nirs = pd.rolling_corr(nirs_data, nirs_data_avg, window = (hz*secs*mins))  
    print 'rolling correlation: resp'
    ISC_resp = pd.rolling_corr(resp_data, resp_data_avg, window = (hz*secs*mins))  
    print 'rolling correlation: card'
    ISC_card = pd.rolling_corr(card_data, card_data_avg, window = (hz*secs*mins))                         

    # calculate mean ICS value per ppt and metric
    this_index = this_data_file[len(this_data_file)-20:len(this_data_file)-5]
        
    if 'avo_nirs' in ISC_nirs:
        avo_nirs = np.mean(ISC_nirs['avo_nirs'])
    else:
        avo_nirs = np.nan

    if 'avo_resp' in ISC_resp:
        avo_resp = np.mean(ISC_resp['avo_resp'])
    else:
        avo_resp = np.nan

    if 'avo_card' in ISC_card:    
        avo_card = np.mean(ISC_card['avo_card'])
    else:
        avo_card = np.nan
        
    dempc_nirs = np.mean(ISC_nirs['dempc_nirs'])
    dempc_resp = np.mean(ISC_resp['dempc_resp'])
    dempc_card = np.mean(ISC_card['dempc_card'])
    
    plo_nirs = np.mean(ISC_nirs['plo_nirs'])
    plo_resp = np.mean(ISC_resp['plo_resp'])
    plo_card = np.mean(ISC_card['plo_card'])
        
    to_append = [avo_nirs, avo_resp, avo_card, dempc_nirs, dempc_resp, dempc_card, plo_nirs, plo_resp, plo_card]   
    df[this_index] = to_append
    
    print(df)
    
df.to_csv(filename)



