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
my $file1 ;#
my $file2 = "Reactome/reactome.all_species.interactions.tab-delimited.txt.xls";#
my $output = "ligand_receptor_Reactome_Rat.xls";#
my $taxonid = "SSC";#
my $Help;
my $USAGE = <<"USAGE";
Name
   Gene2Gene_IntAct.pl
Options
  -f1      ligand_receptor_list
  -f2      reactome.all_species.interactions.tab-delimited.txt.xls
  -o       ligand_receptor_Reactome.txt.
  -s       organism HSA, RNO, MMU, SSC
  -h      help
USAGE
GetOptions(
	'f1=s'    => \$file1,
	'f2=s'    => \$file2,
	's=s'    => \$taxonid,
	'o=s'    => \$output,
	'h'      => \$Help
);
if( !$file1 ) {die $USAGE;}
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
		if($data[3] ne ""){
			$ligandDic{$data[3]}=$data[0];
		}

	}
	if($data[1] eq "receptor"){
		if($data[3] ne ""){
			$receptorDic{$data[3]}=$data[0];
		}
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
	#$tline =~ s/^\s+//g; 
	$tline =~ s/[\r\n]//g;
	my @data = split(/\t/,$tline); ##
	if($data[7] =~/reactome\:R-$taxonid/){
		my $gene1 = ""; 
		my $gene2 = "";
		print $data[7],"\n";
		if($data[1] =~/ENSEMBL\:(ENS...G\d+)/){
			
			$gene1 = $1;
		}
		if($data[4] =~/ENSEMBL\:(ENS...G\d+)/){
			$gene2 = $1;
		}
		print $gene1,"\n";
		print $gene2,"\n";
		if(exists $ligandDic{$gene1} and exists $receptorDic{$gene2}){
			if(!exists $pairs{"${gene1}_${gene2}"}){
				print OUT "$ligandDic{$gene1}_$receptorDic{$gene2}\t\t$ligandDic{$gene1}\t$receptorDic{$gene2}\t$data[7]\t\n";
				$pairs{"${gene1}_${gene2}"} = 1;
			}
		}
		if(exists $ligandDic{$gene2} and exists $receptorDic{$gene1}){
			if(!exists $pairs{"${gene2}_${gene1}"}){
				print OUT "$ligandDic{$gene2}_$receptorDic{$gene1}\t\t$ligandDic{$gene2}\t$receptorDic{$gene1}\t$data[7]\t\n";
				$pairs{"${gene2}_${gene1}"} = 1;
			}
		}
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
