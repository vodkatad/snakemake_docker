#!/usr/bin/env Rscript

library(getopt)

opts <- matrix(c(
  'help', 'h', 0, 'logical', 'help documentation',
  'input', 'i', 1, 'character', 'the file you built with prepare',
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

library(reshape)
library(tidyverse)

samples <- read.table(opt$input, sep="\t", quote="", header=TRUE, stringsAsFactors=FALSE)

samples[is.na(samples)] <- ""

wanted <- 1

df <- data.frame(row.names=colnames(samples)[5:ncol(samples)])
df$gene <- rownames(df)
df$pval <- rep(0, nrow(df))


fisher_cluster_all <- function(w, annot, col) {
  info <- data.frame(model=annot[,1], inclass=ifelse(annot[,col] == w, 'yes','no'))
  m <- merge(annot, info, by=1)
  conttabledf <- data.frame(table(m[,2], m[,"inclass"]))
  if ( length(unique(conttabledf$Var2))==1 ) {
    return(100)
  } else {
    conttable <- as.data.frame(matrix(conttabledf$Freq, ncol=2))
    colnames(conttable) <- c("no","yes")
    conttabledf$Var1 <- as.numeric(conttabledf$Var1)
    # rownames(conttable) <- seq(min(conttabledf$Var1),max(conttabledf$Var1))
    # rownames(conttable) <- levels(as.factor(conttabledf$Var1))
    return(fisher.test(conttable, workspace = 2e9)$p.value)
  }
}

for ( n in colnames(samples)[5:ncol(samples)] ) {
  pvals <- sapply(wanted, fisher_cluster_all, samples, n)
  df[n,"pval"] <- pvals
}

df <- df[order(df$pval),,drop=FALSE]
df$pval_adj_Bonf <- p.adjust(df$pval, method = "bonferroni", n = length(df$pval))
df$pval_adj_BH <- p.adjust(df$pval, method = "BH", n = length(df$pval))
df$sign_nom <- ifelse(df$pval<0.05, "yes", "no")
df$sign_adj_Bonf <- ifelse(df$pval_adj_Bonf<0.05, "yes", "no")
df$sign_adj_BH <- ifelse(df$pval_adj_BH<0.05, "yes", "no")

write.table(df, paste0(dir,opt$output), sep='\t', quote=FALSE, col.names=TRUE, row.names=FALSE)
