#!/usr/bin/env Rscript
# Convert a tsv to xls

#options(error=traceback)

library("getopt")
library("openxlsx")

opts <- matrix(c(
        'help', 'h', 0, 'logical',
        'inputfileS' , 'i', 1, 'character', # can be comma separated list of files or a single one
        'sheetnames' , 's', 1, 'character', # can be comma separated list of sheetnames or a single one
        'outputfile'  , 'o', 1, 'character'), ncol=4, byrow=TRUE)
opt <- getopt(opts)


# TODO: probably this if can be skipped if one has the time to fully read getopt manual and set arguments as mandatory
if (is.null(opt$inputfile) || is.null(opt$outputfile) || is.null(opt$sheetnames) || !is.null(opt$help)) {
    usage <- getopt(opts, usage=TRUE)
    stop(usage)
}

files <- unlist(strsplit(opt$inputfileS, ','))
sheetnames <- unlist(strsplit(opt$sheetnames, ','))
if (length(files) != length(sheetnames)) {
    print(files)
    print(sheetnames)
    stop('-i and -s need to be a single file/name or two comma separated list of the same length!')
}

if (length(unique(sheetnames)) != length(sheetnames)) {
    stop(paste('cannot use duplicated sheet names! ', sheetnames))
}

sheets <- vector('list', length(files))
names(sheets) <- sheetnames
for (i in seq(1, length(files))) { 
    df <- read.table(files[i], stringsAsFactors = FALSE, sep = "\t", quote = "", na.strings=c("", " ", "NA"), header=TRUE)
    if (any(rownames(df) != seq(1, nrow(df)))) {
        df$rowid <- rownames(df)
        df <- df[, c(ncol(df), seq(1, ncol(df) -1))]
    }
    sheets[[i]] <- df
}

write.xlsx(sheets, file=opt$outputfile)