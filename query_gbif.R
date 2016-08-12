library("rgbif")
library("maps")

sgcn <- c('Piranga olivacea',"Quercus alba") # yeah, these are currently plants

#keys <- sapply(sgcn, function(x) name_suggest(x)$key[1], USE.NAMES=FALSE)
#occ_count(taxonKey=keys, georeferenced = TRUE)

### NEED to get rid of counts that are equal to '0' as they cause an out of range error below

keys <- sapply(sgcn, function(x) name_suggest(x)$key[1], USE.NAMES=FALSE)
OS1 <- occ_search(
                    taxonKey=keys,
                    hasCoordinate=TRUE,
                    geometry=c(-80.5195, 39.7199, -74.6896, 42.2695), 
                    year='1980,2016',
                    limit=500,
                    return="data",
                    fields=c('name','key','decimalLatitude','decimalLongitude','country','basisOfRecord','coordinateAccuracy','year','month','day'),
                    minimal=FALSE
                ) # bounding box of Pennsylvania -80.5195, 39.7199, -74.6896, 42.2695

#OS1 <- occ_search(taxonKey=keys, fields=c('name','key','decimalLatitude','decimalLongitude','country','basisOfRecord','coordinateAccuracy','elevation','elevationAccuracy','year','month','day'), minimal=FALSE,limit=10, return='data')

filenames <- paste(sapply(sapply(OS1, FUN = "[[", "name", simplify = FALSE), unique), ".txt", sep = "")
mapply(OS1, filenames, FUN = function(x, y) write.table(x, file = y, row.names = FALSE))