# Written by Patrick B. Williams 2016 for extracing means and standard deviations of physiological
# data in relation to nback task performance. These data are used for visualization and analyses

rm(list = ls())
#~----- load libraries

#~----- load helper functions
# function to return the a vector of the mean and sd for each trial run
metric_descs = function(metric,starts,ends,data) {
        meanvec <- vector() #create an empty list
        sdvec   <- vector() #create an empty list
        for (i in 1:length(starts)) {
                temp <- metric[data$packetnum>starts[i] & data$packetnum<ends[i]]
                meanvec[i] <- mean(temp) 
                sdvec[i]   <- sd(temp)
        }      
        mylist = list(meanvec,sdvec)
}

#~----- load theme for plots
apatheme=theme_bw()+
        theme(panel.grid.major=element_blank(),
              panel.grid.minor=element_blank(),
              panel.border=element_blank(),
              axis.line=element_line(),
              text=element_text(family='Times'),
              legend.title=element_blank())

#~----- load data
data_dir   <- '~/Documents/barraza/data/Nback_joined_20151117'
data_names <- Sys.glob(file.path('~/Documents/barraza/data/Nback_joined_20151117','*.csv'))

unique_files <- list.files(data_dir)
file_name <- substr(unique_files, 1, nchar(unique_files)-11)

#~----- manipulate data
data_out = data.frame() # initialize empty data frame

for (i in 1:length(data_names)) {
        mydata <- read.csv(data_names[i], na.strings = c("", " ","NA","NaN"), stringsAsFactors=F)
        
        # Cleaning data
        # all variables lowercase
        names(mydata) <- tolower(names(mydata))
        
        mydata$istutorialtrial <- as.logical(mydata$istutorialtrial)
        trial_begin <- min(which(mydata$istutorialtrial == F)) # index first non-tutorial trial.
        #~-----
        nback <- mydata[trial_begin:nrow(mydata),] # new data frame includes only non-tutorial trials
        trial_onset <- nback[!(is.na(nback$trial)),]
        
        start_inds <- !is.na(nback$trial)
        start_packet <- nback$packetnum[start_inds]
        end_packet <- start_packet + 70
        
        deoxy <- nback$hbrlfodata
        resp  <- nback$hbrrespdata
        hr    <- nback$hbrcardrms
        
        descs_deoxy <- metric_descs(deoxy,start_packet,end_packet,nback)
        descs_resp  <- metric_descs(resp,start_packet,end_packet,nback)
        descs_hr    <- metric_descs(hr,start_packet,end_packet,nback)
        
        trial_onset$deoxy_trial_means <- descs_deoxy[[1]]
        trial_onset$deoxy_trial_sds   <- descs_deoxy[[2]]
        
        trial_onset$resp_trial_means  <- descs_resp[[1]]
        trial_onset$resp_trial_sds    <- descs_resp[[2]]
        
        trial_onset$hr_trial_means  <- descs_hr[[1]]
        trial_onset$hr_trial_sds    <- descs_hr[[2]]
        
        trial_onset$pid <- i
        
        data_out = rbind(data_out,trial_onset)
        print(paste('done with subj: ', i, ' of ', length(data_names)))
        print(nrow(nback))
}

require(Hmisc)
corr.nback <- rcorr(as.matrix(data.frame(dprime = data_out$dprime, nback = as.factor(data_out$nback), RT = data_out$positionreactiontime,
                                         deoxy_mean = data_out$deoxy_trial_means, deoxy_sd = data_out$deoxy_trial_sds,
                                         resp_mean  = data_out$resp_trial_means,  resp_sd  = data_out$resp_trial_sds,
                                         hr_mean    = data_out$hr_trial_means,    hr_sd    = data_out$hr_trial_sds),
                              type='pearson'))

#~---- old crap
# mod1 <- summary(with(data_out, lm(dprime ~ nback + nback*hbrlfodata)))
# mod2 <- summary(with(data_out, lm(dprime ~ nback + nback*deoxy_trial_means)))
# # 
# mod1 <- summary(with(data_out, lm(dprime ~ nback + nback*hbrrespdata)))
# mod2 <- summary(with(data_out, lm(dprime ~ nback + nback*resp_trial_means)))
# mod2 <- summary(with(data_out, lm(dprime ~ nback + nback*hr_trial_means)))

# mod3 <- summary(with(data_out, lm(dprime ~ resp_trial_sd + nback)))
# mod4 <- summary(with(data_out, lm(dprime ~ nback:positionreactiontime + resp_trial_sd)))

# mod1 <- summary(with(data_out, lm(dprime ~ resp_trial_sds + nback:positionreactiontime)))
# mod2 <- with(data_out, lm(dprime ~ deoxy_trial_means + resp_trial_sds + nback:positionreactiontime))

#----- updated models: broader window of time and addition of pid variable
require(magrittr)
mod1.0 <- with(data_out, lm(dprime ~ deoxy_trial_means + nback:positionreactiontime))
mod1.1 <-  with(data_out, lm(dprime ~ deoxy_trial_means + nback:positionreactiontime + pid))
        
mod2.0 <- with(data_out, lm(dprime ~ resp_trial_sds))
mod2.1 <- with(data_out, lm(dprime ~ deoxy_trial_means + resp_trial_sds + nback:positionreactiontime + pid))

mod1.0_Rsquared <- mod1.0 %>% summary %>% .$r.squared
mod1.1_Rsquared <- mod1.1 %>% summary %>% .$r.squared
mod2.1_Rsquared <- mod2.1 %>% summary %>% .$r.squared

require(scales)
Rsquared_diff_pid <- percent(mod1.1_Rsquared - mod1.0_Rsquared)
Rsquared_diff_resp <- percent(mod2.1_Rsquared - mod1.1_Rsquared)

model_diff_pid <- anova(mod1.0,mod1.1) %>% .$F
model_diff_resp <- anova(mod2.1,mod1.1) %>% .$F

# #
dprime_deoxy <- ggplot(data_out, aes(dprime, deoxy_trial_means)) + geom_point(alpha = .5, mapping=aes(size=resp_trial_sds)) +
        geom_smooth(method=lm) + apatheme  + 
        scale_size_area() + 
        xlab("Nback sensitivity") +
        ylab("Deoxygenated hemoglobin") +
        ggtitle("Figure 1. \n Nback sensitivity and levels of deoxygenated \n hemoglobin in the prefrontal cortex")
