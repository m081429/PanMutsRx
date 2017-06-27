#! /usr/bin/env bash
#trap "exit 100; exit" ERR
####################
## Script Options ##
####################

#set -x

usage ()
{
cat << EOF
######################################################################
##      script to install tools
## Script Options:
##      -r      <ref file directory>      -       (REQUIRED)      required path to directory for ref files download
##      -t      <tool install config file>      -       (REQUIRED)      required path to tool info config file
##      -h      - Display this usage/help text (No arg)
#############################################################################
EOF
exit
}
echo "Options specified: $@"

while getopts "r:t:h" OPTION; do
    case $OPTION in
        r) reffile_dir=$OPTARG ;;
		t) toolinfo_file=$OPTARG ;;
		h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$reffile_dir" ] || [ -z "$toolinfo_file" ]; then
    usage
fi

echo "******************"
echo "Ref file Directory: $reffile_dir"
echo "Tool info File: $toolinfo_file"
echo "******************"

echo "checking tool info tools"
source $toolinfo_file

#Toolinfo file
if [[ -w $toolinfo_file ]]
then
	echo "Tool info file $toolinfo_file is found"	
else
    echo "Tool info file $toolinfo_file is not found"
	exit
fi
#FTP links
LINK_GTF='ftp://ftp.ensembl.org/pub/release-75/gtf/homo_sapiens/Homo_sapiens.GRCh37.75.gtf.gz'
LINK_STAR_FUSION='https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/GRCh37_gencode_v19_CTAT_lib_July272016.tar.gz'
LINK_1KG='ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz'
LINK_KG_MILLS='ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz'
LINK_DB_SNP='ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/dbsnp_138.hg19.excluding_sites_after_129.vcf.gz'
LINK_GENCODE='ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz'

#testing links
mkdir -p $reffile_dir

links_not_worked=" "

wget --spider -v  $LINK_GTF > $reffile_dir/testlink 2>&1
testp=`grep -c "exists." $reffile_dir/testlink`
if [ $testp -eq 0 ]
	then
	echo "GTF ftp LINK $LINK_GTF expired. Please replace the old link with new one on the line 55 of this script"
	links_not_worked=$links_not_worked" GTF"
fi
rm $reffile_dir/testlink

wget --spider -v  $LINK_STAR_FUSION > $reffile_dir/testlink 2>&1
testp=`grep -c "exists." $reffile_dir/testlink`
if [ $testp -eq 0 ]
	then
	echo "STAR_FUSION ftp LINK $LINK_STAR_FUSION expired. Please replace the old link with new one on the line 56 of this script"
	links_not_worked=$links_not_worked" STAR_FUSION"
fi
rm $reffile_dir/testlink

wget --spider -v  $LINK_1KG > $reffile_dir/testlink 2>&1
testp=`grep -c "exists." $reffile_dir/testlink`
if [ $testp -eq 0 ]
	then
	echo "1KG ftp LINK $LINK_1KG expired. Please replace the old link with new one on the line 57 of this script"
	links_not_worked=$links_not_worked" 1KG"
fi
rm $reffile_dir/testlink

wget --spider -v  $LINK_KG_MILLS > $reffile_dir/testlink 2>&1
testp=`grep -c "exists." $reffile_dir/testlink`
if [ $testp -eq 0 ]
	then
	echo "KG_MILLS ftp LINK $LINK_KG_MILLS expired. Please replace the old link with new one on the line 58 of this script"
	links_not_worked=$links_not_worked" KG_MILLS"
fi
rm $reffile_dir/testlink

wget --spider -v  $LINK_DB_SNP > $reffile_dir/testlink 2>&1
testp=`grep -c "exists." $reffile_dir/testlink`
if [ $testp -eq 0 ]
	then
	echo "DB_SNP ftp LINK $LINK_DB_SNP expired. Please replace the old link with new one on the line 59 of this script"
	links_not_worked=$links_not_worked" DB_SNP"
fi
rm $reffile_dir/testlink

wget --spider -v  $LINK_GENCODE > $reffile_dir/testlink 2>&1
testp=`grep -c "exists." $reffile_dir/testlink`
if [ $testp -eq 0 ]
	then
	echo "GENCODE ftp LINK $LINK_GENCODE expired. Please replace the old link with new one on the line 60 of this script"
	links_not_worked=$links_not_worked" GENCODE"
fi
rm $reffile_dir/testlink

if [[ $links_not_worked == " " ]]; then   
  echo "All links are properly working" 
else
  echo "All links are  not working properly" $links_not_worked
  exit 1
fi

#GTF file
echo "downloading gtf file from encode"

cd $reffile_dir
#wget ftp://ftp.ensembl.org/pub/release-75/gtf/homo_sapiens/Homo_sapiens.GRCh37.75.gtf.gz
wget $LINK_GTF
FILE="Homo_sapiens.GRCh37.75.gtf.gz"
if [[ -r "$FILE" ]]
then
	gunzip $FILE	
else
    echo "File '$FILE' is not downloaded properly"
	exit
fi

#creating Coding file
FILE="$WORKFLOW_PATH/perp_codingfile.pl";
if [[ -x $FILE ]]
then
	echo "Workflow script $FILE is found"	
else
    echo "Workflow script $FILE is not found"
	exit
fi

#bedtools
FILE="$BEDTOOLS/mergeBed";
if [[ -x $FILE ]]
then
	echo "Mergebed tool $FILE is found"	
else
    echo "Mergebed tools $FILE is not found"
	exit
fi

echo " creating coding file from annovare ref file"
FILE="$ANNOVAR/humandb/hg19_refGene.txt"
if [[ -r "$FILE" ]]
then
	perl $WORKFLOW_PATH/perp_codingfile.pl $ANNOVAR/humandb/hg19_refGene.txt coding.bed
	sort -T $ANNOVAR/humandb/ -k1,1 -k2,2n -k3,3n coding.bed|uniq> coding1.bed
	$BEDTOOLS/mergeBed -i coding1.bed > coding.bed
else
    echo "File '$FILE' is not found in ANNOVAR directory.First run the tool install script and then run the ref file script"
	exit
fi

#star fusion files
#wget https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/GRCh37_gencode_v19_CTAT_lib_July272016.tar.gz
wget $LINK_STAR_FUSION
FILE="GRCh37_gencode_v19_CTAT_lib_July272016.tar.gz"
if [[ -r "$FILE" ]]
then
	tar -zxvf $FILE	
else
    echo "File '$FILE' is not downloaded properly"
	exit
fi

cd GRCh37_gencode_v19_CTAT_lib_July272016
if [[ -x "$SAMTOOLS" ]]
then
	echo "SAMTOOLS $SAMTOOLS found or is executable"
else
    echo "SAMTOOLS $SAMTOOLS nor found or not executable"
	exit
fi

#Ref file
$SAMTOOLS faidx ref_genome.fa

if [[ -x $PICARD ]]
then
	$JAVA -jar  $PICARD CreateSequenceDictionary R=ref_genome.fa O=ref_genome.dict
else
    echo "PICARD tool $GATK is not found"
	exit
fi

cd $reffile_dir

##GATK recalibration sites
#wget ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz
wget $LINK_1KG
FILE="1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not downloaded properly"
	exit
fi
#wget ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz
wget $LINK_KG_MILLS
FILE="Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not downloaded properly"
	exit
fi
#wget ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/dbsnp_138.hg19.excluding_sites_after_129.vcf.gz
wget $LINK_DB_SNP
FILE="dbsnp_138.hg19.excluding_sites_after_129.vcf.gz"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not downloaded properly"
	exit
fi

BGZIP="$HTSDIR/bgzip"
TABIX="$HTSDIR/tabix"
if [[ -x $TABIX ]]
then
	gunzip 1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz dbsnp_138.hg19.excluding_sites_after_129.vcf.gz
	$BGZIP 1000G_phase1.snps.high_confidence.hg19.sites.vcf
	$BGZIP Mills_and_1000G_gold_standard.indels.hg19.sites.vcf
	$BGZIP dbsnp_138.hg19.excluding_sites_after_129.vcf
	$TABIX  -f -p vcf 1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz 
	$TABIX  -f -p vcf Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz 
	$TABIX  -f -p vcf dbsnp_138.hg19.excluding_sites_after_129.vcf.gz
else
    echo "tabix $TABIX is not found"
	exit
fi

#annovar
cd $reffile_dir
mkdir ANNOVAR_humandb/

FILE="$ANNOVAR/annotate_variation.pl";
if [[ -x $FILE ]]
then
	$PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar refGene ANNOVAR_humandb/
	cd ANNOVAR_humandb
	FILE="hg19_refGene.txt"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not downloaded properly"
		exit
	fi
	FILE="hg19_refGeneMrna.fa"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not downloaded properly"
		exit
	fi
	#$PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar ensGene ANNOVAR_humandb/
	#$PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar knownGene ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb tfbsConsSites ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb cytoBand ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb targetScanS ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb genomicSuperDups ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb dgvMerged ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb gwasCatalog ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb wgEncodeBroadHmmGm12878HMM ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -downdb 1000g2012apr ANNOVAR_humandb/ -buildver hg19
	# $PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar snp138 ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -build hg19 -downdb -webfrom annovar ljb23_sift ANNOVAR_humandb/ -buildver hg19
	# $PERL $ANNOVAR/annotate_variation.pl -downdb -webfrom annovar -build hg19 esp6500si_all ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -downdb -webfrom annovar -build hg19 exac03 ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar gerp++gt2 ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar clinvar_20140211 ANNOVAR_humandb/
	# $PERL $ANNOVAR/annotate_variation.pl -downdb -buildver hg19 -webfrom annovar cosmic68 ANNOVAR_humandb/
else
    echo "ANNOVAR $FILE is not found or not executable"
	exit
fi

#star reference files
cd $reffile_dir
mkdir STAR/

if [[ -x $STAR ]]
then
	$STAR --runMode genomeGenerate --genomeDir $reffile_dir/STAR --genomeFastaFiles $reffile_dir/GRCh37_gencode_v19_CTAT_lib_July272016/ref_genome.fa
	cd STAR
	FILE="SAindex"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not processed properly"
		exit
	fi
	FILE="SA"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not processed properly"
		exit
	fi
	FILE="Genome"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not processed properly"
		exit
	fi
	FILE="chrNameLength.txt"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not processed properly"
		exit
	fi
else
    echo "STAR tool $STAR is not found"
	exit
fi

#gsnap reference files
cd $reffile_dir
#wget ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz
wget $LINK_GENCODE
FILE="gencode.v19.annotation.gtf.gz"
if [[ -r "$FILE" ]]
then
	gunzip $FILE
	FILE="gencode.v19.annotation.gtf"
	if [[ ! -r "$FILE" ]]
	then
		echo "File '$FILE' is not processed properly"
		exit
	fi	
else
    echo "File $FILE is not downloaded properly"
	exit
fi
mkdir GSNAP/
cd GSNAP
fasta=$reffile_dir/GRCh37_gencode_v19_CTAT_lib_July272016/ref_genome.fa
genomeDir=$reffile_dir/GSNAP
if [[ -x $GSNAP ]]
then
	gsnapdir=`echo $GSNAP|sed -e 's/gsnap$//g'`
else
    echo "GSNAP tool $GSNAP is not found"
	exit
fi
$gsnapdir/gmap_build -d $genomeDir $fasta
FILE="GSNAP.sarray"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not processed properly"
	exit
fi
##create junction files using gencode annotation v19
cat $reffile_dir/gencode.v19.annotation.gtf | $gsnapdir/gtf_splicesites >$genomeDir/GSNAP.maps/gencode.v19.splicesites
FILE="$genomeDir/GSNAP.maps/gencode.v19.splicesites"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not processed properly"
	exit
fi
cat $reffile_dir/gencode.v19.annotation.gtf | $gsnapdir/gtf_introns >$genomeDir/GSNAP.maps/gencode.v19.introns
FILE="$genomeDir/GSNAP.maps/gencode.v19.introns"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not processed properly"
	exit
fi
cd $genomeDir/GSNAP.maps/
cat gencode.v19.splicesites | $gsnapdir/iit_store -o gencode.v19.splicesites.iit
FILE="gencode.v19.splicesites.iit"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not processed properly"
	exit
fi
cat gencode.v19.introns | $gsnapdir/iit_store -o gencode.v19.introns.iit
FILE="gencode.v19.introns.iit"
if [[ ! -r "$FILE" ]]
then
	echo "File '$FILE' is not processed properly"
	exit
fi
cd $reffile_dir

#processing the star fusion reference files
if [[ -x $STAR ]]
then
	stardir=`echo $STAR|sed -e 's/STAR$//g'`
else
    echo "STAR tool $STAR is not found"
	exit
fi
if [[ -x $GSNAP ]]
then
	gsnapdir=`echo $GSNAP|sed -e 's/gsnap$//g'`
else
    echo "GSNAP tool $GSNAP is not found"
	exit
fi

#bowtie
FILE="$BOWTIEDIR/bowtie-build";
if [[ -x $FILE ]]
then
	echo "bowtie build tool $FILE is found"	
else
    echo "bowtie build tools $FILE is not found"
	exit
fi

export PATH=$PATH:$stardir:$gsnapdir:$BOWTIEDIR

cd GRCh37_gencode_v19_CTAT_lib_July272016
if [[ -x $PERL ]]
then
	if [[ -x $STAR_FUSION ]]
	then	
		STAR_FUSION_HOME=`echo $STAR_FUSION|sed -e 's/STAR-Fusion$//g'`
		$STAR_FUSION_HOME/FusionFilter/prep_genome_lib.pl --genome_fa ref_genome.fa --gtf ref_annot.gtf --blast_pairs blast_pairs.outfmt6.gz
	else
		echo "STAR FUSION $STAR_FUSION is not found"
		exit
	fi
else
    echo "PERL $PERL is not found"
	exit
fi
 
echo "REF_GENOME=$reffile_dir/GRCh37_gencode_v19_CTAT_lib_July272016/ref_genome.fa"  >> $toolinfo_file
echo 'GATK_BASE_RECALIBRATION_KNOWNSITES="-knownSites '"$reffile_dir/1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz"' -knownSites '"$reffile_dir/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz"' -knownSites '"$reffile_dir/dbsnp_138.hg19.excluding_sites_after_129.vcf.gz"'"'>> $toolinfo_file
echo "STAR_REF=$reffile_dir/STAR">> $toolinfo_file
echo 'GSNAP_OPTION="-t 4 -A sam -D '"$reffile_dir/GSNAP"' -d GSNAP --use-splicing='"$reffile_dir/GSNAP/GSNAP.maps/gencode.v19.splicesites.iit"' -N 1 --read-group-id=group1 --read-group-name=sample1 --read-group-library=lib1 --read-group-platform=illumina"'>> $toolinfo_file
echo 'GATK_HAPLOTYPE_CALLER_OPTION=" -stand_call_conf 20.0  -ERCIS 50 -pcrModel HOSTILE  -stand_emit_conf 20.0  -mmq 20 -L '"$reffile_dir/coding.bed"' "'>> $toolinfo_file
echo 'ANNOVAR_OPTION="'"$reffile_dir/ANNOVAR_humandb/"' -buildver hg19 -remove -protocol refGene -operation g -nastring ."'>> $toolinfo_file
echo "STAR_FUSION_CTAT_LIB=$reffile_dir/GRCh37_gencode_v19_CTAT_lib_July272016">> $toolinfo_file
echo 'FEATURECOUNTS_OPTION="-t exon -g gene_name -a '"$reffile_dir/Homo_sapiens.GRCh37.75.gtf"'"'>> $toolinfo_file
