# Load Relevant Libraries----
library(pls)
library(tidyverse)
library(scales)
library(plotly)
library(readr)
library(dplyr)
library(Metrics)
library(moderndive)
library(ggplot2)

# Load Absorbance Data----
  #Load data with wet chem bsi % and absorbance values
  wetChemAbsorbance <- read_csv("csvFiles/wetChemAbsorbance.csv")
  dim(wetChemAbsorbance) # 28 3699
  names(wetChemAbsorbance)

  #Isolate actual BSi percent from wet chem lab data
  actual_bsi_wetchem <- wetChemAbsorbance %>%
    select(dataset, BSiPercent)
  dim(actual_bsi_wetchem) #28  2

# Indices for specific intervals ----

    #368 - 3750cm-1 <- (1946:3699)
    #435 - 480cm-1 <- (3642:3664)
    #790 - 830cm-1 <- (3460:3480)
    #1050 - 1280cm-1 <- (3227:3345)
    #Combined intervals <- (2, 3642:3664, 3460:3480, 3227:3345)

#Create truncated dataframe with three intervals
   # data_trunc <- data %>%
  #  select(2, 3642:3664, 3460:3480, 3227:3345)
  #  dim(data_trunc) #28 164

# PLS Model----
  #Rerun pls model; cv depends on number of samples

    #Full spectrum
      plsModel <- plsr(BSiPercent~., ncomp = 10, data=wetChemAbsorbance, validation = "CV", segments = 5)
    #Interval
  #  pls2 <- plsr(BSiPercent~., ncomp = 10, data=data[c(2,3642:3664)], validation = "CV", segments = 5)
#Create dataframe with actual and predicted BSi percentages----

      #Predicted BSi for 10 components
      predicted_bsi <- as.data.frame(plsModel$fitted.values)
      dim(predicted_bsi) ### 28 10

      #select model with 3 components
      predicted_bsi_3 <- as.data.frame(predicted_bsi[,c(3)])

      #Rename wet_chem_data columns
      names(predicted_bsi_3 )[1] <- "BSiPercent_Predicted"

      #Combine actual and predicted BSi wetchem data
      BSi <- cbind(actual_bsi_wetchem, predicted_bsi_3)
      dim(BSi) #28  3

      #reformat into long so we can graph
      BSi_Long <- BSi %>%
        select(dataset, BSiPercent, BSiPercent_Predicted)%>%
        gather(key = "variable", value = "value", -dataset)

      dim(BSi_Long) #56  3
#Create dataframe with residual error ----

      #Calculating Residuals: Difference between actual and predicted
        BSi$Difference <- (BSi$BSiPercent_Predicted - BSi$BSiPercent)

      #Table of differences for each sample
        Difference <- BSi %>%
        select(dataset, Difference)

     #Function to round digits #edit function so it can skip non-numeric factor cols
        round_df <- function(x, digits) {
        # round all numeric variables
        # x: data frame
        # digits: number of digits to round
        numeric_columns <- sapply(x, mode) == 'numeric'
        x[numeric_columns] <-  round(x[numeric_columns], digits)
        x
      }

      Difference <- round_df(Difference, 2)

#Calculate absolute values, mean and median of residual errors ----

      Abs <- (abs(Difference$Difference))

      mean(Abs)
      median(Abs)
#GRAPHS----

        ##Model Accuracy
        ggplot(BSi_Long, aes(x = dataset, y = value, fill=variable))+
        geom_col(position= position_dodge()) +
        scale_fill_manual(values=c("#999999", "#E69F00"),
                          name="Values",
                          breaks=c("BSiPercent", "BSiPercent_Predicted"),
                          labels=c("Actual", "Predicted")) +
        labs(
          y = "BSi Percentage",
          x = "Sample ID",
          title= expression("Model Accuracy: Full Spectrum" ~ cm^{-1}), ###Rename title according to chosen interval
          subtitle= "For 28 Samples", ###Modify depending on number of samples in dataset
          colour = "variabl") +
        theme(legend.position = c(0.125, 0.8),
              axis.text.x  = element_text(angle = 90))

      ##Visually Represent difference
      Difference %>%
        mutate(highlight_flag = ifelse(Difference >= '0', T, F)) %>%
        ggplot (aes(x = dataset, y = Difference)) +
        geom_col(aes(fill = highlight_flag)) +
        scale_fill_manual(values = c('red', 'green'), name = "Overfitting") +
        geom_text( data = Difference, aes(label = Difference), fontface ="bold", size = 2.5, vjust = 0) +
        labs(
          y = "Difference in Percentage",
          x = "Sample ID",
          title=expression("Residuals: Full Spectrum" ~ cm^{-1}),
          subtitle= "For 28 Samples",
          colour = "variabl") +
        theme(legend.position = c(0.1, 0.85),
              axis.text.x  = element_text(angle = 90))



