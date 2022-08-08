#! /usr/bin/env perl

# filtrare file/matrice in base alle colonne
# per ora assume che nell'header del file il primo elemento sia sempre da conservare (ex. snpid)!
# ricevere in input una lista degli header da tenere

$lista = $ARGV[0];
%lista = ();
$x=0;
open (LISTA, $lista);
while ($header = <LISTA>){
	chomp $header;
	$lista{$header} = $x;
	$x++;
}
close LISTA;

$file = $ARGV[1];
open (FILE, $file);
$primariga = <FILE>;
chomp $primariga;
close FILE;
@primariga = split (/\t/, $primariga);
# ignorare primo elemento(0)!
# salvare indici degli header da eliminare (non sono presenti nella lista di riferimento)
@eliminare = ();
$a=0;
$length = scalar(@primariga);
for($i=1; $i < $length; $i++){
	if (!(exists $lista{$primariga[$i]})){
		$eliminare[$a] = $i;
		$a++;
	}
}

open (FILE2, $file);
while ($riga = <FILE2>){
	chomp $riga;
	@riga = split (/\t/,$riga);
	$length2 = scalar(@eliminare);
	for ($b=0; $b < $length2; $b++){
			$nuovoindice = $eliminare[$b] - $b;
			splice (@riga,$nuovoindice,1);
	}
$newline = join("\t", @riga);
print "$newline\n";
}

close FILE2;
exit	
		
