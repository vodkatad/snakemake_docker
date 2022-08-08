#!/usr/bin/env Rscript
library("biomaRt")

## tool to translate from mouse to human and the other way around

# get opt deve avere 5 argometni un input che sono i geni, 2 RDS, 1 output df e un ouptud differenti
# in-attribute e out-attribute che devono essere corrispondenti agli RDS deve essere come SYMBOL and ENSEMBLE di 
# get attributes

# mouse <- "/mnt/cold1/snaketree/prj/scRNA/local/share/data/Norkin_etal.tsv"
# m <- read.table(mouse, quote = "", sep = "\t", header = FALSE, stringsAsFactors = FALSE)
# colnames(m) <- c("Gene", "Type")


# mouse_genes <- m$Gene
# mouse_genes_prova <- head(mouse_genes)

##input files need to become a list so it's needed a df with one column
library("getopt")

opts <- matrix(c(
        'help', 'h', 0, 'logical',
        'inputfile', 'i', 1, 'character',
        'outputfile_df', 'o', 1, 'character',
        'outputfile_txt', 'x', 1, 'character',
        'to_rds', 't', 1, 'character',
        'from_rds', 'f', 1, 'character',
        'to_attribute', 'T', 1, 'character',
        'from_attribute', 'F', 1, 'character',
        'hasheader', 'd', 0, 'logical'), ncol=4, byrow=TRUE)
opt <- getopt(opts)


# TODO: probably this if can be skipped if one has the time to fully read getopt manual and set arguments as mandatory
if (!is.null(opt$help) || is.null(opt$inputfile) || is.null(opt$outputfile_df) || is.null(opt$outputfile_txt) ||is.null(opt$to_rds) || is.null(opt$from_rds) || is.null(opt$to_attribute) || is.null(opt$from_attribute)) {
    usage <- getopt(opts, usage=TRUE)
    stop(usage)
}
if (!opt$hasheader) {
    gene <- read.table(opt$inputfile, stringsAsFactors = FALSE, sep = "\t", quote = "", na.strings=c("", " ", "NA"))
} else {
    gene <- read.table(opt$inputfile, stringsAsFactors = FALSE, sep = "\t", quote = "", na.strings=c("", " ", "NA"), header=TRUE)
}
genelist <- gene[,1]

from_rds_object <- readRDS(opt$from_rds)
to_rds_object <- readRDS(opt$to_rds) 

convertMouseGeneList <- function(x, from_Rds, in_Rds){
  require("biomaRt")
  genesV2 = getLDS(attributes = c(opt$from_attribute), filters = opt$from_attribute, 
                   values = x , mart = from_Rds, attributesL = c(opt$to_attribute), martL = in_Rds, uniqueRows=T)
  return(genesV2)
}


translated_genes <- as.data.frame(convertMouseGeneList(genelist, from_rds_object, to_rds_object))
differences <- setdiff(genelist, translated_genes$MGI.symbol) 

if (!opt$hasheader) {
    write.table(translated_genes, sep="\t", row.names=FALSE, col.names=FALSE, quote=FALSE, file = opt$outputfile_df)
} else {
    write.table(translated_genes, sep="\t", row.names=FALSE, col.names=TRUE, quote=FALSE, file = opt$outputfile_df)
}

if (!opt$hasheader) {
    write.table(differences, sep="\t", row.names=FALSE, col.names=FALSE, quote=FALSE, file = opt$outputfile_txt)
} else {
    write.table(differences, sep="\t", row.names=FALSE, col.names=TRUE, quote=FALSE, file = opt$outputfile_txt)
}

