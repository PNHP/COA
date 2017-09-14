library(reshape)
lu_HabitatTerrestrialLentic <- read.csv("lu_HabitatTerrestrialLentic.csv")

lu_HabitatTerrestrialLentic1 <- melt(lu_HabitatTerrestrialLentic, id=c("unique_id"))
lu_HabitatTerrestrialLentic1 <- lu_HabitatTerrestrialLentic1[ which(lu_HabitatTerrestrialLentic1$value!=0), ]
lu_HabitatTerrestrialLentic1 <- lu_HabitatTerrestrialLentic1[ which(lu_HabitatTerrestrialLentic1$value!=-1), ]
write.csv(lu_HabitatTerrestrialLentic1,"TerrHabitatReshape.csv")
