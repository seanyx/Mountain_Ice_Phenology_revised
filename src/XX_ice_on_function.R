library(tidyverse)
library(ggpubr)
library(lubridate)
library(plotly)
library(Metrics)

#below function is a combination of sources from here: https://statisticsglobe.com/avoid-for-loop-in-r
#and here: https://stackoverflow.com/questions/31862933/storing-loop-output-in-a-dataframe-in-r (the last response on that discussion board)

test_output_ice_on <- data.frame()


test_output_ice_on <- do.call(
  rbind.data.frame,
  lapply(
    2:100,
    function(i){
      remote_iceOn <- all_remote_w_median %>%
        #filter(median_val == "full_merge") %>%
        #remove median_val as grouping variable when above filter is in use
        group_by(lakename, water_year, median_val) %>% #, medial_val
        filter(date > '2000-10-01') %>% #start at 2001 water year (otherwise will have a misleading ice on in March of 2000)
        #mutate(median_iceFrac = rollapply(median_iceFrac, width = i, min, align = "left", fill = NA, na.rm = TRUE)) %>% #21
        mutate(median_iceFrac = rollapply(median_iceFrac, width = i, median, align = "left", fill = NA, na.rm = TRUE)) %>%
        filter(median_iceFrac >= 0.8) %>%
        filter(row_number() == 1) %>%
        rename(date_ice_on = date) %>% #remove when not going through all columns
        ungroup() #%>%
      
      remote_insitu_merge_iceOn_dates <- remote_iceOn %>%
        select(-year) %>%
        rename(ice_on_water_year = water_year) %>%
        select(-median_iceFrac) %>% #comment out when using one median_val
        pivot_wider(names_from = median_val, values_from = date_ice_on) %>% #comment out when using one median_val
        inner_join(all_insitu_w_water_year, by = c("lakename", "ice_on_water_year")) %>% #inner_join() works better than right_join(), as it does not include erroneous NA values, such as the Castle ice on dates, since we do not have Castle ice on dates.
        #right_join(all_insitu_w_water_year, by = c("lakename")) %>%
        select(-ice_off_insitu, -ice_off_insitu_yday, -ice_off_water_year) %>%
        arrange(lakename, ice_on_water_year) #%>%
      
      ice_on_med_test <- remote_insitu_merge_iceOn_dates %>%
        na.omit() %>%
        #group_by(lakename) %>% # f you do not group by lake name, it will get the total MAE
        #filter(lakename != "morskie_oko") %>%
        summarise(across(
          .cols = 3:20, #without full_merge_fill
          #.cols = 2:5, #with full_merge_fill
          #.fns = ~ mean(na.rm = TRUE, interval(.x, ice_on_insitu) %/% days(1)) #NOTE: 02.18.2022 This is not MAE its the absolute value of the mean difference (which is absolute value of the mean bias error MBE - see Smejkalova et al., 2016)
          #.fns = ~ Metrics::mdae(predicted = as.numeric(.x), actual = as.numeric(ice_on_insitu))
          .fns = ~ Metrics::mae(predicted = as.numeric(.x), actual = as.numeric(ice_on_insitu))
          #.fns = ~ Metrics::rmse(predicted = as.numeric(.x), actual = as.numeric(ice_on_insitu))
        ));
      
      return(ice_on_med_test)
    }
  )
);

test <- test_output_ice_on %>%
  mutate(
    width = c(2:100)
  ) %>%
  select(19, 18, 1:17)

write_csv(test, here('data/ice_on__median_width_2_100_threshold_0.8.csv'))


test2 <- test %>%
  select(-1,-2)
  
min(test2)

ggplot(data = test, aes(x = width, y = full_merge))+
  geom_line(size = 2)+
  theme_classic()







remote_iceOn <- all_remote_w_median %>%
  #filter(median_val == "full_merge") %>%
  #remove median_val as grouping variable when above filter is in use
  group_by(lakename, water_year, median_val) %>% #, medial_val
  filter(date > '2000-10-01') %>% #start at 2001 water year (otherwise will have a misleading ice on in March of 2000)
  #mutate(median_iceFrac = rollapply(median_iceFrac, width = 19, quantile, align = "left", fill = NA, na.rm = TRUE)) %>% #21
  mutate(quantile_iceFrac = rollapply(median_iceFrac, width = 90, median, align = 'left', fill = NA, na.rm = TRUE)) %>%
  filter(median_iceFrac >= 0.8) %>%
  filter(row_number() == 1) %>%
  rename(date_ice_on = date) %>% #remove when not going through all columns
  ungroup() #%>%

remote_insitu_merge_iceOn_dates <- remote_iceOn %>%
  select(-year) %>%
  rename(ice_on_water_year = water_year) %>%
  select(-median_iceFrac) %>% #comment out when using one median_val
  pivot_wider(names_from = median_val, values_from = date_ice_on) %>% #comment out when using one median_val
  inner_join(all_insitu_w_water_year, by = c("lakename", "ice_on_water_year")) %>% #inner_join() works better than right_join(), as it does not include erroneous NA values, such as the Castle ice on dates, since we do not have Castle ice on dates.
  #right_join(all_insitu_w_water_year, by = c("lakename")) %>%
  select(-ice_off_insitu, -ice_off_insitu_yday, -ice_off_water_year) %>%
  arrange(lakename, ice_on_water_year) #%>%

ice_on_med_test <- remote_insitu_merge_iceOn_dates %>%
  na.omit() %>%
  #group_by(lakename) %>% # f you do not group by lake name, it will get the total MAE
  #filter(lakename != "morskie_oko") %>%
  summarise(across(
    .cols = 3:20, #without full_merge_fill
    #.cols = 2:5, #with full_merge_fill
    .fns = ~ mean(na.rm = TRUE, interval(.x, ice_on_insitu) %/% days(1)) #NOTE: 02.18.2022 This is not MAE its the absolute value of the mean difference (which is absolute value of the mean bias error MBE - see Smejkalova et al., 2016)
    #.fns = ~ Metrics::mdae(predicted = as.numeric(.x), actual = as.numeric(ice_on_insitu))
    #.fns = ~ Metrics::mae(predicted = as.numeric(.x), actual = as.numeric(ice_on_insitu))
    #.fns = ~ Metrics::rmse(predicted = as.numeric(.x), actual = as.numeric(ice_on_insitu))
  ))
ice_on_med_test




x <- all_remote_w_median %>%
  filter(lakename == 'silver' & water_year == 2001 & median_val == 'frac_03day_med') %>%
  mutate(
    quant_frac = rollapply(median_iceFrac, width = 19, quantile(median_iceFrac, probs = 0.75), align = "left", fill = NA, na.rm = TRUE)
  )

quantile(x$median_iceFrac)


y <- data.frame()

y <- do.call(
  rbind.data.frame,
  lapply(1:5,
         function(i){
           z <- i*2;
           return(z)
         })
)








#could do this for cloud cover. show a boxplot of cloudy days per lake. 
#then show a boxplot of cloudy days per month per lake
#this may also be well represented by a histogram of percent cloudy days per lake per month
#I think this would look like a bimodal distribution, where we have high cloudy days in Jan - Mar
#Low cloudy days in Apr - Sep, and then high cloudy days again in Oct - Dec
ggplot(all_remote_w_median, aes(x = median_val, y = median_iceFrac, fill = median_val))+
  geom_boxplot()








