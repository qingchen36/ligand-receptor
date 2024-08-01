#!/usr/bin/perl -w
use strict;
use warnings;
use autodie;
use FileHandle;
use File::Spec;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(basename dirname);
my $programe_dir=basename($0);
use FindBin qw($Bin $Script);
use Cwd;
use POSIX qw(strftime);
use List::Util qw(sum max min);
use List::MoreUtils qw(uniq);
my $version=1.0;

#######################################################################################
# ------------------------------------------------------------------
# GetOptions, Check format, Output info.
# ------------------------------------------------------------------
my ($complex,$interact,$ligand);
GetOptions(
				"help|?" =>\&USAGE,
				"f1|file1=s" => \$complex,
				"f2|file2=s" => \$interact,
				"o|outfile=s" => \$ligand
				) or &USAGE;
&USAGE unless ($complex and $interact) ;

$complex=&ABSOLUTE_DIR($complex);
$interact=&ABSOLUTE_DIR($interact);

################################ Time_begin ############################################
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\n$programe_dir Start Time :[$Time_Start]\n\n";

################################ Program ############################################
###### id type

my %complexDic;
open IN,$complex or die "$!";
<IN>; #head
while (<IN>) {
	chomp;
	$_=~s/\r//;
	my @data = split(/,/,$_); ##csv format
	my $length=@data;
	$data[0] =~ s/\"//g;
	for (my $i = 1; $i < $length; $i++) {
		$data[$i] =~ s/\"//g;
		if($data[$i] ne ""){
			$complexDic{$data[0]}{$data[$i]}=1;
		}
	}
}
close IN;

my %ligandDic;
my %receptorDic;
open IN,$interact or die "$!";
<IN>; #head
while (<IN>) {
	chomp;
	$_=~s/\r//;
	$_=~ s/\"//g;
	my @data = split(/,/,$_); ##csv format
	if(exists $complexDic{$data[2]}){
		foreach my $key (keys $complexDic{$data[2]}){
			if(!exists $ligandDic{$key}){
				$ligandDic{$key} = 1;
			}
		}
	}else{
		if(!exists $ligandDic{$data[2]}){
				$ligandDic{$data[2]} = 1;
			}
	}
	if(exists $complexDic{$data[3]}){
		foreach my $key (keys $complexDic{$data[3]}){
			if(!exists $receptorDic{$key}){
				$receptorDic{$key} = 1;
			}
		}
	}else{
		if(!exists $receptorDic{$data[3]}){
				$receptorDic{$data[3]} = 1;
			}
	}
}
close IN;

open File, ">$ligand";
print File "symbol\ttype\n";
foreach my $key (keys %ligandDic){
	print File "$key\tligand\n";
}
foreach my $key (keys %receptorDic){
	print File "$key\treceptor\n";
}
close File;

################################ Time_end ############################################
my $Time_End = sub_format_datetime(localtime(time()));
print "\n$programe_dir End Time :[$Time_End]\n\n";

################################ Time_cost ############################################
#&Runtime($BEGIN_TIME);

##########################################################################################################

############### Subs ###############


##########
sub ABSOLUTE_DIR
{ #$pavfile=&ABSOLUTE_DIR($pavfile);
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	
	if(-f $in)
	{
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}
	elsif(-d $in)
	{
		chdir $in;$return=`pwd`;chomp $return;
	}
	else
	{
		warn "Warning just for file and dir in [sub ABSOLUTE_DIR]\n";
		exit;
	}
	
	chdir $cur_dir;
	return $return;
}

##########
sub sub_format_datetime {#Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

##########
sub Runtime
{ # &Runtime($BEGIN);
	my ($t1)=@_;
	my $t=time()-$t1;
	print "Total elapsed time: ${t}s\n";
}

########## perl程序参数使用说明
sub USAGE {
	my $usage=<<"USAGE";
	Version: $version;
	Program: $0;
	Description: The program is to get ligand repetor genelist from CellChatDB;
		-f1 | -file1		complex.csv		[must be given];
		-f2 | -file2		interaction.csv		[must be given];
		-o  | -outfile		ligand_and_receptor_symbol_list		[must be given];
		-h  | -help;

USAGE
	print $usage;
	exit;
}