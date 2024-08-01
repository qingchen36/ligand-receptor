#! /lustre/software/target/plenv/shims/perl -w
#  从Intact数据库中收集整理配受体互作数据
# Version: 1.0  2024.05.15 shengchen(shengchen@capitalbiotech.com)
############################################################################
use strict;
use warnings;
use Cwd;
use FindBin qw($Bin);
use lib "$Bin";
use File::Basename;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove); 
use Getopt::Long;
use XML::Simple;
#use XML::Validate;
use LWP;
use LWP::Simple;
use Data::Dumper;
########################################################
my $file1 = "Human_ligand_receptor_list.xls";#
my $file2 = "intact.txt";#
my $output = "ligand_receptor_IntAct_human.xls";#
my $taxonid = "9606";#
my $Help;
my $USAGE = <<"USAGE";
Name
   Gene2Gene_IntAct.pl
Options
  -f1      ligand_receptor_list
  -f2      IntAct PPI XML file
  -o       ligand_receptor_IntAct.txt.
  -s       organism ncbi taxonid, such as rat 10116
  -h      help
USAGE
GetOptions(
	'f1=s'    => \$file1,
	'f2=s'    => \$file2,
	's=s'    => \$taxonid,
	'o=s'    => \$output,
	'h'      => \$Help
);
if( !$file2 ) {die $USAGE;}
####################################################################

#----------------------   Program Start --------------------------#
# set up time
my $now;
my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime();
my $date = sprintf("%04d%02d%02d", $year + 1900, $mon +1, $day);
my $datett = sprintf("%04d%02d%02d%02d%02d",
                     $year + 1900, $mon + 1, $day, $hour, $min);
$now = localtime();
print " Start Time:\t$now\n";
###########################################
my %ligandDic;
my %receptorDic;
open File, "<$file1";
<File>;
while (my $tline = <File>){
	chomp $tline;
	$tline =~ s/[\r\n]//g;
	my @data = split(/\t/,$tline); ##
	if($data[1] eq "ligand"){
		$ligandDic{$data[0]}=1;
	}
	if($data[1] eq "receptor"){
		$receptorDic{$data[0]}=1;
	}
}
close File;

my %pairs;
open File, "<$file2";
<File>;
open OUT, ">$output";
print OUT "interaction_name\tpathway_name\tligand\treceptor\tevidence\tannotation\n";
my $i = 1;
while (my $tline = <File>){
	chomp $tline;
	$tline =~ s/^\s+//g; 
	$tline =~ s/[\r\n]//g;
	my @data = split(/\t/,$tline); ##
	my $taxidA="";
	my $taxidB="";
	if($data[9] =~/taxid\:(\d+)\(/){
		$taxidA=$1;
	}
	if($data[10] =~/taxid\:(\d+)\(/){
		$taxidB=$1;
	}
	#print $taxidA,"\n";
	#print $taxidB,"\n";
	if($taxidA eq $taxonid & $taxidB eq $taxonid){
		my $geneNameA="";
		my $geneNameB="";
		if($data[4] =~/uniprotkb\:(.*?)\(gene\ name\)/){
			$geneNameA=$1;
		}
		if($data[5] =~/uniprotkb\:(.*?)\(gene\ name\)/){
			$geneNameB=$1;
		}
		if(exists $ligandDic{$geneNameA} and exists $receptorDic{$geneNameB}){
			if(!exists $pairs{"${geneNameA}_${geneNameB}"}){
				print OUT "${geneNameA}_${geneNameB}\t\t$geneNameA\t$geneNameB\tIntAct\t\n";
				$pairs{"${geneNameA}_${geneNameB}"} = 1;
			}
		}
		if(exists $ligandDic{$geneNameB} and exists $receptorDic{$geneNameA}){
			if(!exists $pairs{"${geneNameB}_${geneNameA}"}){
				print OUT "${geneNameB}_${geneNameA}\t\t$geneNameB\t$geneNameA\tIntAct\t\n";
				$pairs{"${geneNameB}_${geneNameA}"} = 1;
			}
		}
	}
	$i = $i + 1;
	if($i % 100000 ==0){
		print $i,"\n";
	}
}
close(File);
close(OUT);


###########################################

select STDOUT;
($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime();
$date = sprintf("%04d%02d%02d", $year + 1900, $mon +1, $day);
$datett = sprintf("%04d%02d%02d%02d%02d",
                     $year + 1900, $mon + 1, $day, $hour, $min);
$now = localtime();
print "Programe End Time:\t$now\n";
