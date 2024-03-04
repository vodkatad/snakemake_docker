#!/usr/bin/perl -w

use strict;
use warnings;

my $i=0;
my $j=0;
my $max_i=0;
my $max_j=0;
my @data=();
while(<>){
        chomp;
        my @F=split /\t/;
        for(@F){
                if($_=~/./){#per le matrici sparse
                        $data[$i][$j]=$_;
                }
                $j++;
        }
        if($j>$max_j){
                $max_j=$j;
        }
        $j=0;
        $i++;
}

$max_i=$i;

for($j=0;$j<$max_j;$j++){
        for($i=0;$i<$max_i;$i++){
                if(defined($data[$i][$j])){
                        print $data[$i][$j];
                }
                if($i==$max_i - 1){
                        print "\n";
                }else{
                        print "\t";
                }
        }
}

