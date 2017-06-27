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
##      script to run somatic strelka
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -f      <BamfilePath>      -       (REQUIRED)      required file with fullpath to Bamfiles(each line should contain <NORMAL BAMFILE>)
##      -s      <BamfilePath>      -       (REQUIRED)      required file with fullpath to Bamfiles(each line should contain <TUMOR BAMFILE>)
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

while getopts "c:f:s:r:e:i:n:h" OPTION; do
    case $OPTION in
        c) config=$OPTARG ;;
		f) fastq=$OPTARG ;;
		s) somaticfastq=$OPTARG ;;
		r) rundir=$OPTARG ;;
		e) EMAIL=$OPTARG ;;
		i) RUNID=$OPTARG ;;
		n) JOB_NUM=$OPTARG ;;
        h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$config" ] || [ -z "$fastq" ] || [ -z "$somaticfastq" ] || [ -z "$rundir" ] || [ -z "$EMAIL" ] || [ -z "$RUNID" ]; then
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

normalbam=`cat $fastq|head -$SGE_TASK_ID|tail -1`
tumorbam=`cat $somaticfastq|head -$SGE_TASK_ID|tail -1`
sampname=`basename $tumorbam|sed -s 's/.bam//g'`
START=$(date +%s)
k3=$rundir
mkdir -p $k3
cd $k3
output=$rundir/$sampname.strelka
# $PERL $STRELKA_WORKFLOW/install/bin/configureStrelkaWorkflow.pl  --tumor=$tumorbam --normal=$normalbam --ref=$REF_GENOME --config=$STRELKA_CONFIG --output-dir=$output
$PERL $STRELKA_WORKFLOW/bin/configureStrelkaWorkflow.pl  --tumor=$tumorbam --normal=$normalbam --ref=$REF_GENOME --config=$STRELKA_CONFIG --output-dir=$output
check_variable $? $0 $sampname "Strelka Somatic Caller configration step" $EMAIL $RUNID
cd  $output
make 
check_variable $? $0 $sampname "Strelka Somatic Caller calling(Make) step" $EMAIL $RUNID

cd $k3

mv $output/results/passed.somatic.snvs.vcf $rundir/$sampname.strelka.passed.somatic.snvs.vcf
mv $output/results/all.somatic.snvs.vcf $rundir/$sampname.strelka.all.somatic.snvs.vcf
mv $output/results/passed.somatic.indels.vcf $rundir/$sampname.strelka.passed.somatic.indels.vcf
mv $output/results/all.somatic.indels.vcf $rundir/$sampname.strelka.all.somatic.indels.vcf

if [ $DEBUG != "YES" ] || [ $DEBUG != "yes" ]
then
        
		rm $output/config/*
		rmdir $output/config
		rm $output/results/*
		rmdir $output/results/
		rm $output/chromosomes/chr*/bins/*/*
		rmdir $output/chromosomes/chr*/bins/*
		rmdir $output/chromosomes/chr*/bins
		rm $output/chromosomes/chr*/*
		rmdir $output/chromosomes/chr*
		rmdir $output/chromosomes
		rm $output/*
		rmdir $output
fi

if [ "$ANNOVAR_OPTION" != "NA" ] && [ "$ANNOVAR_OPTION" != "na" ] 
then
	#Converting STRELKA output to VCF file for annovar input
	IFS=$'\n'
	for i in `cat $sampname.strelka.passed.somatic.snvs.vcf`
	do
			if [[ "$i" =~ ^# ]]
			then
					echo $i >> $sampname.strelka.passed.somatic.snvs.ANN.vcf
			else
					a=(`echo $i | tr '\t' '\n'`)
					if [[ "${a[7]}" =~ "->${a[4]}${a[4]}" ]]
					then
							echo -e "${a[0]}\t${a[1]}\t${a[2]}\t${a[3]}\t${a[4]}\t${a[5]}\t${a[6]}\t${a[7]}\tGT:${a[8]}\t1/1:${a[9]}\t${a[10]}" >> $sampname.strelka.passed.somatic.snvs.ANN.vcf
					elif [[ "${a[7]}" =~ "->${a[3]}${a[4]}" ]]
					then
							echo -e "${a[0]}\t${a[1]}\t${a[2]}\t${a[3]}\t${a[4]}\t${a[5]}\t${a[6]}\t${a[7]}\tGT:${a[8]}\t0/1:${a[9]}\t${a[10]}" >> $sampname.strelka.passed.somatic.snvs.ANN.vcf
					else
							echo -e "${a[0]}\t${a[1]}\t${a[2]}\t${a[3]}\t${a[4]}\t${a[5]}\t${a[6]}\t${a[7]}\tGT:${a[8]}\t1/0:${a[9]}\t${a[10]}" >> $sampname.strelka.passed.somatic.snvs.ANN.vcf
					fi
			fi
	done
	annovar $config $rundir $sampname.strelka.passed.somatic.snvs.ANN.vcf
	check_variable $? $0 $sampname "STRELKA ANNOVAR step for SNPS" $EMAIL $RUNID
	rm $sampname.strelka.passed.somatic.snvs.vcf
	sed -e 's/\tGT:/\t/g' -e 's/\t0\/1:/\t/g' -e 's/\t1\/1:/\t/g' -e 's/\t1\/0:/\t/g' $sampname.strelka.passed.somatic.snvs.ANN.ANNOVAR.vcf  > $sampname.strelka.passed.somatic.snvs.ANNOVAR.vcf 
	rm $sampname.strelka.passed.somatic.snvs.ANN.ANNOVAR.vcf
	
	#$PYTHON $WORKFLOW_PATH/Gene_Filter.py -g $GENE_FILTER -i $sampname.strelka.passed.somatic.snvs.ANNOVAR.vcf  -o $sampname.strelka.passed.somatic.snvs.ANNOVAR.GENE_FILTER.vcf 
	#check_variable $? $0 $sampname "GENE FILTER STRELKA ANNOVAR SNP step" $EMAIL $RUNID
	
	#Converting STRELKA output to VCF file for annovar input
	IFS=$'\n'
	for i in `cat $sampname.strelka.passed.somatic.indels.vcf`
	do
        if [[ "$i" =~ ^# ]]
        then
                echo $i >> $sampname.strelka.passed.somatic.indels.ANN.vcf
        else
                a=(`echo $i | tr '\t' '\n'`)
                if [[ "${a[7]}" =~ "->hom" ]]
                then
                        echo -e "${a[0]}\t${a[1]}\t${a[2]}\t${a[3]}\t${a[4]}\t${a[5]}\t${a[6]}\t${a[7]}\tGT:${a[8]}\t1/1:${a[9]}\t${a[10]}" >> $sampname.strelka.passed.somatic.indels.ANN.vcf
                else
                        echo -e "${a[0]}\t${a[1]}\t${a[2]}\t${a[3]}\t${a[4]}\t${a[5]}\t${a[6]}\t${a[7]}\tGT:${a[8]}\t0/1:${a[9]}\t${a[10]}" >> $sampname.strelka.passed.somatic.indels.ANN.vcf
                fi
        fi
	done

	annovar $config $rundir $sampname.strelka.passed.somatic.indels.ANN.vcf
	check_variable $? $0 $sampname "STRELKA ANNOVAR step for INDELS" $EMAIL $RUNID
	rm $sampname.strelka.passed.somatic.indels.vcf
	sed -e 's/\tGT:/\t/g' -e 's/\t0\/1:/\t/g' -e 's/\t1\/1:/\t/g' -e 's/\t1\/0:/\t/g' $sampname.strelka.passed.somatic.indels.ANN.ANNOVAR.vcf  > $sampname.strelka.passed.somatic.indels.ANNOVAR.vcf 
	rm $sampname.strelka.passed.somatic.indels.ANN.ANNOVAR.vcf
	#if [ "$GENE_FILTER" != "NA" ] && [ "$GENE_FILTER" != "na" ] 
	#then
	#	$PYTHON $WORKFLOW_PATH/Gene_Filter.py -g $GENE_FILTER -i $sampname.strelka.passed.somatic.indels.ANNOVAR.vcf   -o $sampname.strelka.passed.somatic.indels.ANNOVAR.GENE_FILTER.vcf 
	#	check_variable $? $0 $sampname "GENE FILTER STRELKA ANNOVAR INDELS step" $EMAIL $RUNID
	#fi
fi

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Strelka Somatic Calling  for $samplename took $DIFF seconds"
