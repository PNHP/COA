setwd("E:/coa2/temp_tables_for_sqlite")

myvars <- c("unique_id", "pres")


ag <- read.csv("tmp_aghex.csv")
ag$pres <- "y"
ag <- ag[myvars]
amd <- read.csv("tmp_amdhex.csv")
amd$pres <- "y"
amd <- amd[]
amd <- amd[myvars]

threats <- read.csv("lu_threats.csv")

threats <- merge(threats,ag,all.x=TRUE)
threats$StmImpAg[threats$pres=='y'] <-  'y'
threats$pres <- NULL
threats <- merge(threats,amd,all.x=TRUE)
threats$StrImpAMD[threats$pres=='y'] <-  'y'
threats$pres <- NULL

colnames(threats)[colnames(threats) == 'StmImpAg'] <- 'StrImpAg'

write.csv(threats,"lu_threats_update.csv")
