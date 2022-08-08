#!/usr/bin/env Rscript

set.seed(42)

library(getopt)

opts <- matrix(c(
  'help', 'h', 0, 'logical', 'help documentation',
  'df_in', 'i', 1, 'character', 'dataframe with features (rows) and samples (header)',
  'cluster_in', 'c', 1, 'character', 'file with sample-classification association (with header)',
  'k_in', 'k', 1, 'integer', 'number of clusters',
  'fsel', 'f', 2, 'character', 'path to specific features to use (no header in files)',
  'silho', 's', 2, 'character', 'if you have a file with silhouette value and want to filter samples with negative silhouette width',
  'directory', 'd', 1, 'character', 'directory to save output files',
  'output', 'o', 1, 'character', 'name for output files'
  ), ncol=5, byrow=TRUE)
opt <- getopt(opts)

if ( !is.null(opt$help) ) {
  cat(getopt(opts, usage=TRUE))
  q()
}

dir <- opt$directory
if ( dir.exists(dir) ) {
  stop("Directory already exists, please specify a new directory")  
} else {
  dir.create(dir)
}
# setwd(opt$directory)

library(randomForest)
library(tidyverse)
library(dplyr)
library(caTools)

k <- opt$k_in

df <- read.table(gzfile(opt$df_in), sep = '\t', row.names=1, header=TRUE, quote="", stringsAsFactors=FALSE)
cl <- read.table(opt$cluster_in, sep = '\t', row.names=1, header=TRUE, quote="", stringsAsFactors=FALSE)
names(cl) <- "cluster"
tab <- as.data.frame(table(cl$cluster))
sampsize <- min(tab$Freq)
mtry <- round(sqrt(nrow(df)),0)


if ( !is.null(opt$silho) ) {
    width <- read.table(opt$silho, sep = '\t', header=FALSE, quote="", stringsAsFactors=FALSE)
    width <- width[width$V2>0,]
    df <- df[,names(df) %in% width$V1]
    cl <- cl[rownames(cl) %in% width$V1,,drop=FALSE]
    tab <- as.data.frame(table(cl$cluster))
    sampsize <- min(tab$Freq)
}


if ( !is.null(opt$fsel) ) {
    path <- opt$fsel
    feats <- data.frame()
    features <- list.files(path=path, full.names=TRUE)
    for ( f in seq(features) ) {
        fsel <- read.table(features[f], sep = '\t', header=FALSE, quote="", stringsAsFactors=FALSE)
        feats <- rbind(feats,fsel)
    }
    names(feats) <- "features"
    df <- df[row.names(df) %in% feats$features,]
    mtry <- round(sqrt(nrow(df)),0)
}


df <- as.data.frame(t(df))
mm <- merge(df, cl, by=0)
rownames(mm) <- mm$Row.names
mm$Row.names <- NULL
mm <- mm %>%
    dplyr::select(cluster, everything())
mm$cluster <- as.factor(mm$cluster)


rf <- randomForest(cluster ~ ., data=mm,
                   do.trace=100,
                  #  na.action=na.roughfix,
                   ntree=1000,
                   mtry=mtry,
                   replace=TRUE,
                   importance=TRUE,
                   # proximity=TRUE,
                   sampsize=rep(sampsize,k)
                   )

setwd(dir)

sink(paste0(opt$output,".txt"))
print(rf)
sink()

save.image(paste0(opt$output,".RData"))

