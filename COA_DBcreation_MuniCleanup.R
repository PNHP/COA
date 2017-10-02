setwd("E:/coa2/temp_tables_for_sqlite")

muni <- read.csv("tmp_municipalities.csv")

myvars <- c("unique_id", "FIPS_MUN_P", "Name_Proper_Type")
muni <-muni[myvars]
myvars <- c("FIPS_MUN_P","Name_Proper_Type")
muni_names <- muni[myvars]
muni_names <- unique(muni_names)
muni_names <- muni_names[order(muni_names$FIPS_MUN_P),]
write.csv(muni_names, "lu_muni_names.csv")

myvars <- c("unique_id", "FIPS_MUN_P")
muni <-muni[myvars]
muni <- muni[order(muni$unique_id),]
write.csv(muni, "lu_muni.csv")
