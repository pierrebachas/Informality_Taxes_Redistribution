##################################
# INSTALL PACKAGES 
##################################


library(tidyr)
library(dplyr)
library(readr)   # to read csv
library("readxl")
library(metafor)
library(forestplot)

##########
## DATA ##
##########
#Dataset for graph 1
income <- read_delim(file.path(main,"gini_middle_low_inc_central.csv"),delim = ",", col_names = TRUE) %>% as.data.frame()

#Dataset for graph 2
rates <- read_delim(file.path(main,"gini_central.csv"),delim = ",", col_names = TRUE) %>% as.data.frame()
income_nosample <- subset(income, select = -c(sample,source) )
drop <- c("source","other_sample")
rates_nosample <- rates[,!(names(rates) %in% drop)]

income_final <- rbind(income_nosample,rates_nosample)
income_final <- income_final[-c(4:5,9:10,11:13,16), ]
income_final$id <- seq_len(nrow(income_final))
income_final$id[grepl("black", income_final$color) & income_final$order == 7] <- 9
income_final$scenario[grepl("Food subsidy, only formal taxed", income_final$scenario)] <- "Food rate differentiation, only formal taxed"
income_final$scenario[grepl("Food subsidy, formal and informal taxed", income_final$scenario)] <- "Food rate differentiation, formal and informal taxed"

                
#Dataset for graph 3
income_lower <- income[-c(6:10), ]
#Dataset for graph 4
income_middle <- income[-c(1:5), ]



############
## GRAPH 2 # Lower/middle/CEQ FIG A16 Paper
############



jpg <- 1
pdf <- 0
c.lo <- -6
c.hi <- 0.55

if (pdf==1) { 
  pdf(file=file.path(main,"gini_income.pdf"),
      width = 22, height = 9
  ) 
}

if (jpg==1) { 
  jpeg(file=file.path(main,"gini_income.jpg"),
       width = 1600, height = 823
  ) 
}

# Sort it
income_final <- arrange(income_final, -id)

par(mar=c(5,4,0,2))

forest(income_final$mean, # observed effect sizes
       ci.lb = income_final$ci_low, # lower bound confidence interval
       ci.ub = income_final$ci_high, # upper bound confidence interval
       annotate = FALSE, # try changing to false
       clim = c(-0.02,0), efac = c(0,1),
       ylim = c(1,6.5),
       xlim = c(c.lo, c.hi + 0.005),
       at = c(-4,-3,-2,-1,0,0.5),
       alim = c(c.lo,c.hi), # Doesnt seem to do much 
       xlab = "Percent change in Gini from policy",
       slab = NA,
       top= 1.3,
       ilab=cbind(income_final$scenario),
       ilab.xpos = c(c.lo),
       ilab.pos = c(4), 
       pch = 19, psize = 2, pcol = 2 , col =cbind(income_final$color) , # This controls the look of the dots and the size
       cex = 1.5,             # font size
       digits = 1,            # digits on the axis
       lwd = 1,               # Linewidht I imagine 
       ref = 0 ,              # reference line based at 0
       lty = c("blank","solid","blank"),
       rows=c(1.2,1.5,2.9,3.2,3.5,4.9,5.2,5.5))


# Add column headers to figure
par(font=2)  # font = 2 is italic
vertspace <- 6.4
text(c.lo, vertspace, "Tax Policy", pos=4, cex = 1.5)
text(-2, vertspace, "Effect Size", cex = 1.5)

# Panel titles 
par(font=2) # Bold
text(c.lo, 5.8 , "Panel A: Lower Income Countries (Source: This paper N=16)", pos=4, cex = 1.5)
text(c.lo, 3.8 , "Panel B: Middle Income Countries (Source: This paper N=15)", pos=4, cex = 1.5)
text(c.lo, 1.8 , "Panel C: Middle Income Countries (Source: CEQ N=25)", pos=4, cex = 1.5)

# Runs the whole file to generate the figure 
dev.off()
