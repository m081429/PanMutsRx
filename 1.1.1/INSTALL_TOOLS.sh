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
##      -s      <source code directory>      -       (REQUIRED)      required source code directory
##      -d      <install directory>      -       (REQUIRED)      required path to directory for installation
##      -t      <tool install config file>      -       (REQUIRED)      required path to tool info config file
##      -w      <workflow script directory>      -       (REQUIRED)      required path to downloaded workflow scripts directory
##      -h      - Display this usage/help text (No arg)
#############################################################################
EOF
exit
}
echo "Options specified: $@"

while getopts "s:d:t:w:h" OPTION; do
    case $OPTION in
        s) source_dir=$OPTARG ;;
		d) install_dir=$OPTARG ;;
		t) toolinfo_config=$OPTARG ;;
		w) workflow_dir=$OPTARG ;;
		h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$source_dir" ] || [ -z "$install_dir" ] || [ -z "$toolinfo_config" ] || [ -z "$workflow_dir" ]; then
    usage
fi

echo "******************"
echo "Source Directory: $source_dir"
echo "Install Directory: $install_dir"
echo "Tool info Config file: $toolinfo_config"
echo "Workflow script directory: $workflow_dir"
echo "******************"

echo "checking tool info tools"
source $toolinfo_config

if [[ -x "$TAR" ]]
then
    echo "tar '$TAR' is found and executable"
else
    echo "tar '$TAR' is not executable or found"
	exit
fi

if [[ -x "$UNZIP" ]]
then
    echo "unzip '$UNZIP' is found and executable"
else
    echo "unzip '$UNZIP' is not executable or found"
	exit
fi

if [[ -x "$BZIP2" ]]
then
    echo "bzip2 '$BZIP2' is found and executable"
else
    echo "bzip2 '$BZIP2' is not executable or found"
	exit
fi

if [[ -x "$JAVA" ]]
then
    echo "java '$JAVA' is found and executable"
else
    echo "java '$JAVA' is not executable or found"
	exit
fi

if [[ -x "$PERL" ]]
then
    echo "perl '$PERL' is found and executable"
else
    echo "perl '$PERL' is not executable or found"
	exit
fi

if [[ -x "$PYTHON" ]]
then
    echo "python '$PYTHON' is found and executable"
else
    echo "python '$PYTHON' is not executable or found"
	exit
fi

if [[ -x "$TAR" ]]
then
    echo "tar '$TAR' is found and executable"
else
    echo "tar '$TAR' is not executable or found"
	exit
fi

if [[ -x "$SH" ]]
then
    echo "sh '$SH' is found and executable"
else
    echo "sh '$SH' is not executable or found"
	exit
fi

#if [[ -x "$QSUB" ]]
#then
 #   echo "qsub '$QSUB' is found and executable"
#else
 #   echo "qsub '$QSUB' is not executable or found"
#fi

FILE="$workflow_dir/SomaticCaller.py"
if [[ -x "$FILE" ]]
then
    echo "workflow directory $workflow_dir is found"
else
    echo "workflow directory $workflow_dir not found"
	exit
fi

#checking tar
#checking unzip
#checking bzip2
#
#

mkdir -p $install_dir
cd $install_dir

touch $install_dir/TOOL_INFO.txt



#STAR
mkdir STAR
cd STAR
$TAR -zxvf $source_dir/2.5.2b.tar.gz 
cd STAR-2.5.2b/bin/Linux_x86_64


cd $install_dir
#GSNAP
mkdir GSNAP
cd GSNAP
$TAR -zxvf $source_dir/gmap-gsnap-2014-12-31.v2.tar.gz
cd gmap-2014-12-31
mkdir gmapdb
./configure --prefix=$install_dir/GSNAP/gmap-2014-12-31 --with-gmapdb=$install_dir/GSNAP/gmap-2014-12-31/gmapdb  
make 
make install   >> LOG.log 2>&1 


cd $install_dir
#SAMTOOLS
mkdir SAMTOOLS
cd SAMTOOLS/
cp $source_dir/samtools-1.3.1.tar.bz2 .
$BZIP2 -d samtools-1.3.1.tar.bz2 
$TAR -xvf samtools-1.3.1.tar
cd samtools-1.3.1
make 
make prefix=$install_dir/SAMTOOLS/samtools-1.3.1 install  >> LOG.log 2>&1


cd $install_dir
#FEATURE COUNTS
mkdir FEATURECOUNTS
cd FEATURECOUNTS/
$TAR -zxvf  $source_dir/subread-1.5.1-Linux-x86_64.tar.gz 
cd subread-1.5.1-Linux-x86_64


cd $install_dir
#HTSDIR
mkdir HTSDIR
cd HTSDIR/
cp $source_dir/htslib-1.3.2.tar.bz2 .
$BZIP2 -d htslib-1.3.2.tar.bz2
$TAR -xvf htslib-1.3.2.tar
cd htslib-1.3.2
./configure --prefix=$install_dir/HTSDIR/htslib-1.3.2
make
make install
HTSDIR=$install_dir/HTSDIR/htslib-1.3.2/bin


cd $install_dir
#BCFTOOLS
#mkdir BCFTOOLS
#cd BCFTOOLS/
#cp $source_dir/bcftools-1.3.1.tar.bz2 .
#$BZIP2 -d bcftools-1.3.1.tar.bz2
#$TAR -xvf bcftools-1.3.1.tar
#cd bcftools-1.3.1
#make prefix=$install_dir/BCFTOOLS/bcftools-1.3.1 install



cd $install_dir
#SAMBLASTER
mkdir SAMBLASTER
cd SAMBLASTER/
$UNZIP $source_dir/samblaster-master.zip
cd samblaster-master
make 


cd $install_dir
#SAMBAMBA
mkdir SAMBAMBA
cd SAMBAMBA
cp $source_dir/sambamba_v0.6.4_linux.tar.bz2 .
$BZIP2 -d sambamba_v0.6.4_linux.tar.bz2
$TAR -xvf sambamba_v0.6.4_linux.tar


cd $install_dir
#PICARD
mkdir PICARD
cd PICARD/
cp $source_dir/picard.jar .


cd $install_dir
#GATK
mkdir GATK
cd GATK
cp $source_dir/GenomeAnalysisTK-3.6.tar.bz2 .
$BZIP2 -d GenomeAnalysisTK-3.6.tar.bz2
$TAR -xvf GenomeAnalysisTK-3.6.tar



cd $install_dir
#ANNOVAR
mkdir ANNOVAR
cd ANNOVAR
$TAR -zxvf  $source_dir/annovar.latest.tar.gz 
cd annovar/



cd $install_dir
#STRELKA
mkdir STRELKA
cd STRELKA
$TAR -zxvf  $source_dir/strelka_workflow-1.0.15.tar.gz 
cd strelka_workflow-1.0.15/
./configure --prefix=$install_dir/STRELKA/strelka_workflow-1.0.15
make


cd $install_dir
#STARFUSION
mkdir STARFUSION
cd STARFUSION/
$UNZIP $source_dir/STAR-Fusion-master.zip
cd STAR-Fusion

cd $install_dir
#BOWTIE
mkdir BOWTIE
cd BOWTIE/
$UNZIP $source_dir/bowtie-1.1.2-linux-x86_64.zip


cd $install_dir
#BEDTOOLS
mkdir BEDTOOLS
cd BEDTOOLS/
$TAR -zxvf  $source_dir/bedtools-2.25.0.tar.gz
cd bedtools2
make

mkdir $install_dir/STARFUSION/PERLPACKAGE/
cd $install_dir/STARFUSION/PERLPACKAGE/
$TAR -zxvf $source_dir/Set-IntervalTree-0.02.tar.gz
cd Set-IntervalTree-0.02
$PERL Makefile.PL PREFIX=$install_dir/STARFUSION/PERLPACKAGE/lib
make
make install

cd $install_dir/STARFUSION/PERLPACKAGE/
$TAR -zxvf $source_dir/DB_File-1.840.tar.gz
cd DB_File-1.840
$PERL Makefile.PL PREFIX=$install_dir/STARFUSION/PERLPACKAGE/lib
make
make install

cd $install_dir/STARFUSION/PERLPACKAGE/
$TAR -zxvf $source_dir/URI-1.71.tar.gz
cd URI-1.71
$PERL Makefile.PL PREFIX=$install_dir/STARFUSION/PERLPACKAGE/lib
make
make install

path_star_fusion=`find $install_dir/STARFUSION/PERLPACKAGE/lib  -name 'IntervalTree.pm'`
path_star_fusion=`echo $path_star_fusion|sed -e 's/Set\/IntervalTree.pm//'`
#cp $source_dir/DB_File.pm $path_star_fusion


cd $install_dir
echo "checking tools are installed properly"
Tools_not_installed=" "


echo "JAVA=$JAVA" > $install_dir/TOOL_INFO.txt
echo "PYTHON=$PYTHON" >> $install_dir/TOOL_INFO.txt
echo "PERL=$PERL" >> $install_dir/TOOL_INFO.txt
echo "SH=$SH" >> $install_dir/TOOL_INFO.txt
echo "WORKFLOW_PATH=$workflow_dir" >> $install_dir/TOOL_INFO.txt
echo "STAR_FUSION_PERL_PACKAGE=$path_star_fusion" >> $install_dir/TOOL_INFO.txt
if [[ -x "$QSUB" ]]
then
    echo "QSUB=$QSUB" >> $install_dir/TOOL_INFO.txt
else
    echo "QSUB=NA" >> $install_dir/TOOL_INFO.txt
fi

#checking star
testp=`$install_dir/STAR/STAR-2.5.2b/bin/Linux_x86_64/STAR | grep -c 'versionSTAR'`
if [ $testp -ne 1 ]
	then
	echo "star not installed properly"
	Tools_not_installed=$Tools_not_installed" STAR"
	echo "STAR=$install_dir/STAR/STAR-2.5.2b/bin/Linux_x86_64/STAR(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "STAR=$install_dir/STAR/STAR-2.5.2b/bin/Linux_x86_64/STAR" >> $install_dir/TOOL_INFO.txt
fi

#checking gsnap
testp=`$install_dir/GSNAP/gmap-2014-12-31/bin/gsnap --version| grep -c 'GSNAP:'`
if [ $testp -ne 1 ]
	then
	echo "gsnap not installed properly"
	Tools_not_installed=$Tools_not_installed" GSNAP"
	echo "GSNAP=$install_dir/GSNAP/gmap-2014-12-31/bin/gsnap(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "GSNAP=$install_dir/GSNAP/gmap-2014-12-31/bin/gsnap" >> $install_dir/TOOL_INFO.txt
fi

#checking samtools
testp=`$install_dir/SAMTOOLS/samtools-1.3.1/samtools index|grep -c "samtools index"`
if [ $testp -ne 1 ]
	then
	echo "samtools not installed properly"
	Tools_not_installed=$Tools_not_installed" SAMTOOLS"
	echo "SAMTOOLS=$install_dir/SAMTOOLS/samtools-1.3.1/samtools(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
	echo "HTSDIR=$install_dir/HTSDIR/htslib-1.3.2/bin(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "SAMTOOLS=$install_dir/SAMTOOLS/samtools-1.3.1/samtools" >> $install_dir/TOOL_INFO.txt
	echo "HTSDIR=$install_dir/HTSDIR/htslib-1.3.2/bin" >> $install_dir/TOOL_INFO.txt
fi

#checking featureCounts
testp=`$install_dir/FEATURECOUNTS/subread-1.5.1-Linux-x86_64/bin/featureCounts -v 2>&1| grep -c 'featureCounts'`
if [ $testp -ne 1 ]
	then
	echo "featureCounts not installed properly"
	Tools_not_installed=$Tools_not_installed" featureCounts"
	echo "FEATURECOUNTS=$install_dir/FEATURECOUNTS/subread-1.5.1-Linux-x86_64/bin/featureCounts(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "FEATURECOUNTS=$install_dir/FEATURECOUNTS/subread-1.5.1-Linux-x86_64/bin/featureCounts" >> $install_dir/TOOL_INFO.txt
fi

#checking bcftools
#testp=`$install_dir/BCFTOOLS/bcftools-1.3.1/bin/bcftools --version|grep -c "bcftools"`
#if [ $testp -ne 1 ]
#	then
#	echo "bcftools not installed properly"
#	Tools_not_installed=$Tools_not_installed" bcftools"
#	echo "BCFTOOLS=$install_dir/BCFTOOLS/bcftools-1.3.1/bin/bcftools(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
#else
#	echo "BCFTOOLS=$install_dir/BCFTOOLS/bcftools-1.3.1/bin/bcftools" >> $install_dir/TOOL_INFO.txt
#fi

#checking samblaster
testp=`$install_dir/SAMBLASTER/samblaster-master/samblaster -h 2>&1|grep -c 'Version'`
if [ $testp -ne 1 ]
	then
	echo "samblaster not installed properly"
	Tools_not_installed=$Tools_not_installed" samblaster"
	echo "SAMBLASTER=$install_dir/SAMBLASTER/samblaster-master/samblaster(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "SAMBLASTER=$install_dir/SAMBLASTER/samblaster-master/samblaster" >> $install_dir/TOOL_INFO.txt
fi

#checking sambamba
testp=`$install_dir/SAMBAMBA/sambamba_v0.6.4 view 2>&1|grep -c "Options"`
if [ $testp -ne 1 ]
	then
	echo "sambamba not installed properly"
	Tools_not_installed=$Tools_not_installed" sambamba"
	echo "SAMBAMBA=$install_dir/SAMBAMBA/sambamba_v0.6.4(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "SAMBAMBA=$install_dir/SAMBAMBA/sambamba_v0.6.4" >> $install_dir/TOOL_INFO.txt
fi

#checking picard
testp=`$JAVA -jar $install_dir/PICARD/picard.jar -h 2>&1|grep -c "Available Programs"`
if [ $testp -ne 1 ]
	then
	echo "picard not installed properly"
	Tools_not_installed=$Tools_not_installed" picard"
	echo "PICARD=$install_dir/PICARD/picard.jar(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "PICARD=$install_dir/PICARD/picard.jar" >> $install_dir/TOOL_INFO.txt
fi

#checking gatk
testp=`$JAVA -jar $install_dir/GATK/GenomeAnalysisTK.jar -T HaplotypeCaller -h|grep -c  "Number of reads per SAM file"`
if [ $testp -ne 1 ]
	then
	echo "gatk not installed properly"
	Tools_not_installed=$Tools_not_installed" gatk"
	echo "GATK=$install_dir/GATK/GenomeAnalysisTK.jar(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "GATK=$install_dir/GATK/GenomeAnalysisTK.jar" >> $install_dir/TOOL_INFO.txt
fi

#checking annovar
testp=`$PERL $install_dir/ANNOVAR/annovar/annotate_variation.pl -h|grep -c "print complete documentation"`
if [ $testp -ne 1 ]
	then
	echo "annovar not installed properly"
	Tools_not_installed=$Tools_not_installed" annovar"
	echo "ANNOVAR=$install_dir/ANNOVAR/annovar(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "ANNOVAR=$install_dir/ANNOVAR/annovar" >> $install_dir/TOOL_INFO.txt
fi

#checking strelka
testp=`$PERL $install_dir/STRELKA/strelka_workflow-1.0.15/bin/configureStrelkaWorkflow.pl 2>&1|grep -c "Path to tumor sample BAM"`
if [ $testp -ne 1 ]
	then
	echo "strelka not installed properly"
	Tools_not_installed=$Tools_not_installed" strelka"
	echo "STRELKA_WORKFLOW=$install_dir/STRELKA/strelka_workflow-1.0.15(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "STRELKA_WORKFLOW=$install_dir/STRELKA/strelka_workflow-1.0.15" >> $install_dir/TOOL_INFO.txt
fi

#checking star_fusion
export PERL5LIB=$path_star_fusion
testp=`$PERL $install_dir/STARFUSION/STAR-Fusion/STAR-Fusion 2>&1|grep -c "directory containing genome lib"`
if [ $testp -ne 1 ]
	then
	echo "star_fusion not installed properly"
	Tools_not_installed=$Tools_not_installed" star_fusion"
	echo "STAR_FUSION=$install_dir/STARFUSION/STAR-Fusion/STAR-Fusion(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "STAR_FUSION=$install_dir/STARFUSION/STAR-Fusion/STAR-Fusion" >> $install_dir/TOOL_INFO.txt
fi

#checking bedtools
testp=`$install_dir/BEDTOOLS/bedtools2/bin/mergeBed --help 2>&1|grep -c "Merges overlapping BED"`
if [ $testp -ne 1 ]
	then
	echo "bedtools not installed properly"
	Tools_not_installed=$Tools_not_installed" bedtools"
	echo "BEDTOOLS=$install_dir/BEDTOOLS/bedtools2/bin/(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "BEDTOOLS=$install_dir/BEDTOOLS/bedtools2/bin/" >> $install_dir/TOOL_INFO.txt
fi

#checking bowtie
testp=`$install_dir/BOWTIE/bowtie-1.1.2/bowtie-build --version 2>&1|grep -c "1.1.2"`
if [ $testp -ne 1 ]
	then
	echo "bowtie not installed properly"
	Tools_not_installed=$Tools_not_installed" bowtie"
	echo "BOWTIEDIR=$install_dir/BOWTIE/bowtie-1.1.2(PLEASE INSTALL PROPERLY)" >> $install_dir/TOOL_INFO.txt
else
	echo "BOWTIEDIR=$install_dir/BOWTIE/bowtie-1.1.2" >> $install_dir/TOOL_INFO.txt
fi


if [[ $Tools_not_installed == " " ]]; then   
  echo "Tools installed properly"  $Tools_not_installed
else
  echo "Tools not installed properly" $Tools_not_installed
  #exit 1
fi

echo "writing extra default paramaters"
echo 'SAMBLASTER_OPTIONS=" "'  >> $install_dir/TOOL_INFO.txt
echo 'PICARD_ARG_OPTION="SO=coordinate RGID=group1 RGLB=lib1 RGPL=illumina RGPU=unit1 RGSM=sample1"' >> $install_dir/TOOL_INFO.txt
echo 'STAR_OPTION="--runThreadN 4"' >> $install_dir/TOOL_INFO.txt
echo 'STAR_OPTION_STEP2="--chimSegmentMin 12 --chimJunctionOverhangMin 12 --alignSJDBoverhangMin 10 --alignMatesGapMax 200000 --alignIntronMax 200000 --limitBAMsortRAM 31532137230 --outSAMstrandField intronMotif --outSAMtype BAM Unsorted"' >> $install_dir/TOOL_INFO.txt
echo 'GSNAP_JAVA_OPTION="-XX:CompileThreshold=1000 -XX:ReservedCodeCacheSize=128m -Xmx20g -Xms5g"' >> $install_dir/TOOL_INFO.txt
echo 'GATK_JAVA_OPTION="-XX:CompileThreshold=1000 -XX:ReservedCodeCacheSize=128m -Xmx20g -Xms5g"' >> $install_dir/TOOL_INFO.txt
echo 'GATK_SPLITNCIGAR_OPT="-RMQF 255 -RMQT 60"' >> $install_dir/TOOL_INFO.txt
echo 'DEBUG=NO' >> $install_dir/TOOL_INFO.txt
echo 'REMOVE_DUP_READS="TRUE"' >> $install_dir/TOOL_INFO.txt
echo 'ANNOVAR_QUEUE=1-day' >> $install_dir/TOOL_INFO.txt
echo 'ANNOVAR_MEM=30G' >> $install_dir/TOOL_INFO.txt
#echo 'BCFTOOLS_OPTIONS=""' >> $install_dir/TOOL_INFO.txt
echo 'SAMTOOLS_BCFTOOLS_OPTIONS=" -q 20"' >> $install_dir/TOOL_INFO.txt
echo 'DELETE_BAM_POST_GATK_PROCESS=YES' >> $install_dir/TOOL_INFO.txt
echo 'SAMBAMBA_PARAM="  -m 12GB -t 4 "' >> $install_dir/TOOL_INFO.txt
echo 'GSNAP_QUEUE=4-days' >> $install_dir/TOOL_INFO.txt
echo 'GSNAP_MEM=30G' >> $install_dir/TOOL_INFO.txt
echo 'STAR_QUEUE=lg-mem' >> $install_dir/TOOL_INFO.txt
echo 'STAR_MEM=50G' >> $install_dir/TOOL_INFO.txt
echo 'GATK_QUEUE=4-days' >> $install_dir/TOOL_INFO.txt
echo 'GATK_MEM=30G' >> $install_dir/TOOL_INFO.txt
#echo 'BCFTOOLS_QUEUE=4-days' >> $install_dir/TOOL_INFO.txt
#echo 'BCFTOOLS_MEM=30G' >> $install_dir/TOOL_INFO.txt
echo 'STRELKA_QUEUE=4-days' >> $install_dir/TOOL_INFO.txt
echo 'STRELKA_MEM=30G' >> $install_dir/TOOL_INFO.txt
echo 'STAR_QUEUE=4-days' >> $install_dir/TOOL_INFO.txt
echo 'STAR_MEM=30G' >> $install_dir/TOOL_INFO.txt
echo 'STARFUSION_MITO_FILTER=YES' >> $install_dir/TOOL_INFO.txt
cat $install_dir/STRELKA/strelka_workflow-1.0.15/demo/strelka_demo_config.ini |sed 's/extraStrelkaArguments =/extraStrelkaArguments = --ignore-conflicting-read-names/' > $install_dir/STRELKA/strelka_workflow-1.0.15/strelka_demo_config.ini
echo "STRELKA_CONFIG=$install_dir/STRELKA/strelka_workflow-1.0.15/strelka_demo_config.ini" >> $install_dir/TOOL_INFO.txt

if [[ $Tools_not_installed == " " ]]; then   
  echo "Tools installed properly"  $Tools_not_installed
else
  echo "Tools not installed properly" $Tools_not_installed
  exit 1
fi