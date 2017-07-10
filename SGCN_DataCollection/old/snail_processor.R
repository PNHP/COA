
setwd("C:/Users/ctracey/Dropbox (Personal)/coa_data/cmnh_snails")

library(lubridate)
library(data.table)

# list of snail SGCN
SGCN <- read.csv("SGCNmollusks.csv")
keeps <- c("ELCODE","Common_Name","Scientific_Name")
SGCN <- SGCN[keeps]

setnames(SGCN, old=c("Scientific_Name","Common_Name"),new=c("SNAME","SCOMNAME"))
SGCN <- unique(SGCN)

# existing data in the CMNH database
SnailOlder <- read.csv("snail_older.csv")
# merge and drop nonSGCN
SnailOlder$SNAME <- paste(SnailOlder$Genus,SnailOlder$Species)
SnailOlder <- merge(x=SnailOlder, y=SGCN, by="SNAME", all=TRUE)
SnailOlder <- SnailOlder[!is.na(SnailOlder$ELCODE),]
SnailOlder <- SnailOlder[(SnailOlder$Latitude!=""),]

## drop a bunch of columns that we don't need
keeps <- c("SNAME","Catalog.Number","Latitude","Longitude","Coordinate.Precision","Date.1")
SnailOlder1 <- SnailOlder[keeps]

# process the dates

a <- parse_date_time(SnailOlder1$Date.1, orders=c("Y", "Ym"))

#SGCN <- NULL
SnailOlder$date <- ymd(SnailOlder$Date.1)

# newer data not yet in the db
SnailNewer <- read.csv("snail_newer.csv")

