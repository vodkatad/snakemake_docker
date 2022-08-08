#!/usr/bin/env python3

#./count_bam_many.py /media/data/New\ Volume/BAM_Files_RNA/Human_Pipeline/bam_files/PN0039B-HNC0086PRH00Aligned.sortedByCoord.out.bam  <(grep HNC0039PRH hn_fp_coords.tsv  | grep -v NA)

# this scripts checks for consistencies between Eugenia's fp info:
#data@rotpunkt:~/work/stash/hn$ head fingerprint/hn_fp_coords.tsv 
#chr10	127402700	G	rs11017876_HNC0012PRX0A02001TUMD06000
#chr8	70100576	A	rs1106334_HNC0012PRX0A02001TUMD06000
# and a sample assignment map:
# id is
# HNC0034PRH00	HNC0125PRX0A
# looking at bam alignments

# for each snp in Eugenia's files it counts the number of 'wrong' reads, i.e reads with a nucleotide that is not in the genotype reported by the fp info
# it also add a column with 'ok' (or 'neutral' or 'homo'): for het SNPs  if both the alleles have more than 1 (default, but can be given as an argument) supporting reads
# not true TODO FIXME 
# other argument: starting dir where to look for alignments
from sys import argv
import pysam
import re
import glob
import os

# args:
# fp file
# samples map
# starting dir
if __name__ == "__main__":

    if len(argv) != 4:
        print("I need 4 arguments, fp file, samples map and bam dir, only %d where given" % len(argv))
        exit(1)

    fp_file = argv[1]
    samples_map = argv[2]
    starting_dir = argv[3]

    whoiswho = {}
    with open(samples_map, 'r') as sm:
        for l in sm.readlines():
            l = l.rstrip('\n')
            f = l.split("\t")
            if f[0] not in whoiswho.keys():
                whoiswho[f[0]] = f[1]
            else:
                print('duplicate row for identity %s' % f[0])
                exit(1)

    map_work = {}
    model = ""
    sample_bam = ""
    snps = []
    with open(fp_file,'r') as muts:
        for l in muts.readlines():
            l = l.rstrip('\n')
            f = l.split("\t")
            m = (f[0],int(f[1]),f[2],f[3]) # chr, coord 1 based, genotype, rs_sample
            sample_fp = m[3].split('_')[1]
            sample_fp = sample_fp[0:12]
            if model != "" and model != sample_fp: # new model
                map_work[model] = (sample_bam, snps)
                sample_bam = ""
                error = 0
                ok = ""
                snps = []
            model = sample_fp
            if sample_bam == "":    
                if sample_fp in whoiswho.keys():
                    sample_bam = whoiswho[sample_fp]
                else:   
                    print('missing samplemap for %s' % sample_fp)
                    exit(1)
                #bamf = glob.glob(os.path.join(starting_dir, '*'+sample_bam+'_*.bam'))
                bamf = glob.glob(os.path.join(starting_dir, '*'+sample_bam+'*.bam'))
                #bamf = 'p'
                if len(bamf) != 1:
                    print('more than one or missing bam for %s %d' % (sample_fp, len(bamf)))
                    print(bamf)
                    exit(1)
                sample_bam = bamf[0]
            snps.append(m)
        if model != "": # new model
            map_work[model] = (sample_bam, snps)
            
        for model in map_work.keys():
            #print(map_work[model])
            #print("#working on %s" % model)
            #print(map_work[model][1])
            #continue
            bamf = map_work[model][0]
            samfile = pysam.AlignmentFile(bamf, "rb")
            errors = 0
            has_ok = 0
            n_snps = 0
            n_covered_snps = 0
            for m in map_work[model][1]:
                n_snps += 1
                # for each read that overlap the postion given
                haplotypes =  list(m[2])
                ok = 0
                # the iterator given by pileup will always be of length 1
                for pileupcolumn in samfile.pileup(m[0], m[1]-1, m[1], stepper='all', truncate=True, max_depth=10000):
                   #print("\ncoverage at base %s = %s" % (pileupcolumn.pos, pileupcolumn.n))
                   counts = dict(A=0, C=0, G=0, T=0)
                   for read_base in pileupcolumn.pileups:
                       # .is_del -> the base is a deletion?
                       # .is_refskip -> the base is a N in the CIGAR string ?
                       if not read_base.is_del and not read_base.is_refskip:
                           counts[read_base.alignment.query_sequence[read_base.query_position]] += 1
                   if sum(counts.values()):
                       print(">{}_{} A {} T {} C {} G {}".format(m[3], m[2], counts['A'], counts['T'], counts['C'], counts['G']))
                       n_covered_snps += 1
                       for base in counts.keys():
                           if counts[base] != 0:
                                if base not in haplotypes:
                                    errors += 1
                                elif counts[base] > 1:
                                    ok += 1
                if ok > 1:
                    has_ok += 1
                #print("%s\t%d\t%s\t%s\t%d\t%d" % (m[0],m[1],m[2],m[3], errors, ok))

            print("%s\t%d\t%d\t%d\t%d" % (model,n_snps,n_covered_snps,errors,has_ok))
            samfile.close()

