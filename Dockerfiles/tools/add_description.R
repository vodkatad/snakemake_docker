#!/usr/bin/env Rscript
# Translate a column with gene symbols adding a column with the corresponding long names.
# TODO FUTURE pass also parameters with the wanted translation

#options(error=traceback)

# Old way with commandArgs
#args <- commandArgs(trailingOnly = FALSE)
# first argument: tsv where the description column will be added
#input <- args[6]
# second argument: the index of the column to be translated
#col_number <- as.integer(args[7])
#output_file <- args[8]

#script_name <- unlist(strsplit(args[4],split="="))[2]
#if (is.na(input) || is.na(col_number) || is.na(output_file)) {
#        stop(paste0("Usage: ", script_name, " input_file col_number"))
#}


library("getopt")

opts <- matrix(c(
        'help', 'h', 0, 'logical',
        'inputfile' , 'i', 1, 'character',
        'outputfile'  , 'o', 1, 'character',
        'to' , 't', 1, 'character',
        'from'  , 'f', 1, 'character',
        'colnumber'  , 'n', 1, 'integer',
        'library', 'l', 1, 'character',
        'hasheader', 'd', 0, 'logical'), ncol=4, byrow=TRUE)
opt <- getopt(opts)



# TODO: probably this if can be skipped if one has the time to fully read getopt manual and set arguments as mandatory
if (is.null(opt$inputfile) || is.null(opt$outputfile) || is.null(opt$colnumber) || !is.null(opt$help) || is.null(opt$to) || is.null(opt$from)) {
    usage <- getopt(opts, usage=TRUE)
    stop(usage)
}
library(AnnotationDbi)

if (is.null(opt$hasheader)) {
 opt$hasheader <- FALSE
}
    
if (is.null(opt$library))  {
    opt$library <- "org.Hs.eg.db"
}
library(opt$library, character.only=TRUE)

if (!opt$hasheader) {
    IDtsv <- read.table(opt$inputfile, stringsAsFactors = FALSE, sep = "\t", quote = "", na.strings=c("", " ", "NA"))
} else {
    IDtsv <- read.table(opt$inputfile, stringsAsFactors = FALSE, sep = "\t", quote = "", na.strings=c("", " ", "NA"), header=TRUE)
}
save.image("p.RData")
keys <- as.character(IDtsv[,opt$colnumber])
merge <- function(x) { paste(x, collapse=',')}
geneIDSymbols <- mapIds(get(opt$library), keys=keys, column=opt$to, keytype=opt$from, multiVals=merge)

IDtsv$description <- as.character(geneIDSymbols)
# 1 ... ncol(IDtsv)
# 1 ... ncol(IDtsv)+1
ncols <- ncol(IDtsv)
neworder <- unique(c(seq(1, opt$colnumber), ncols, seq((opt$colnumber+1), (ncols-1))))
IDtsv <- IDtsv[, neworder]

if (!opt$hasheader) {
    write.table(IDtsv, sep="\t", row.names=FALSE, col.names=FALSE, quote=FALSE, file = opt$outputfile)
} else {
    write.table(IDtsv, sep="\t", row.names=FALSE, col.names=TRUE, quote=FALSE, file = opt$outputfile)
}
