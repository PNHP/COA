library("bdvis")

install.packages("rinat") 
require(rinat)  # Data download might take some time
inat=get_inat_obs_project("nine-mile-run-watershed") 
inat=format_bdvis(inat,source='rinat')

bdsummary(inat) 

mapgrid(inat,ptype="records",bbox=c(33.836081 , -84.268548,  43.0909222956 , -78.029881))

tempolar(inat, color="green", title="iNaturalist daily", plottype="r", timescale="d") 
tempolar(inat, color="blue", title="iNaturalist weekly", plottype="p", timescale="w") 
tempolar(inat, color="red", title="iNaturalist monthly", plottype="r", timescale="m")

#inat=gettaxo(inat) 
#taxotree(inat) 

chronohorogram(inat) 

comp=bdcomplete(inat,recs=5)
mapgrid(comp,ptype="complete",bbox=c(60,100,5,40),region=c("India"))

distrigraph(inat,ptype="cell",col="tomato") 
distrigraph(inat,ptype="species",ylab="Species") 
distrigraph(inat,ptype="efforts",col="red") 
distrigraph(inat,ptype="efforts",col="red",type="s")


bdcalendarheat(inat) 
