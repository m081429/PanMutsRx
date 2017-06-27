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
##      script to run gsnap
## Script Options:
##		-c 		<tool_info_config>      -       (REQUIRED)      required tool info config file
##      -g      <genelist>      -       (REQUIRED)      required gene list
##      -r      <rundir>      -       (REQUIRED)      rundir
##      -d      <dirname>      -       (REQUIRED)      results directory name
##      -h      - Display this usage/help text (No arg)
#############################################################################
EOF
exit
}
echo "Options specified: $@"

while getopts "c:g:r:d:h" OPTION; do
    case $OPTION in
        c) config=$OPTARG ;;
		g) genelist=$OPTARG ;;
		r) rundir=$OPTARG ;;
		d) res_dirname=$OPTARG ;;
		h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$config" ] || [ -z "$genelist" ] || [ -z "$rundir" ] || [ -z "$res_dirname" ]; then
    usage
fi

if [ ! -f "$config" ]; then
	echo "config file $config not found"
fi

source $config

if [ ! -f "$genelist" ]; then
	echo "gene list not found"
fi

if [ ! -d "$rundir" ]; then
	echo "rundir $rundir not found"
fi

START=$(date +%s)
script=$0
dirname=`dirname $script`
filter_script="$dirname/Gene_Filter.py"
process_dir="$rundir/$res_dirname"
mkdir -p $process_dir
#echo "$filter_script $process_dir"

#fusions
tmpdir="$rundir/FUSIONS"
restmpdir="$process_dir/FUSIONS"
if [  -d "$tmpdir" ]; then
	mkdir -p $restmpdir
	$PYTHON  $WORKFLOW_PATH/Gene_Filter.py  -g $genelist -i $tmpdir -f fusion -o $restmpdir/FUSION_FILTERED.txt
	
fi

#gene counts
tmpdir="$rundir/GENECOUNTS"
restmpdir="$process_dir/GENECOUNTS"
if [  -d "$tmpdir" ]; then
	mkdir -p $restmpdir
	for i in `find $tmpdir -name '*txt'`
	do 
		tmpdir1=`dirname $i`
		bsedir=`basename $tmpdir1`
		bsefile=`basename $i`
		mkdir -p $restmpdir/$bsedir
		$PYTHON  $WORKFLOW_PATH/Gene_Filter.py  -g $genelist -i $tmpdir/$bsedir/$bsefile -f expression -o $restmpdir/$bsedir/$bsefile
	done	
	
fi

#snvindels star
tmpdir="$rundir/SNVINDEL/STAR/"
restmpdir="$process_dir/SNVINDEL/STAR/"
if [  -d "$tmpdir" ]; then
	mkdir -p $restmpdir
	$PYTHON  $WORKFLOW_PATH/Gene_Filter.py  -g $genelist -i $tmpdir -f variant -o $restmpdir/STAR_SNVINDEL.txt
fi

#snvindels gsnap
tmpdir="$rundir/SNVINDEL/GSNAP/"
restmpdir="$process_dir/SNVINDEL/GSNAP/"
if [  -d "$tmpdir" ]; then
	mkdir -p $restmpdir
	$PYTHON  $WORKFLOW_PATH/Gene_Filter.py  -g $genelist -i $tmpdir -f variant -o $restmpdir/GSNAP_SNVINDEL.txt
fi

#somatic snvindels star
tmpdir="$rundir/SOMATIC_SNVINDEL/STAR/"
restmpdir="$process_dir/SOMATIC_SNVINDEL/STAR/"
if [  -d "$tmpdir" ]; then
	mkdir -p $restmpdir
	$PYTHON  $WORKFLOW_PATH/Gene_Filter.py  -g $genelist -i $tmpdir -f somatic -o $restmpdir/STAR_SOMATIC_SNVINDEL.txt
fi

#somatic snvindels gsnap
tmpdir="$rundir/SOMATIC_SNVINDEL/GSNAP/"
restmpdir="$process_dir/SOMATIC_SNVINDEL/GSNAP/"
if [  -d "$tmpdir" ]; then
	mkdir -p $restmpdir
	$PYTHON  $WORKFLOW_PATH/Gene_Filter.py  -g $genelist -i $tmpdir -f somatic -o $restmpdir/GSNAP_SOMATIC_SNVINDEL.txt
fi
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "gene list filter results took $DIFF seconds"
