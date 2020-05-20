##################################
# INSTALL PACKAGES 
##################################
# install.packages("glue")
# install.packages("tidyr")
# install.packages("dplyr")
# install.packages("readr")   # to read csv
# install.packages("readxl")
# install.packages("metafor")
# install.packages("forestplot")

library(tidyr)
library(dplyr)
library(readr)   # to read csv
library("readxl")
library(metafor)
library(forestplot)

#################
## DIRECTORIES ##
#################
 main <- "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata/tables"
# main <- "/Users/pierrebachas/Dropbox/Regressivity_VAT/Stata/tables"


##########
## DATA ##
##########
rates <- read_delim(file.path(main,"gini_central.csv"),delim = ",", col_names = TRUE) %>% as.data.frame()
# income <- read_delim(file.path(main,"gini_middle_low_inc_central.csv"),delim = ",", col_names = TRUE, skip_empty_rows = TRUE) %>% as.data.frame()
rates <- rates[-c(6), ]
rates$scenario[grepl("Food subsidy, only formal taxed", rates$scenario)] <- "Food rate differentiation, only formal taxed"
rates$scenario[grepl("Food subsidy, formal and informal taxed", rates$scenario)] <- "Food rate differentiation, formal and informal taxed"


############
## GRAPH 1 #
############
# Vertical space play with ylim

jpg <- 1
pdf <- 0
c.lo <- -8
c.hi <- 0.55

if (pdf==1) { 
  pdf(file=file.path(main,"gini.pdf"),
      width = 22, height = 9
  ) 
}

if (jpg==1) { 
  jpeg(file=file.path(main,"gini.jpg"),
       width = 1600, height = 823
  ) 
}

# Sort it
rates <- arrange(rates, -order)

# Forest plot
par(font=1)
other_sample_start_row  <- 1
other_sample_end_row    <- sum(rates$other_sample)
our_sample_start_row <- other_sample_end_row + 2
our_sample_end_row   <- our_sample_start_row + sum((rates$other_sample==0)) - 1

par( mar=c(5.5,4,0,2))

forest(rates$mean, # observed effect sizes
      ci.lb = rates$ci_low, # lower bound confidence interval
      ci.ub = rates$ci_high, # upper bound confidence interval
       annotate = FALSE, # try changing to false
       clim = c(-0.02,0), efac = c(0,1),
       ylim = c(1.1,2.90),
       xlim = c(c.lo, c.hi + 0.005),
       at = c(-4,-3,-2,-1,0,0.5),
       alim = c(c.lo,c.hi), # Doesnt seem to do much 
       xlab = "",
       slab = NA,
       top= 1.2,
       ilab=cbind(rates$scenario),
       ilab.xpos = c(c.lo),
       ilab.pos = c(4), 
       pch = 19, psize = 2, pcol = 2 , col =cbind(rates$color) , # This controls the look of the dots and the size
       cex = 2,             # font size
       cex.lab = 2.2,            # font size xtitle
       cex.axis = 2,           # font size xlab
       digits = 1,            # digits on the axis
       lwd = 1,               # Linewidht I imagine 
       ref = 0 ,              # reference line based at 0
       lty = c("blank","solid","blank"),
       rows=c(1.35,1.5,2.1,2.25,2.4))
    # separate into two panels by length of study 
       # (http://www.metafor-project.org/doku.php/plots:forest_plot_with_subgroups)
       #rows = c(other_sample_start_row:other_sample_end_row,our_sample_start_row:our_sample_end_row))

# Add column headers to figure
par(font=2)  # font = 2 is bold
vertspace <- 2.8
text(c.lo, vertspace, "Tax Policy", pos=4, cex = 2.3)
text(c.lo, 2.55 , "Panel A: Simulated Optimal Consumption Taxes (This paper N=31)", pos=4, cex = 2)
text(c.lo, 1.65 , "Panel B: Studies Using Current Tax Policies (CEQ N=25)", pos=4, cex = 2)
text(-2, vertspace, "Effect Size", cex = 2.3)
mtext("                                                                                               Percent change in Gini from policy",side=1, line=4, cex=2.1)



# Panel titles 
# (http://www.metafor-project.org/doku.php/plots:forest_plot_with_subgroups)
par(font=2) # Bold
# text(c.lo, 2.55 , "Panel A: Simulated Optimal Consumption Taxes (This paper N=31)", pos=4, cex = 2)
text(c.lo, 1.65 , "Panel B: Studies Using Current Tax Policies (CEQ N=25)", pos=4, cex = 2)

# Runs the whole file to generate the figure 
dev.off()

