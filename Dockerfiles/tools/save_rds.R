## input for H<->M transaltor

library("biomaRt")

human <- useMart("ensembl", dataset = "hsapiens_gene_ensembl")
mouse <- useMart("ensembl", dataset = "mmusculus_gene_ensembl")
saveRDS(human, file = "human.Rds")
saveRDS(mouse, file = "mouse.Rds")