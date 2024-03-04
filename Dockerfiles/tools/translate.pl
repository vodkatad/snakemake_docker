#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
$,="\t";


my $usage = "$0 [-i|ignore-missing-columns] [-s|split_separator] [-w|split_each_word] [-a|append] [-d [-g glue] [-j]] [-m glue] [-v|allow_missing_translations [-e VALUE ]] [-k|kill] [-n|invert-dictionary] [-f|key_field N] [-p|pass REGEXP] DICTIONARY 1 2 3 < tab_file\
	-d	allow duplicated keys in DICTIONARY
	-g	indicate the separator for multiple values of the same key in output
	-m	if the dictionary file has more than 2 columns, the transaltion is multi column and the separator is glue
	-k	kill untranslated rows
	-b FILE print the killed rows of STDIN in FILE
	-e	use VALUE as translation when a key si not present in dictionary
	-j	join lyke out (when there duplicated translation for the same key generate multiple rows)
	-p	ignore input rows matching REGEXP, use -p '^>' to skip the translation of fasta headers
	-c	ignore case in the comparison with the dictionary
	-w	translate each word
	-r	put the added columns at the end of rows
	-z	allow empty dictionary
";

my $key_field = undef;
my $ignore_missing_columns=0;
my $append=0;
my $duplicated_keys=0;
my $glue=undef;
my $split_separator="\t";
my $split_each_word=0;
my $kill=0;
my $print_killed=undef;
my $invert_dictionary=0;
my $allow_missing_translations=0;
my $join_lyke_out=0;
my $empty_key = undef;
my $multi_column_separator = undef;
my $skip_input_regexp = undef;
my $ignore_case=0;
my $append_at_the_R_of_rows=0;
my $allow_empty_dictionary=0;
GetOptions (
	'f|key_field=i' => \$key_field,
	'i|ignore-missing-columns' => \$ignore_missing_columns,
	'n|invert-dictionary' => \$invert_dictionary,
	'a|append' => \$append,
	'd|duplicated_keys' => \$duplicated_keys,
	's|split_separator=s' => \$split_separator,
	'e|empty=s' => \$empty_key,
	'w|split_each_word' => \$split_each_word,
	'g|glue=s' => \$glue,
	'j|join' => \$join_lyke_out,
	'k|kill' => \$kill,
	'b|print_killed=s' => \$print_killed,
	'v|allow_missing_translations' => \$allow_missing_translations,
	'm|multi_column_separator=s' => \$multi_column_separator,
	'p|pass=s' => \$skip_input_regexp,
	'c|case' => \$ignore_case,
	'r|append_at_the_R_of_rows' => \$append_at_the_R_of_rows,
	'z|allow_empty_dictionary' => \$allow_empty_dictionary
) or die($usage);

$SIG{__WARN__} = sub {die @_};

die("-g option meaningless without -d option") if defined $glue  and !$duplicated_keys;

$glue = ';' if not defined $glue;

#$allow_missing_translations = 1 if $kill;

my $filename = shift @ARGV;

open FH,$filename or die("Can't open file ($filename)");
open KILLED,">$print_killed" or die("Can't open file ($print_killed)") if $print_killed;

my @columns=@ARGV;

die("no column indication\n$usage") if scalar(@columns) == 0 and !$split_each_word; 

for(@columns){
	die("invalid columns ($_)") if !m/^\d+$/;
	$_--;
}

die("-w option incompatible with column indication") if($split_each_word and scalar(@columns) > 0);
die("-j option require -d and -a options and conflicts with -w") if $join_lyke_out and ($split_each_word or (!$duplicated_keys or !$append));
die("-w option conflicts with -k") if ($split_each_word and $kill);
die("-b|print_killed option require -k") if ($print_killed and not $kill);
die("-e meaningless without -v") if defined($empty_key) and not $allow_missing_translations;
die("-n meaningless with -f") if defined($key_field) and $invert_dictionary;
die("-f require a parameter >=1") if defined($key_field) and $key_field < 1;
die("-r require -a") if $append_at_the_R_of_rows and not $append;
die("-r not compatible with -j") if $append_at_the_R_of_rows and $join_lyke_out;

$empty_key  =~ s/\\t/\t/g if defined($empty_key);
$key_field-- if defined($key_field);
$key_field = 0 if !defined($key_field);




my $columns_added_by_translation = undef;
my %hash=();
my $empty_map = 1;
while(<FH>){
	$empty_map = 0;
	chomp;
	
	my $k = undef;
	my $v = undef;
	if($key_field == 0){
		die("At least 2 columns required in dictionary file (".$filename.")") if !m/\t/;
		m/([^\t]+)[\t](.*)/;
		if(!$invert_dictionary){
			$k = $1;
			$v = $2;
		}else{
			$v = $1;
			$k = $2;
		}
		if(defined($multi_column_separator)){
			$v =~ s/\t/$multi_column_separator/g;
		}
		die("Malformed input in dictionary ($_)") if not defined $v;
		if(not defined $columns_added_by_translation){
			my @F=split(/\t/, $v);
			$columns_added_by_translation = scalar(@F);
		}
	}else{
		my @F = split /\t/;
		$k = splice @F, $key_field, 1;
		#my $separator = "\t" if not defined($multi_column_separator); ## seems to my that this row is useless
		$v = join( defined $multi_column_separator ? $multi_column_separator : "\t", @F);
		if(defined($columns_added_by_translation)){
			warn "The dictrionary file has rows with differet number of fields." if scalar @F != $columns_added_by_translation;
		}
		$columns_added_by_translation = scalar(@F) if not defined $columns_added_by_translation;

	}

	$k = uc($k) if $ignore_case;
	if(not defined($k)){
		die("Malformed input in dictionary ($_)");
	}

	if(defined $hash{$k}){
		if(!$duplicated_keys){
			die("Duplicated key in dictionary ($k)");
		}else{
			if($join_lyke_out){
				if(ref($hash{$k}) eq 'ARRAY'){
					push(@{$hash{$k}},$v);
				}else{
					my @tmp=($hash{$k},$v);
					$hash{$k}=\@tmp;
				}
			}else{
				$hash{$k}.=$glue.$v;
			}
		}
	}else{
		$hash{$k}=$v;
	}
}

if($empty_map){
	if($allow_empty_dictionary){
		$columns_added_by_translation=1
	}else{
		if($kill){
			#return(0); # will raise a broken pipe
			while(<STDIN>){
				#consume input
			}
			exit(0);
		}
		die("WARNING: The dictionary is empty");
	}
}

if($columns_added_by_translation > 1){
	$columns_added_by_translation--;
	$empty_key = "\t" x $columns_added_by_translation if $allow_missing_translations and not defined $empty_key;
}else{
	$empty_key = "" if not defined $empty_key;
}



my $warning=0;

while(<STDIN>){
	
	if(defined $skip_input_regexp and m/$skip_input_regexp/){
		print;
		next;
	}
	
	if(!$split_each_word){
		chomp;
		my @F = split /$split_separator/;
		my @G=@F;
		my $print=1;
		for(@columns){
			$a=$F[$_];
			if(defined($a)){
				my ($val, $translated)=@{&translate($a)};
				$print = 0 if (!$translated and $kill);
				if( not $join_lyke_out){
					if(not $append_at_the_R_of_rows){
						$F[$_] = $val;
					}else{
						push(@F,$val);
					}
				}else{ 
					#$append_at_the_R_of_rows not allowed in -j mode
					my @tmp= ($F[$_],$val); 
					$F[$_] = \@tmp; #nella colonna da tradurre metto una ref ad un array col valore iniziale
							#e quello tradotto (che sara` quello iniziale tab traduzione in caso di -a
							# e non join_lyke_out e solo la traduzione negli altri casi)
				}
			}else{
				die("column $_+1 not defined in standard input (-i to ignore)") if !$ignore_missing_columns;
				if(!$warning){
					print STDERR "WARNING: $0, column not defined\n";
					$warning=1;
				}
			}
		}
		if($print){
			if(!$join_lyke_out){
				print @F;
				print "\n";
			}else{
				die("only one column allowed when join lyke output enabled") if scalar(@columns) > 1;
				my $c = $columns[0];
				my $a = $G[$c];
				my $val=$F[$c]->[1];
				if(ref($val) ne 'ARRAY'){
					$F[$c] = $a .$split_separator.$val;
					print @F;
					print "\n";
				}else{
					for(@{$val}){
						$F[$c] = $a .$split_separator.$_;
						print @F;
						print "\n";
					}
				}
			}
		}else{
			if($print_killed){
				#print KILLED @F;
				#print KILLED "\n";
				if(!$join_lyke_out){
					print KILLED @F;
					print KILLED "\n";
				}else{ 
					die("only one column allowed when join lyke output enabled") if scalar(@columns) > 1;
					my $c = $columns[0];
					my $a = $G[$c];
					my $val=$F[$c]->[1];
					if(ref($val) ne 'ARRAY'){
						$F[$c] = $val;
						print KILLED @F;
						print KILLED "\n";
					}else{
						for(@{$val}){
							$F[$c] = $split_separator.$_;
							print KILLED @F;
							print KILLED "\n";
						}
					}
				}

			}
		}
	}else{
		s/^([\W]+)//;
		print $1 if $1;
		while(s/([^\W]+)([\W]+)//){
			my ($val, $translated)=@{&translate($1)};
			print $val;
			print $2;
		}
	}
}

sub translate
{
	my $a=shift;
	my $b=undef;
	if($ignore_case){
		$b=$hash{uc($a)};
	}else{
		$b=$hash{$a};
	}
	if(!defined($b)){
		if($allow_missing_translations){
			if(defined($empty_key)){
				$b=$empty_key;
			}
		}elsif(not $kill){
			warn "missing translation for key ($a)\n" if !$allow_missing_translations;
		}
	}
	if(defined($b)){
		if($append and not $join_lyke_out and not $append_at_the_R_of_rows){
			$a .= "\t$b";
		}else{
			$a = $b;
		}
	}
	
	my @tmp=($a, defined($b));
	return \@tmp;
}
