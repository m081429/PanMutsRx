#! /usr/bin/env bash
#trap "exit 100; exit" ERR
####################
## Script Options ##
####################
#$ -V

#set -x

usage ()
{
cat << EOF
######################################################################
##      script to run star fusion
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -f      <fastqfile>      -       (REQUIRED)      required file with path to fastq(each line should contain <FASTQ1> <FASTQ2>)
##      -r      <rundir>      -       (REQUIRED)      rundir
##      -e      <email>      -       (REQUIRED)      email
##      -i      <runid>      -       (REQUIRED)      runid
##      -n      <filenumber>      -             file number to process
##      -h      - Display this usage/help text (No arg)
#############################################################################
EOF
exit
}
echo "Options specified: $@"

while getopts "c:f:r:e:i:n:h" OPTION; do
    case $OPTION in
        c) config=$OPTARG ;;
		f) fastq=$OPTARG ;;
		r) rundir=$OPTARG ;;
        e) EMAIL=$OPTARG ;;
		i) RUNID=$OPTARG ;;
		n) JOB_NUM=$OPTARG ;;
        h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$config" ] || [ -z "$fastq" ] || [ -z "$rundir" ] || [ -z "$EMAIL" ] || [ -z "$RUNID" ]; then
    usage
fi

#loading the config file
source $config
source $WORKFLOW_PATH/shared_functions.sh

if [ ! -z $JOB_NUM ]
then
	SGE_TASK_ID=$JOB_NUM
fi

if [ -z $SGE_TASK_ID ]
then
	SGE_TASK_ID=1
fi
sampname=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'|cut -d ' ' -f1`
inputfastq1=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'|cut -d ' ' -f2`
inputfastq2=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'|cut -d ' ' -f3`

START=$(date +%s)
mkdir -p $rundir
cd $rundir/$sampname.process_dir_pass2
k3=$rundir


export PERL5LIB=$STAR_FUSION_PERL_PACKAGE
if [ "$STARFUSION_MITO_FILTER" == "YES" ]
then
	awk -F "\t" '{if($1!="chrM" && $4!="chrM")print $0}' Chimeric.out.junction > Chimeric.out.junction.noMito
	#mv Chimeric.out.junction Chimeric.out.junction.all
	#mv Chimeric.out.junction.noMito Chimeric.out.junction
else
	cp Chimeric.out.junction Chimeric.out.junction.noMito
fi
$PERL  $STAR_FUSION --genome_lib_dir $STAR_FUSION_CTAT_LIB -J Chimeric.out.junction.noMito --output_dir star_fusion_outdir --left_fq  $inputfastq1 --right_fq $inputfastq2
exit_code=$?
check_variable $exit_code $0 $sampname "STAR Fusion Calling step" $EMAIL $RUNID

sampname1=`echo $sampname|sed -s 's/.STAR//g'`
rundir1=`echo $rundir|xargs dirname|xargs dirname`
cp $rundir/$sampname.process_dir_pass2/star_fusion_outdir/star-fusion.fusion_candidates.final.abridged.FFPM $rundir1/FUSIONS/$sampname1.star_fusion.txt	
n1=`head -1 $rundir1/FUSIONS/$sampname1.star_fusion.txt|tr '\t' '\n'|grep -n "J_FFPM"|cut -f1 -d ':'`
n2=`head -1 $rundir1/FUSIONS/$sampname1.star_fusion.txt|tr '\t' '\n'|grep -n "S_FFPM"|cut -f1 -d ':'`
n3=`head -1 $rundir1/FUSIONS/$sampname1.star_fusion.txt|tr '\t' '\n'|grep -n "LargeAnchorSupport"|cut -f1 -d ':'`
head -1  $rundir1/FUSIONS/$sampname1.star_fusion.txt > $rundir1/FUSIONS/$sampname1.star_fusion_filtered.txt
awk -F "\t" -v x=$n1 -v y=$n2 -v z=$n3 '{if($x+$y > 0.1 && $z=="YES_LDAS")print $0}' $rundir1/FUSIONS/$sampname1.star_fusion.txt >> $rundir1/FUSIONS/$sampname1.star_fusion_filtered.txt
fcount=`cat $rundir1/FUSIONS/$sampname1.star_fusion_filtered.txt|wc -l`
fcount=$((fcount -1))
cd $rundir/
tar -zcvf $sampname1.STARFUSIONDIR.tar.gz $sampname1.STAR.process_dir_pass2
rm $rundir/$sampname1.STAR.process_dir_pass2/*
rm $rundir/$sampname1.STAR.process_dir_pass2/*/*
rm $rundir/$sampname1.STAR.process_dir_pass2/*/*/*
rmdir $rundir/$sampname1.STAR.process_dir_pass2/*/*
rmdir $rundir/$sampname1.STAR.process_dir_pass2/*
rmdir $rundir/$sampname1.STAR.process_dir_pass2/


END=$(date +%s)
DIFF=$(( $END - $START ))
echo "STAR fusion for $sampname took $DIFF seconds"
