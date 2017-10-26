library(devtools)
install_github("ChristopherTracey/natserv")
library(natserv)

# http://services.natureserve.org/docs/schemas/biodiversityDataFlow/1/1/documentation_comprehensiveSpecies_v1.1.xml
# need to set an environment varible for the NatureServe key
Sys.setenv(NATURE_SERVE_KEY="72ddf45a-c751-44c7-9bca-8db3b4513347")

sgcnlist <- read.csv("lu_sgcn.csv")
sgcnELCODE <- sgcnlist$ELCODE

#splist <- c("ELEMENT_GLOBAL.2.101808","ELEMENT_GLOBAL.2.100312")
splist <- read.csv("tracked_species_universal_id_pa_20170530.csv")
splist <- splist[splist$ELCODE %in% sgcnELCODE,]
splist$UID <- paste("ELEMENT_GLOBAL",splist$ELEMENT_GLOBAL_OU_UID,splist$ELEMENT.GLOBAL.UNIVERSAL.KEY,sep=".")
splist <- splist[ which(substr(splist$ELCODE,1,1)=="I"), ]
splist <- splist$UID
#splist <- "ELEMENT_GLOBAL.2.101808
results <- list()
for(i in 1:length(splist)) {
  delayedAssign("do.next", {next})
  tryCatch(res <- ns_data(uid = splist[i]), finally=print(splist[i]), error=function(e) force(do.next))

  print("Palustrine Habitats")
  habitat_pal <- res[[1]]$ecologyAndLifeHistory$habitats$palustrineHabitats
  if(!is.null(habitat_pal)) {
    hab_pal <- data.frame(matrix(unlist(habitat_pal, use.names=T), nrow=length(habitat_pal), byrow=T))
    names(hab_pal)[1]<-"habitat"
    type="Palustrine"
    hab_pal <- cbind(hab_pal, type)
    hab_pal$habitat <- as.character(hab_pal$habitat)
    hab_pal$type <- as.character(hab_pal$type)
  }
  print("lacustrine Habitats")
  habitat_lac <- res[[1]]$ecologyAndLifeHistory$habitats$lacustrineHabitats
  if(!is.null(habitat_lac)) {
    hab_lac <- data.frame(matrix(unlist(habitat_lac, use.names=T), nrow=length(habitat_lac), byrow=T))
    names(hab_lac)[1]<-"habitat"
    type="Lacustrine"
    hab_lac <- cbind(hab_lac, type)
    hab_lac$habitat <- as.character(hab_lac$habitat)
    hab_lac$type <- as.character(hab_lac$type)
  }
  print("terrestrial Habitats")
  habitat_ter <- res[[1]]$ecologyAndLifeHistory$habitats$terrestrialHabitats
  if(!is.null(habitat_ter)) {
    hab_ter <- data.frame(matrix(unlist(habitat_ter, use.names=T), nrow=length(habitat_ter), byrow=T))
    names(hab_ter)[1]<-"habitat"
    type="Terrestrial"
    hab_ter <- cbind(hab_ter, type)
    hab_ter$habitat <- as.character(hab_ter$habitat)
    hab_ter$type <- as.character(hab_ter$type)
  }
  print("estuarine Habitats")
  habitat_est <- res[[1]]$ecologyAndLifeHistory$habitats$estuarineHabitats
  if(!is.null(habitat_est)) {
    hab_est <- data.frame(matrix(unlist(habitat_est, use.names=T), nrow=length(habitat_est), byrow=T))
    names(hab_est)[1]<-"habitat"
    type="estuarine"
    hab_est <- cbind(hab_est, type)
    hab_est$habitat <- as.character(hab_est$habitat)
    hab_est$type <- as.character(hab_est$type)
  }
  print("Riverine Habitats")
  habitat_riv <- res[[1]]$ecologyAndLifeHistory$habitats$riverineHabitats
  if(!is.null(habitat_riv)) {
    hab_riv <- data.frame(matrix(unlist(habitat_riv, use.names=T), nrow=length(habitat_riv), byrow=T))
    names(hab_riv)[1]<-"habitat"
    type="Riverine"
    hab_riv <- cbind(hab_riv, type)
    hab_riv$habitat <- as.character(hab_riv$habitat)
    hab_riv$type <- as.character(hab_riv$type)
  }
  print("Subterranean Habitats")
  habitat_sub <- res[[1]]$ecologyAndLifeHistory$habitats$subterraneanHabitats
  if(!is.null(habitat_sub)) {
    hab_sub <- data.frame(matrix(unlist(habitat_sub, use.names=T), nrow=length(habitat_sub), byrow=T))
    names(hab_sub)[1]<-"habitat"
    type="Subterranean"
    hab_sub <- cbind(hab_sub, type)
    hab_sub$habitat <- as.character(hab_sub$habitat)
    hab_sub$type <- as.character(hab_sub$type)
  }
  habitat_all <- rbind(if(exists("hab_est"))hab_est, if(exists("hab_pal"))hab_pal, if(exists("hab_ter"))hab_ter, if(exists("hab_lac"))hab_lac, if(exists("hab_riv"))hab_riv, if(exists("hab_sub"))hab_sub)

  sgcnname <- unlist(res[[1]]$classification$names$scientificName$unformattedName)
  habitat_all <- cbind(sgcnname,habitat_all)

  #hab_comments <- unlist(res[[1]]$ecologyAndLifeHistory$habitats$habitatComments)
  #if (is.null(hab_comments)) {
  #   habitat_all$hab_comments <- "NA"
  #} else if (!is.null(hab_comments)) {
  #  habitat_all <- cbind(habitat_all,hab_comments)
  #}

  results[[i]] <- habitat_all
  hab_lac<-NULL
  hab_pal<-NULL
  hab_ter<-NULL
  hab_riv<-NULL
  hab_est<-NULL
  hab_sub<-NULL
  sgcnname<-NULL
}

results_df<-ldply(results, data.frame)
