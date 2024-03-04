#!/usr/bin/env Rscript

library(getopt)

opts <- matrix(c(
  'help', 'h', 0, 'logical', 'help documentation',
  'input', 'i', 1, 'character', 'the file you built with prepare',
  'column', 'c', 1, 'character', 'the column you want to check',
  'output_png', 'p', 1, 'character', 'whatever name for the output (.pdf)',
  'output_tsv', 't', 1, 'character', 'whatever name for the output',
  'directory', 'd', 2, 'character', 'directory to save output files (optional)'), ncol=5, byrow=TRUE)
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
library(dplyr)
library(RColorBrewer)


### Column chosen to focus on
annotation_column <- opt$column

samples <- read.table(opt$input, sep="\t", quote="", header=TRUE, stringsAsFactors=FALSE)
if ( !annotation_column %in% names(samples) ) {
    stop(paste0("No column called ",annotation_column," has been found!"))
}
samples[is.na(samples)] <- ""
samples <- samples[samples[,annotation_column]!="",]
samples[,annotation_column] <- droplevels(as.factor(samples[,annotation_column]))
tot <- nrow(samples)

### distinguish whether you want a class or a gene column
## EG questo funziona ma si rompe non appena dovrai lavorare con una fonte di annotazione diversa per le mutazioni, no?
## se facciamo l'assunto di codificare sempre le mutazioni 0/1 e le altre colonne in modo diverso io farei un if sul contenuto
## dell'annotation column stessa.

### MV verissimo, ci metto mano, TODO
genes <- c("ACVR1B","ACVR2A","APC","ARFGEF1","ARID1A","ARID2","ARID4A","ASXL1","ATM","ATR",    
"ATRX","AXIN2","BAI3","BCL9L","BCLAF1","BCOR","BRAF","BRCA2","CARD11","CBL",    
"CDC27","CDC73","CDH1","CDK12","CDK8","CDKN2A","CLSPN","CREBBP","CSPP1","CTNNB1", 
"DKK2","DUSP16","EGFR","ELF3","EP300","EP400","ERBB2","ERBB3","ERBB4","EZH2",   
"FBXW7","FGFR1","FGFR2","FLT1","GATA3","GNAS","H3F3A","HNF4A","IGF2","IKBKB",  
"IRS2","JAK2","KAT6A","KDM3B","KDM6A","KDR","KIT","KLF5","KRAS","LIG1",   
"MAP2K4","MAP3K4","MARK1","MET","MGA","MLH1","MLH3","MSH2","MSH3","MSH6",   
"MTOR","MYC","NF1","NF2","NRAS","PCBP1","PDGFRA","PIK3CA","PIK3R1","PMS2",   
"POLE","PPP1R3A","PTCH1","PTEN","PTPN11","RB1","RET","RNF43","RSPO2","RSPO3",  
"SETD2","SMAD2","SMAD3","SMAD4","SOX9","STAG2","STK11","TBX3","TCF7L2","TGFBR2", 
"TOP2B","TP53","TP53BP1","TPTE","TRIM23","TRRAP","TSHR","VEGFA","VHL","VTI1A",  
"WT1","ZC3H13")

if ( annotation_column %in% genes ) {
    w <- 1
}else{
    w <- levels(as.factor(samples[,annotation_column]))
}

final <- data.frame(matrix(nrow=2, ncol=2), stringsAsFactors = FALSE)
rownames(final) <- c('1','other')
names(final) <- c('no','yes')

# setwd(dir)
pvals <- data.frame(row.names = w, pval=rep(0,length(w)), cluster=rep("",length(w)), stringsAsFactors = FALSE)

for ( n in 1:length(w) ) {
  df1 <- data.frame(model=samples[,1], inclass=ifelse(samples[,annotation_column] == w[n], 'yes','no'))
  m <- merge(samples, df1, by=1) 
  conttabledf <- as.data.frame(table(m[,2], m[,"inclass"]))
  if ( length(unique(conttabledf$Var2))==1 ) { ### with this, i should be able to pick both "character" and "numeric" classes that have only one class (difficult with CRIS or cetuxi)
                                              ### but it happened for the 3wt part, so, now we have the code covering it just in case     
    if ( unique(conttabledf$Var2)=='yes' ) { ### this check which case we have: again this is mainly for mutations, but it could be used for other cases
        tmp <- data.frame(Var1=conttabledf$Var1, Var2=rep('no', nrow(conttabledf)), Freq=rep(0, nrow(conttabledf)))
        conttabledf <- rbind(conttabledf, tmp)
    } else {
        tmp <- data.frame(Var1=conttabledf$Var1, Var2=rep('yes', nrow(conttabledf)), Freq=rep(0, nrow(conttabledf)))
        conttabledf <- rbind(conttabledf, tmp)
    }
  }
  # EG this addition for corner cases makes sense!
    conttable <- as.data.frame(matrix(conttabledf$Freq, ncol=2))
    colnames(conttable) <- c("no","yes")
    rownames(conttable) <- levels(as.factor(conttabledf$Var1))
    df <- conttable
    for ( i in 1:nrow(df) ) {
        if ( df[i,'yes'] == max(df$yes) ) {
            cl <- rownames(df)[i]
            final[1,] <- df[i,]
            r <- rownames(final)[1] <- cl
            final[2,'no'] <- sum(df$no)-df[i,'no']
            final[2,'yes'] <- sum(df$yes)-df[i,'yes']
        }
    }
  p <- fisher.test(final, workspace=2e8)$p.value
  v <- c(p, r)
  pvals[n,] <- v
}

### old part, i leave it here for now
# if ( length(w) > 1 ) {
#   for ( n in 1:length(w) ) {
#     df1 <- data.frame(model=samples[,1], inclass=ifelse(samples[,annotation_column] == w[n], 'yes','no'))
#     m <- merge(samples, df1, by=1) # non model?
#     conttabledf <- as.data.frame(table(m[,2], m[,"inclass"]))
#     if ( length(unique(conttabledf$Var2))==1 ) {
#     return(100)
#     } else {
#       conttable <- as.data.frame(matrix(conttabledf$Freq, ncol=2))
#       colnames(conttable) <- c("no","yes")
#     # conttabledf$Var1 <- as.numeric(conttabledf$Var1)
#     # rownames(conttable) <- seq(min(conttabledf$Var1),max(conttabledf$Var1))
#       rownames(conttable) <- levels(as.factor(conttabledf$Var1))
#       df <- conttable
#       for ( i in 1:nrow(df) ) {
#         if ( df[i,'yes'] == max(df$yes) ) {
#           cl <- rownames(df)[i]
#           final[1,] <- df[i,]
#           r <- rownames(final)[1] <- cl
#           final[2,'no'] <- sum(df$no)-df[i,'no']
#           final[2,'yes'] <- sum(df$yes)-df[i,'yes']
#         }
#       }
#     }
#     p <- fisher.test(final, workspace=2e8)$p.value
#     v <- c(p, r)
#     pvals[n,] <- v
#   }
# } else {
#   df1 <- data.frame(model=samples[,1], inclass=ifelse(samples[,annotation_column] == w, 'yes','no'))
#   m <- merge(samples, df1, by=1)
#   conttabledf <- as.data.frame(table(m[,2], m[,"inclass"]))
#   if ( length(unique(conttabledf$Var2))==1 ) {
#     return(100)
#   } else {
#     conttable <- as.data.frame(matrix(conttabledf$Freq, ncol=2))
#     colnames(conttable) <- c("no","yes")
#     rownames(conttable) <- levels(as.factor(conttabledf$Var1))
#     df <- conttable
#   for ( i in 1:nrow(df) ) {
#     if ( df[i,'yes'] == max(df$yes) ) {
#       cl <- rownames(df)[i]
#       final[1,] <- df[i,]
#       r <- rownames(final)[1] <- cl
#       final[2,'no'] <- sum(df$no)-df[i,'no']
#       final[2,'yes'] <- sum(df$yes)-df[i,'yes']
#     }
#   }
#   p <- fisher.test(final, workspace=2e8)$p.value
#   v <- c(p, r)
#   pvals[1,] <- v
# }

write.table(pvals, paste0(dir,opt$output_tsv), sep='\t', quote=FALSE, col.names=TRUE, row.names=TRUE)

clusters <- data.frame(table(samples$cluster))
names(clusters) <- c("cluster","value")

percentages <-  function(w, annot, col, tot) {
    pp <- data.frame(model=annot[,1], inclass=ifelse(annot[,col] == w, 'yes','no'))
    m <- merge(annot, pp, by=1)
    cdf <- as.data.frame(table(m[,2], m[,"inclass"]))
    clusters_id <- unique(cdf$Var1)
    # frac <- sapply(clusters_id, function(x) { cdf[cdf$Var1==x & cdf$Var2=="yes","Freq"]/sum(cdf[cdf$Var1==x,"Freq"])} )
    frac <- sapply(clusters_id, function(x) { cdf[cdf$Var1==x & cdf$Var2=="yes","Freq"]/tot} )
    return(frac)
}

summ <-  function(w, annot, col) {
  pp <- data.frame(model=annot[,1], inclass=ifelse(annot[,col] == w, 'yes','no'))
  m <- merge(annot, pp, by=1)
  cdf <- as.data.frame(table(m[,2], m[,"inclass"]))
  clusters_id <- unique(cdf$Var1)
  summm <- sapply(clusters_id, function(x) { cdf[cdf$Var1==x & cdf$Var2=="yes","Freq"]})
  return(summm)
}

percs_owar <- sapply(w, percentages, samples, annotation_column, tot)
rownames(percs_owar) <- levels(as.factor(samples[,2]))
summ_owar <- sapply(w, summ, samples, annotation_column)
rownames(summ_owar) <- levels(as.factor(samples[,2]))

dfp <- melt(percs_owar)
dfs <- melt(summ_owar)
colnames(dfp) <- c("cluster",annotation_column,"fraction")
colnames(dfs) <- c("cluster",annotation_column,"value")
dfp <- dfp[order(dfp$cluster, dfp[,annotation_column]),]
dfs <- dfs[order(dfs$cluster, dfs[,annotation_column]),]
dfs[,c("cluster",annotation_column)] <- NULL
dfp <- cbind(dfp, dfs)
## EG non riesco ora a visualizzare il dato a questo punto e/o a fare una prova interattiva, ne parliamo poi a voce alla prima occasione?
## 1-dfp$fraction e -dfs$value sono i miei crucci perc`he non so bene a sto punto in caso di tutti mutati (o non mutati) cosa ci sia dentro
if ( length(unique(dfp[,annotation_column]))==1 ) {  ### again mainly for genes cause we usually look for mutations (1) so we lose the 0s
    if ( unique(dfp[,annotation_column]==1) ) {
        tmp <- data.frame(cluster=dfp$cluster, col=rep(0,nrow(dfp)), fraction="", value=clusters$value-dfs$value, stringsAsFactors = FALSE)
        names(tmp)[2] <- annotation_column
        tmp$fraction <- tmp[tmp[,annotation_column]==0,]$value/tot
    } else { ### this else is kinda useless? but just in case
        tmp <- data.frame(cluster=dfp$cluster, col=rep(1,nrow(dfp)), fraction="", stringsAsFactors = FALSE)
        names(tmp)[2] <- annotation_column
        tmp$fraction <- tmp[tmp[,annotation_column]==1,]$value/tot
    }
    dfp <- rbind(dfp, tmp)
}
dfp$fraction <- round(dfp$fraction,2)*100 ### to have the fraction in % in the plot

# save.image("pippo.try.RData")

### plot and apply some colors
if ( class(dfp[,annotation_column])=="factor") { ### here it should picks more colors if there are many classes, while checking if it is a factor or numeric (numeric should be for the genes)
    colourCount = length(unique(dfp[,annotation_column]))
    getPalette = colorRampPalette(brewer.pal(9, "Set1"))
    colScale <- scale_fill_manual(values=getPalette(colourCount))
} else {
    dfp[,annotation_column] <- factor(dfp[,annotation_column], levels = c("0","1")) ### find two colors for mut and wt
    colScale <- scale_fill_brewer(palette="Dark2")
}
if ( annotation_column == 'CRISX' | annotation_column == 'cris' ) { ### here I specify order and colors for the 2 classes we are interested in the most
    dfp[,annotation_column] <- factor(dfp[,annotation_column], levels = c("CRIS-A","CRIS-B","CRIS-C",
                                                                          "CRIS-D","CRIS-E","NA"))
    colScale <- scale_fill_manual(values = c("CRIS-A"="darkorange1",
                                             "CRIS-B"="red",
                                             "CRIS-C"="blue4",
                                             "CRIS-D"="darkgreen",
                                             "CRIS-E"="aquamarine2",
                                             "NA"="black"))
} else if ( annotation_column == "cetuxi") {
    colScale <- scale_fill_manual(values = c("OR"="steelblue",
                                             "SD"="orange",
                                             "PD"="red"))
    dfp[,annotation_column] <- factor(dfp[,annotation_column], levels = c("OR","SD","PD"))
}

# png(paste0(dir,opt$output_png), width=1280, height=720, units="px", type="cairo")
pdf(paste0(dir,opt$output_png), width=15, height=8)
ggplot(data=dfp, aes_string(x="cluster", y="fraction", fill=annotation_column)) +
    geom_bar(stat="identity", position=position_dodge()) +
    geom_text(aes(label=value), position=position_dodge(0.9), vjust=-0.2, color="black", size=7) +
    # ylim(0, 30) +
    colScale +
    labs(title="Clusters enrichment", subtitle=annotation_column) +
    theme_bw(base_size = 15)
# graphics.off()
dev.off()
