# This script is a simple demonstration of using the rgbif package to standardize taxonomic information from multiple different sources (GBIF, NCBI, NMNH).
# There are many tools to standardize taxonomic information. This paper does an excellent job of reviewing them and outlining best practices: Grenié, Matthias, Emilio Berti, Juan Carvajal‐Quintero, Gala Mona Louise Dädlow, Alban Sagouis, and Marten Winter. "Harmonizing taxon names in biodiversity data: a review of tools, databases, and best practices." Methods in Ecology and Evolution (2021).
# Contact me a pfeifferj@si.edu if you have questions or concerns.

#load libraries
library(rgbif)
library(tidyverse)    
library(RAM)

### SECTION 1: Make a list of all Recent mollusc families ###
#find the taxon key for mollusca
name_backbone(name='mollusca', rank='phylum')

#look up all the Accepted, non-extinct, family-level mollusc names
out <- name_lookup(higherTaxonKey = 52, rank = "family", status = "Accepted", isExtinct = FALSE, limit = 10000)

#grab just the "data" tibble
mollusc_fams <- out[["data"]]

#make a list of unique fam names
mollusc_fams_list <- unique(mollusc_fams$family)
length(mollusc_fams_list)

### SECTION 2: get a list "all" taxa that have mt genomes (according to NCBI Organelle Genome Resources) and then standardize their taxonomic information
#get a list all taxa that have mt genomes - https://www.ncbi.nlm.nih.gov/genome/organelle/
#this is list is incomplete but it is what NCBI serves up for one reason or another idk

#load the csv that list all the animal taxa that have mt genomes (THE HAVES)
have_mt_orig <- read_csv("/Users/johnpfeiffer/Desktop/carpentries/animal_mt_genomes.csv", trim_ws = TRUE, col_types = cols(.default = "c"))

demo <- name_backbone(name = "Lampsilis ventricosa")

#identify unique species names in the data to minimize calls to GBIF name_backbone
mt_orig_names<-unique(have_mt_orig$orig_species)

#start the for loop - take each unique name, search gbif backbone, return and keep the results. this standardizes everything. 11k names takes about 30 minutes on my laptop
taxa_key <- NULL #initialize an empty dataframe to be filled
for(u in mt_orig_names){
  temp_df<-name_backbone(name = u) %>% #pull down data from the gbif backbone
    mutate(orig_species=u) # keep track of the original name
  taxa_key<-bind_rows(temp_df, taxa_key) #build the dataframe
}

# join the standardized taxonomy with the original data 
have_mt_standard<-left_join(have_mt_orig, taxa_key, 
                           by="orig_species")

#filter to include only mollusc
mollusc_mt_standard <- have_mt_standard %>% filter(phylum == "Mollusca")

#get a list of all mollusc families that have mt genome
mollusc_fams_mt_list <- unique(mollusc_mt_standard$family)

#check and remove NA values
any(is.na(mollusc_fams_mt_list))
#mollusc_fams_mt_list <- na.omit()

length(mollusc_fams_mt_list)

### SECTION 3: Make a list of mollusc families USNM has tissue for ###
#read in IZ biorepository data
usnm_orig <- read_csv("/Users/johnpfeiffer/Desktop/carpentries/iz_biorepo_small.csv", trim_ws = TRUE, col_types = cols(.default = "c"))

#filter to include only molluscs
usnm_mollluscs <- usnm_orig %>% filter(ClaPhylum == "Mollusca")

#identify unique family names in the data to minimize calls to name_backbone
usnm_mollluscs_orig_names <- unique(usnm_mollluscs$ClaFamily)

#start the for loop - take each unique name, search gbif backbone, return and keep the results
taxa_key <- NULL #initialize an empty dataframe to be filled
for(u in usnm_mollluscs_orig_names){
  temp_df<-name_backbone(name = u) %>% #pull down data from the gbif backbone # add strict=TRUE to prevent names from being added to higher rank
    mutate(ClaFamily=u) # keep track of the original name
  taxa_key<-bind_rows(temp_df, taxa_key) #build the dataframe
}

# join the key with the museum data using the column verbatim_name
usnm_mollluscs_standardardized<-left_join(usnm_mollluscs, taxa_key, 
                            by="ClaFamily")

#get a list of all families
mollusc_fams_usnm_list <- unique(usnm_mollluscs_standardardized$family)

#check and remove NA values
any(is.na(mollusc_fams_usnm_list))
mollusc_fams_usnm_list <- na.omit(mollusc_fams_usnm_list)
length(mollusc_fams_usnm_list)

### SECTION 4: make comparisons between the lists - all families, all fam with mt dna, all familes in biorepository ####
#find the familes that do not have mt genomes - the have nots
have_not_fams <- setdiff(mollusc_fams_list, mollusc_fams_mt_list)
length(have_not_fams)

#check to make sure there are no mismatches
both <- c(mollusc_fams_mt_list, have_not_fams)
setequal(both, mollusc_fams_list)

#of the familes that do not, which ones do we have tissue for - the might coulds
might_could_fams <- intersect(have_not_fams, mollusc_fams_usnm_list)
length(might_could_fams)

# filter down the stadardized Biorepositry records (usnm_standard) to only include records from families that don't have mt DNA
mollusc_targets <- usnm_mollluscs_standardardized %>% filter(family %in% might_could_fams)
write.csv(mollusc_targets, file = "usnm_targets.csv")


### SECTION 5: make some graphics ###

#all mollusc fams and the haves
group.venn(list(All_Mollusc_Families=mollusc_fams_list, The_Haves=mollusc_fams_mt_list),label = FALSE,
           fill = c("orange", "blue"),
           cat.pos = c(0, 0),
           lab.cex=0.5, cat.cex = 1)

#familes without mt DNA and families with records in Biorepository
group.venn(list(families_without_mt_genome=have_not_fams, families_in_Biorepository=mollusc_fams_usnm_list),label = FALSE,
           fill = c("orange", "blue"),
           cat.pos = c(0, 0),
           lab.cex=0.5, cat.cex = 1)

### above Venn with prep type
usnm_dna <- usnm_mollluscs_standardardized %>% filter(GSTypePrimary == "DNA, RNA, Proteins")
usnm_tissue <- usnm_mollluscs_standardardized %>% filter(GSTypePrimary != "DNA, RNA, Proteins")

#get a list of all families
#separate out dna and tissues
usnm_fam_dna <- unique(usnm_dna$family)
usnm_fam_tissue <- unique(usnm_tissue$family)

#remove NA value
usnm_fam_dna <- usnm_fam_dna[!is.na(usnm_fam_dna)]
usnm_fam_tissue <- usnm_fam_tissue[!is.na(usnm_fam_tissue)]

#familes without mt DNA, families with DNA, and families with tissues
group.venn(list(families_without_mt_genome=have_not_fams, families_with_dna=usnm_fam_dna, families_with_tissue=usnm_fam_tissue),label = FALSE,
           fill = c("orange", "blue", "red"),
           cat.pos = c(340, 20, 180),
           lab.cex=0.5, cat.cex = 1)


#Consider carefully exploring the data cuz the GBIF backone is not perfect. 
#For example: Actinopterygii snuck in here because Chilodontidae is a homonym (in mollluscs and fish).
#The ICZN ruling on thse names has not yet been incorporated to GBIF backbone
usnm_mollluscs_standardardized %>% count(class)
demo2 <- usnm_mollluscs_standardardized %>% filter(class=="Actinopterygii")


        