#! perl -w
# 从固定的几个Pathway中提取配受体互作，并整理关系表
# 整理相应配受体表格
# 同时得到对应复合物的表格
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
use HTTP::Cookies;
use LWP;
use LWP::Simple;
use Data::Dumper;
########################################################
my $speices;###
my $geneinfo ="Rattus_norvegicus.gene_info";###
my $output1 = "ligand2receptor_KEGG.xls";#
my $output2 = "genetype_KEGG.xls";#
my $output3 = "complex_KEGG.xls";#
my $Help;
my $USAGE = <<"USAGE";
Name
   ligand2receptor_KEGG.pl
Options
  -s      speices such as rno, dme, gga.
  -g      input    geneinfo file.
  -o1     output1, ligand2receptor_KEGG.xls.
  -o2     output2, genetype_KEGG.xls.
  -o3     output3, complex_KEGG.xls.
  -h      help
USAGE
GetOptions(
	's=s'    => \$speices,
	'g=s'    => \$geneinfo,
	'o1=s'    => \$output1,
	'o2=s'    => \$output2,
	'o3=s'    => \$output3,
	'h'      => \$Help
);
if( !$speices ) {die $USAGE;}
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
##只分析特定的pathway，且只分析位于膜上的配受体互作；
my @Pathways;
push @Pathways,$speices."04012";
push @Pathways,$speices."04060";
push @Pathways,$speices."04080";
push @Pathways,$speices."04310";
push @Pathways,$speices."04340";
push @Pathways,$speices."04350";
push @Pathways,$speices."04370";
push @Pathways,$speices."04371";
push @Pathways,$speices."04512";
push @Pathways,$speices."04514";
push @Pathways,$speices."04910";



##2.KEGG xml文件中的GeneName不全，所以只能读取Geneinfo文件，获取Symbol
my %genedic;
open File, "<$geneinfo";
<File>;
while (my $tline = <File>){
	chomp $tline;
	$tline =~ s/[\r\n]//g;
	my @data = split(/\t/,$tline); ##
	$genedic{$data[1]}=$data[2];
	#print $data[1],"\t",$data[2],"\n";
}
close File;

open File1, ">$output1";
open File2, ">$output2";
open File3, ">$output3";
print File1 "interaction_name\tpathway_name\tligand\treceptor\tevidence\tannotation\n";
print File2 "Symbol\ttype\tEntrezGeneID\n";
print File3 "complex\tsubunit_1\tsubunit_2\tsubunit_3\tsubunit_4\tsubunit_5\n";
foreach my $pathway (@Pathways){
	my $tempURL = "https://rest.kegg.jp/get/".$pathway."/kgml";
	print $tempURL,"\n";
	my $tempfile= $pathway.".kgml";
	while(!-e $tempfile){
		`wget $tempURL -O $tempfile`;
		print "download end\n";
		sleep(30);
	}
	my $pathwayxml="";
	open File,"<$tempfile";
	<File>;
	<File>;
	<File>;#前三行固定格式不要
	while (my $tline = <File>){
		chomp $tline;
	    $pathwayxml = $pathwayxml."\n".$tline;
	}
	close(File);
	my $doc = XMLin($pathwayxml, KeyAttr => "id");
	if($pathway =~/04060/){
		#next;
		my $annotation="Secreted Signaling";
		if(ref($doc->{relation}) eq 'ARRAY'){
			foreach my $ele (@{$doc->{relation}}){
				if($ele->{type} eq "PPrel"){
					my $nodes1 = $ele->{entry1};
					my $nodes2 = $ele->{entry2};
					writeInteaction($doc,"$nodes1","$nodes2","","$pathway",$annotation);
				}
			}
		}
	}
	if($pathway =~/04080/){
		#next;
		my $annotation="Secreted Signaling";
		if(ref($doc->{relation}) eq 'ARRAY'){
			foreach my $ele (@{$doc->{relation}}){
				if($ele->{type} eq "PPrel"){
					my $nodes1 = $ele->{entry1};
					my $nodes2 = $ele->{entry2};
					writeInteaction($doc,"$nodes1","$nodes2","","$pathway",$annotation);
				}
			}
		}
	}
	
	if($pathway =~/04512/){
		#next;
		#getNodesAttr($doc, "242");#242节点有4个亚基构成
		my $annotation="ECM-Receptor";
		if(ref($doc->{relation}) eq 'ARRAY'){
			foreach my $ele (@{$doc->{relation}}){
				if($ele->{type} eq "PPrel"){
					my $nodes1 = $ele->{entry1};
					my $nodes2 = $ele->{entry2};
					writeInteaction($doc,"$nodes1","$nodes2","","$pathway",$annotation);
				}
			}
		}
	}
	if($pathway =~/04514/){
		#next;
		##免疫蛋白亚型特别多
		my $annotation="Cell-Cell Contact";
		if(ref($doc->{relation}) eq 'ARRAY'){
			foreach my $ele (@{$doc->{relation}}){
				if($ele->{type} eq "PPrel"){
					my $nodes1 = $ele->{entry1};
					my $nodes2 = $ele->{entry2};
					writeInteaction($doc,"$nodes1","$nodes2","","$pathway",$annotation);
				}
			}
		}
	}
	##多个物种比较后，图上的实体为固定编号
	if($pathway =~/04012$/){##ERBB信号通路
		#next;
		my $annotation="Secreted Signaling";
		if(ref($doc->{relation}) eq 'ARRAY'){
			foreach my $ele (@{$doc->{relation}}){
				if($ele->{type} eq "PPrel"){
					my $nodes1 = $ele->{entry1};
					my $nodes2 = $ele->{entry2};
					if($nodes2 eq "177" or $nodes2 eq "178" or $nodes2 eq "179" or $nodes2 eq "180" or $nodes2 eq "181" or $nodes2 eq "182"){
						writeInteaction($doc,"$nodes1","$nodes2","ERBB","$pathway",$annotation);
					}
				}
			}
		}
	}
	if($pathway =~/04310$/){##WNT信号通路
		#next;
		writeInteaction($doc,"187","186","","$pathway","Secreted Signaling");
		writeInteaction($doc,"88","84","WNT","$pathway","Secreted Signaling");
		writeInteaction($doc,"88","85","WNT","$pathway","Secreted Signaling");
		writeInteaction($doc,"38","36","WNT","$pathway","Secreted Signaling");
		writeInteaction($doc,"27","26","WNT","$pathway","Secreted Signaling");
	}
	if($pathway =~/04350$/){##TGFB信号通路
		#next;
		writeInteaction($doc,"170","175","BMP","$pathway","Secreted Signaling");
		writeInteaction($doc,"176","175","ACTIVIN","$pathway","Secreted Signaling");
		writeInteaction($doc,"236","220","","$pathway","Secreted Signaling");
		writeInteaction($doc,"179","184","BMP","$pathway","Secreted Signaling");
		writeInteaction($doc,"57","55","BMP","$pathway","Secreted Signaling");
		writeInteaction($doc,"51","49","TGFB","$pathway","Secreted Signaling");
		writeInteaction($doc,"34","32","ACTIVIN","$pathway","Secreted Signaling");
		writeInteaction($doc,"20","17","NODAL","$pathway","Secreted Signaling");
	}
	if($pathway =~/04340$/){##Hedgehog信号通路控制细胞命运、增殖与分化
		#next;
		writeInteaction($doc,"86","78","HH","$pathway","Secreted Signaling");
		writeInteaction($doc,"86","79","HH","$pathway","Secreted Signaling");
	}
	if($pathway =~/04370$/){##VEGF信号通路
		#next;
		writeInteaction($doc,"32","12","VEGF","$pathway","Secreted Signaling");
	}
	if($pathway =~/04371$/){##APELIN信号通路
		#next;
		writeInteaction($doc,"205","10","APELIN","$pathway","Secreted Signaling");
	}
	if($pathway =~/04910$/){##胰岛素信号通路
		#next;
		writeInteaction($doc,"22","42","INSULIN","$pathway","Secreted Signaling");
	}	
}
close File1;
close File2;
close File3;


###########################################
sub getNodesAttr{##
	my ($xmlhash, $nodearray) = @_;##没用数组引用
	my @namesArray;
	my $type= $xmlhash->{entry}->{$nodearray}->{type};
	if($type eq "gene"){
		my $tempname = $xmlhash->{entry}->{$nodearray}->{name};
		my @names = split(/\s+/,$tempname);
		foreach my $onename (@names){
			my $tempcs = (split(/:/,$onename))[1];
			push @namesArray, $tempcs;
			print $tempcs,"\n";
		}
		return @namesArray;
	}
	if($type eq "group"){##此节点为复合物
		my $count=keys $xmlhash->{entry}->{$nodearray}->{component};
		print $count ,"\n";
		my %groupdic;
		my $i = 0;
		foreach my $id (keys $xmlhash->{entry}->{$nodearray}->{component}){
			#print $id,"\n";
			if($xmlhash->{entry}->{$id}->{type} ne "gene"){
				next;
			}
			my @namesArray= getNodesAttr($xmlhash, $id);
			foreach my $name (@namesArray){
				$groupdic{$i}{$name}="";
				print $name,"\n";
			}
			$i= $i + 1;
		}
		$count = $i;
		my @array1 = keys($groupdic{0});
		for($i=1;$i<$count;$i++){
			my @medArray;
			my @temp = keys($groupdic{$i});
			foreach my $ele1(@array1){
				foreach my $ele2(@temp){
					push @medArray, "$ele1"."_"."$ele2";
				}
			}
			@array1 = @medArray;
		}
		foreach my $ele1(@array1){
			print $ele1,"\n";
		}
		return @array1;
	}
	return @namesArray;
}

sub writeInteaction{
	my ($xmlhash, $entry1, $entry2, $pathname, $pathway, $annotation) = @_;##没用数组引用
	my @ligands = getNodesAttr($xmlhash, "$entry1");
	my @receptors = getNodesAttr($xmlhash, "$entry2");
	my @resligands;
	my @resreceptors;
	foreach my $ligand (@ligands){
		if($ligand !~ /_/){##不是复合物
			my $symbol="";
			if(exists $genedic{$ligand}){
				$symbol = $genedic{$ligand};
			}else{
				$symbol = $ligand;
			}
			print File2 "$symbol\tligand\t$ligand\n";
			push @resligands,$symbol;
			
		}else{##是复合物
			my @genes = split(/_/,$ligand);
			my @symbols;
			foreach my $gene (@genes){
				if(exists $genedic{$gene}){
					print File2 "$genedic{$gene}\tligand\t$gene\n";
					push @symbols, $genedic{$gene};
				}else{
					print File2 "$gene\tligand\t$gene\n";
					push @symbols, $gene;
				}
			}
			print File3 join("_",@symbols),"\t",join("\t",@symbols),"\n";
			push @resligands,join("_",@symbols);
		}
	}
	foreach my $receptor (@receptors){
		if($receptor !~ /_/){
			my $symbol="";
			if(exists $genedic{$receptor}){
				$symbol= $genedic{$receptor};
			}else{
				$symbol= $receptor;
			}
			print File2 "$symbol\treceptor\t$receptor\n";
			push @resreceptors, $symbol;
		}else{
			my @genes = split(/_/,$receptor);
			my @symbols;
			foreach my $gene (@genes){
				if(exists $genedic{$gene}){
					print File2 "$genedic{$gene}\treceptor\t$gene\n";
					push @symbols, $genedic{$gene};
				}else{
					print File2 "$gene\treceptor\t$gene\n";
					push @symbols, $gene;
				}
			}
			print File3 join("_",@symbols),"\t",join("\t",@symbols),"\n";
			push @resreceptors, join("_",@symbols);
		}
	}
	foreach my $ligand (@resligands){
		foreach my $receptor (@resreceptors){
			print File1 "${ligand}_${receptor}\t$pathname\t$ligand\t$receptor\tKEGG:$pathway\t$annotation\n";
		}
	}
}

###########################################

select STDOUT;
($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime();
$date = sprintf("%04d%02d%02d", $year + 1900, $mon +1, $day);
$datett = sprintf("%04d%02d%02d%02d%02d",
                     $year + 1900, $mon + 1, $day, $hour, $min);
$now = localtime();
print "Programe End Time:\t$now\n";
