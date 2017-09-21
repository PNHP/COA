# wrong ELCODE, mostly for subspecies, update to SWAP
spXpu1$El_Season[spXpu1$El_Season=="AAAAD13010_y"] <- "AAAAD13014_y"  #Pseudotriton montanus montanus
spXpu1$El_Season[spXpu1$El_Season=="AAABH01220_y"] <- "AAABH01222_y"  #Lithobates sphenocephalus utricularius
spXpu1$El_Season[spXpu1$El_Season=="AAABH01400_y"] <- "AAABH01170_y" # Lithobates pipiens
spXpu1$El_Season[spXpu1$El_Season=="ABNNF19020\n_b"] <- "ABNNF19020_b"
spXpu1$El_Season[spXpu1$El_Season=="ABNUA03010\n_b"] <- "ABNUA03010_b"
spXpu1$El_Season[spXpu1$El_Season=="ABPBX05010\n_b"] <- "ABPBX05010_b"
spXpu1$El_Season[spXpu1$El_Season=="ARAAE01050_y"] <- "ARAAE01053_y"
spXpu1$El_Season[spXpu1$El_Season=="IIODO08190_y"] <- "IIODO08191_y" # Gomphus septima delawarensis
spXpu1$El_Season[spXpu1$El_Season=="IIODO12100_y"] <- "IIODO12102_y"
spXpu1$El_Season[spXpu1$El_Season=="AMAFB09020_b"] <- "AMAFB09020_y" # northern flying sq
spXpu1$El_Season[spXpu1$El_Season=="AABPBXB2020_b"] <- "ABPBXB2020_b" # meadowlark, extra 'a' in ELCODE
spXpu1$El_Season[spXpu1$El_Season=="ABPBX05010\n_b"] <- "ABPBX05010_b" 
spXpu1$El_Season[spXpu1$El_Season==""] <- ""



# labeled as a SGCN for a season that its not listed.
# delete these from the file
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNCA02010_m"),]  #Pied-billed Grebe
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNGA01020_m"),]  #least bittern
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNGA02010_m"),]  #amererican bittern
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNGA04040_m"),]  #great egert
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNJB10010_m"),]  #green winged teal
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNKC01010_m"),]  #osprey
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNKC10010_m"),]  #bald eagle
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNKC11010_m"),]  #harrier
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNME05030_m"),]  #virginia rail
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNME08020_m"),]  #sora
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABNME14020_m"),]  #american coot
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABPAE32010_m"),]  #olive sided flycather
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABPBG10010_m"),]  #sedge wren
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABPBG10020_m"),]  #marsh wren
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABPBJ18100_m"),]  #swainsons thrush
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABPBX03230_m"),]  #blackpoll warbler
spXpu1 <- spXpu1[!(spXpu1$El_Season=="ABPBX07010_m"),]  #prot warbler
spXpu1 <- spXpu1[!(spXpu1$El_Season=="AMACC03020_b"),]  #tricolorerd bat
spXpu1 <- spXpu1[!(spXpu1$El_Season=="IMBIV14060_y"),]  # Elliptio complanata, this isn't a SGCN--deleting for now.
spXpu1 <- spXpu1[!(spXpu1$El_Season==""),]
 
# what season?
spXpu1$El_Season[spXpu1$El_Season=="ABPBX03240_y"] <- "ABPBX03240_b" # Cerulean Warbler, I think this is supposed to be breeding based on the other values in the table.
spXpu1$El_Season[spXpu1$El_Season=="ABNKC10010_u"] <- "ABNKC10010_b"   # bald eagle -- what's this code mean? Going with Breeding.
