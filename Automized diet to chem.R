##Title: Automized Conversion Algorithm FFQ/day to CHEM/day
##Author: Emily Oosterhout
## setwd('C:/DATA FOOD COMPONENT ANALYSIS/RP2_ChemIBDFood')
##

##========================= LOAD DATA AND IMPORT LIBRARIES =============================##

#Import libraries
library(readxl)
library(dplyr)
library(tidyverse)
library(data.table)
library(reshape2)
library(ggplot2)
library(ggbreak) 
library(patchwork)
library(rlang)
library(writexl)

# Load data
chem_diet <- read_xlsx('chem_diet_combined_V2.xlsx')
chem <- read_xlsx('transposed_ffqchem_V2.xlsx')
diet_raw <- read_xlsx('diet_raw_v2.xlsx')

##======================================= CONVERSION FFQ_GROUP/DAY TO CHEM/DAY =======================================##
chemdata <- as.character(colnames(chem_diet[,2:1109]))
participant_id <- as.character(colnames(chem_diet[,1110:3094]))

# Set all items of chemdata to numeric
chem[, 2:1109] <- sapply(chem[, 2:1109], as.numeric)

#Create df with only the FFQ data from participants
diet <- chem_diet[, (colnames(chem_diet) %in% participant_id)]

# For loop adding corresponding FFQ data per participant after chemdata
# Saving each df in a list
chem_diet_p <- list()
for (i in participant_id){
  output <- cbind(chem[,2:1109], diet[,i])
  chem_diet_p[[i]] <- output
}

# Function to multiply each chem item with corresponding FFQ data per participant
multiply_columns_list <- function(df_list, participant_id) {
  # loop through each dataframe in the list
  for (i in seq_along(df_list)) {
    df <- df_list[[i]]
    col_to_multiply <- participant_id[[i]]
    # loop through each column and multiply it with the specified column
    for (col in colnames(df)) {
      if (col != col_to_multiply) {
        df[[col]] <- df[[col]] * df[[col_to_multiply]]
      }
    }
    # update the dataframe in the list
    df_list[[i]] <- df
  }
  
  # return the updated list of dataframes
  return(df_list)
}

# call the function to multiply each dataframe's columns with the specified column in list
df_list <- multiply_columns_list(chem_diet_p, participant_id)
df_list_2 <- multiply_columns_list(chem_diet_p, participant_id)

# Add ffq groups to each list item
chem_diet_m <- list()
for (t in participant_id){
  output <- cbind(chem_diet$ffq_group, df_list[[t]])
  colnames(output)[1] <- 'ffq_group'
  chem_diet_m[[t]] <- output
}

##============================= SUM OF DIETARY COMPOUND CONSUMED PER PARTICIPANT ==============##

# ColSums of each dietary component consumed per participant
chem_diet_s <- list()
for (t in participant_id){
  out <- as.data.frame(colSums(df_list_2[[t]], na.rm = TRUE))
  colnames(out) <- t
  chem_diet_s[[t]] <- out
}

# New df with sum of dietary component consumed per participant
sum_chem_diet <- bind_cols(chem_diet_s) # put all items of the list into one df
sum_chem_diet_t <- as.data.frame(t(sum_chem_diet)) #transform df to get compounds as colnames
sum_chem_diet_c <- setDT(sum_chem_diet_t, keep.rownames = 'UMCGIBDResearchIDorLLDeepID')[] #put rownames in first column

# Filter participants containing dietary data from diet_raw (1985/2116)
diet_clean <- diet_raw[1:1985, 1:6]

# Bind dietary info to total component data
chem_diet_merge <- merge(diet_clean, sum_chem_diet_c, on = 'UMCGIBDResearchIDorLLDeepID')
