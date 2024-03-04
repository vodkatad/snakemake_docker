#!/usr/bin/env Rscript

library(getopt)

opts <- matrix(c(
  'help', 'h', 0, 'logical', 'help documentation',
  'samples', 's', 1, 'character', 'your file with sample classification: two columns',
  'cris', 'C', 2, 'character', 'CRIS classification file',
  'muts', 'm', 2, 'character', 'mutational status',
  'cetuxi', 'c', 2, 'character', 'cetuximab response',
  'output', 'o', 1, 'character', 'whatever name for the output',
  'directory', 'd', 2, 'character', 'directory to save output files'), ncol=5, byrow=TRUE)
opt <- getopt(opts)

if ( !is.null(opt$help) ) {
  cat(getopt(opts, usage=TRUE))
  q()
}

### create the directory: possibly a new one for each work
dir <- NULL
if ( !is.null(opt$directory) ) {
  dir <- opt$directory
  if ( !dir.exists(dir) ) {
    dir.create(dir, recursive=TRUE)
  }
}

if ( is.null(opt$cris ) ) { opt$cris = "/mnt/trcanmed/snaketree/prj/DE_RNASeq/dataset/Biodiversa_up5_starOK_selected/cris_tmm_0.2_classes_lmx_basali_models_ns.tsv" } # or was it desidered without /?
if ( is.null(opt$muts ) ) { opt$muts = "/mnt/trcanmed/snaketree/prj/pdxopedia/dataset/sanger_targeted_v2_genealogy/driver_muts_genecollapse_wide_models.tsv" }
if ( is.null(opt$cetuxi ) ) { opt$cetuxi = "/mnt/trcanmed/snaketree/prj/pdxopedia/local/share/data/treats/august2020/Treatments_Eugy_Ele_fix0cetuxi_201005_cetuxi3w.tsv" }

library(reshape)
library(tidyverse)

samples <- read.table(opt$samples, sep="\t", quote="", header=TRUE)
cris <- read.table(opt$cris, sep="\t", quote="", header=TRUE)
cetuxi <- read.table(opt$cetuxi, sep="\t", quote="", header=TRUE)
muts <- read.table(opt$muts, sep="\t", quote="", header=TRUE)

names(cetuxi) <- c("case", "perc_cetuxi")
cetuxi$cetuxi <-  ifelse(cetuxi$perc_cetuxi < -50, 'OR', ifelse(cetuxi$perc_cetuxi > 35, 'PD', 'SD'))
cetuxi$perc_cetuxi <- NULL

check <- colnames(samples)[2]
if ( check %in% colnames(muts) ) {
    colnames(samples)[2] <- "cluster"
}

m <- merge(samples, cris, by=1, all.x=TRUE)
mm <- merge(m, cetuxi, by=1, all.x=TRUE)
mmm <- merge(mm, muts, by=1, all.x=TRUE)

write.table(mmm, paste0(dir,opt$output), sep='\t', quote=FALSE, col.names=TRUE, row.names=FALSE)
