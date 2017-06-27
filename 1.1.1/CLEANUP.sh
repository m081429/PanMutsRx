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
##      script to do cleanup & build HTML main document
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -r      <rundir>      -       (REQUIRED)      rundir
##      -e      <email>      -       (REQUIRED)      email
##      -i      <runid>      -       (REQUIRED)      runid
##      -h      - Display this usage/help text (No arg)
#############################################################################
EOF
exit
}
echo "Options specified: $@"

while getopts "c:r:e:i:h" OPTION; do
    case $OPTION in
        c) config=$OPTARG ;;
		r) rundir=$OPTARG ;;
        e) EMAIL=$OPTARG ;;
		i) RUNID=$OPTARG ;;
        h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$config" ] || [ -z "$rundir" ] || [ -z "$EMAIL" ] || [ -z "$RUNID" ]; then
    usage
fi

#loading the config file
source $config
source $WORKFLOW_PATH/shared_functions.sh
if [ -z $SGE_TASK_ID ]
then
	SGE_TASK_ID=1
fi

cd $rundir

#copying HTML directory
cp -R $WORKFLOW_PATH/HTML .
#loading toolinfo file
source $rundir/CONFIG/runinfo.txt
PAIRED_FASTQ=`echo "$PAIRED_FASTQ" | awk '{print tolower($0)}'`
#rm -f *_NORMAL*.txt *_TUMOR*.txt
find $rundir -name '*invalid_input'|xargs rm 2> /dev/null
###create MainHTMLPage#####

cat <<EOT > Main_Document.html
<html><head><title>mRNAseq Main Document for SOMATIC WORKFLOW RUN</title><style>
					*{
						outline:none;
					}
					body{
						font-family: Arial, "Times New Roman", sans-serif;
						font-size: 14px;
					}
					img{
						border:1px solid #666666;
						width:auto; 
						height:auto; 
					}
					p{
						font-family: Arial, "Times New Roman", sans-serif;
						font-size:14px;
						color:#5e5e5e;
						line-height:20px;
						margin-bottom:5px;
					}
					a {
						color: #0e94b6;
						text-decoration: none;
					}
					table{
						border-collapse: collapse;
						border-spacing: 0px;
						border: 1px solid black;
						text-align : center;
					}
					table td{
						font-family: Arial, "Times New Roman", sans-serif;
						font-size: 14px;
						border: 1px solid black;
						padding: 5px 5px 5px 5px;
						text-align : center;
					}
					table th{
						font-family: Arial, "Times New Roman", sans-serif;
						font-size: 16px;
						font-variant: small-caps;
						white-space:nowrap;
						border: 1px solid black;
						background-color: #edf3fe;
						padding: 5px 5px 5px 5px;
						text-align: center;
					}
					th.border, td.border {
						border-bottom: 1px solid #666666;
						border-right: 1px solid #666666;
					}
					.left {
						text-align: left;
					}
					div {
						padding: 0px 0px 10px 0px;
					}
					li.ques {
						font-weight: bold;
					}
					li.ans {
						list-style-type: none;
						padding-bottom: 10px;
					}
					.heading{
						font-family: Arial, "Times New Roman", sans-serif;
						font-size: 16px;
						font-weight: bold;
						text-align: left;
					}
					.section {
						padding: 15px 0px 0px 25px;
					}
					#pageTitle {
						font-family: Arial, "Times New Roman", sans-serif;
						font-size: 20px;
						font-weight: bold;
						text-align: center;
					}
					#top {
						position: fixed;
						right: 5px;
						z-index: 999;
						top: 40%;
						color: #FF3300;
					}
					#top a {
						color: #FF3300;
					}
					.note {
						font-style: italic;
						font-size: 12px;
					}
				</style><link rel="stylesheet" href="fancybox/source/jquery.fancybox.css?v=2.0.6" type="text/css" media="screen" />
			<link rel="stylesheet" href="fancybox/source/helpers/jquery.fancybox-buttons.css?v=1.0.2" type="text/css" media="screen" />
			<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7/jquery.min.js"></script>
			<script type="text/javascript" src="fancybox/source/jquery.fancybox.pack.js?v=2.0.6"></script>
			<script type="text/javascript" src="fancybox/source/helpers/jquery.fancybox-buttons.js?v=1.0.2"></script>

			<script type="text/javascript">
				\$(document).ready(function() {
					\$(".fancybox").fancybox({
								openEffect	: 'none',
								closeEffect	: 'none'
							});
				});
			</script>
			<script src="./HTML/sorttable.js">
			</script>
			</head><body><div id='pageTitle'><a href="HTML/SomaticCallerWorkflow.pdf" target="_blank" name="DocumentStart">SOMATIC WORKFLOW 1.0</a></div><span id="top"><a href="#DocumentStart">[ TOP ]</a></span><div id="toc">
				<span class="heading">Contents</span>
				<div class="section">
					<ul>
						<li class="toclevel-1">
							<a href="#InputConfigFiles"><span class="tocnumber">1</span>
							<span class="toctext">Configuration Files</span></a>
						</li>
						<ul>
							<li class="toclevel-2">
								<a href="#RunInfoConfigFile"><span class="tocnumber">1.1</span>
								<span class="toctext">RunInfo Config File</span></a>
							</li>
						</ul>
						<ul>
							<li class="toclevel-2">
								<a href="#ToolInfoConfigFile"><span class="tocnumber">1.2</span>
								<span class="toctext">ToolInfo Config File</span></a>
							</li>
						</ul>
						<li class="toclevel-1">
							<a href="#AnalysisPlan"><span class="tocnumber">2</span>
							<span class="toctext">Analysis Workflow</span></a>
						</li>
						<li class="toclevel-1">
							<a href="#Results"><span class="tocnumber">3</span>
							<span class="toctext">Results Summary</span></a>
						</li>
<!--						<ul>
							<li class="toclevel-2">
								<a href="#AlignmentSummary"><span class="tocnumber">3.1</span>
								<span class="toctext">Alignment Statistics</span></a>
							</li>
						</ul>
						<ul>
							<li class="toclevel-2">
								<a href="#VariantsSummary"><span class="tocnumber">3.1</span>
								<span class="toctext">Called Variants Summary</span></a>
							</li>
						</ul>-->
					</ul>
				</div>
			</div>
<div>
	<a name="InputConfigFiles" id="InputConfigFiles"></a>
	<span class="heading">I. Configuration Files: </span>
	<a name="RunInfoConfigFile" id="RunInfoConfigFile"></a>
	<div class="section"><a href="CONFIG/runinfo.txt" target="_blank">RunInfo Config File</a></div>
	<!-- <div class="section"><object data="CONFIG/runinfo.txt" type="text/plain" width="1000" style="height: 150px"></object></div> -->
	<a name="ToolInfoConfigFile" id="ToolInfoConfigFile"></a>
	<div class="section"><a href="CONFIG/toolinfo.txt" target="_blank">ToolInfo Config File</a></div>
	<!-- <div class="section"><object data="CONFIG/toolinfo.txt" type="text/plain" width="1000" style="height: 150px"></object></div> -->
</div><br/>
<div>
	<a name="AnalysisPlan" id="AnalysisPlan"></a>
	<span class="heading">II. Analysis Workflow:</span>
	<div class="section"><p align="center"><img src="HTML/eSNVIndelPipeline.jpg" width="1000"></p></div>
</div><br/><br/>
<div>
	<a name="Results" id="Results"></a>
	<span class="heading">III.  Summary:</span>
	<div class="section"><p align="center"><img src="HTML/eSNVIndel_Output.jpg" width="1000"></p></div><br/> 
	<a name="AlignmentSummary" id="AlignmentSummary"></a>
	<div class="section"><a href="HTML/samstats.txt" target="_blank">Alignment Statistics</a></div>
	<div class="section"><table border="1" style="width:100%" class="sortable"><tr>
	<th>Sample</th>
	<th>Aligner</th>
	<!-- <th>GatkPreprocess</th>-->
	<th>Total</th>
	<!-- <th>Secondary</th> -->
	<!-- <th>Supplementary</th> -->
	<th>Duplicates</th>
	<th>Mapped</th>
	<th>Paired</th>
	<th>Read1</th>
	<th>Read2</th>
	<th><div>Properly</div><div>Paired</div></th>
	<th><div>WithItself</div><div>&MatemApped</div></th>
	<th>Singletons</th>
	<th><div>WithMatemapped</div><div>ToDiffChr</div></th>
	<th><div>WithMatemapped</div><div>ToDiffChr(mapQ>=5)</div></th>
	</tr>

EOT

#generating samtools alignment stats 
#echo -e "Sample\tAligner\tGatkPreprocess\tFilename\tTotal(QC-passed+QC-failed)\tSecondary\tSupplementary\tDuplicates\tMapped\tPaired\tRead1\tRead2\tProperlyPaired\tWithItself&MatemApped\tSingletons\tWithMatemappedToDiffChr\tWithMatemappedToDiffChr(mapQ>=5)" > HTML/samstats.txt
echo -e "Sample\tAligner\tFilename\tTotal(QC-passed+QC-failed)\tSecondary\tSupplementary\tDuplicates\tMapped\tPaired\tRead1\tRead2\tProperlyPaired\tWithItself&MatemApped\tSingletons\tWithMatemappedToDiffChr\tWithMatemappedToDiffChr(mapQ>=5)" > HTML/samstats.txt
#for i in `find $rundir -name '*gatkin.bam' -o -name '*.recaliber.bam'|sort`
for i in `find $rundir -name '*RAW.bam'|sort`
do
	dirnam=`dirname $i`
	basenam=`basename $i`
	#rename star raw bam file	
	#if [[ "$basenam" =~ "STAR.gatkin.bam" ]]
	#then
	#	rm $i.bai
	#	newbasenam=`echo $basenam|sed -e 's/STAR.gatkin.bam/STAR.2STEP.RAW.bam/g'`
	#	mv $dirnam/$basenam $dirnam/$newbasenam
	#	$SAMTOOLS index $dirnam/$newbasenam
	#	i="$dirnam/$newbasenam"
	#fi
	#rename gsnap raw bam file	
	#if [[ "$basenam" =~ "GSNAP.gatkin.bam" ]]
	#then
	#	rm $i $i.bai
	#	basenam1=`echo $basenam|sed -e 's/GSNAP.gatkin.bam/GSNAP.rg.bam/g'`
	#	newbasenam=`echo $basenam|sed -e 's/GSNAP.gatkin.bam/GSNAP.RAW.bam/g'`
	#	rm $dirnam/$basenam1.bai
	#	mv $dirnam/$basenam1 $dirnam/$newbasenam
	#	$SAMTOOLS index $dirnam/$newbasenam
	#	i="$dirnam/$newbasenam"
	#fi	
	samp=`basename $i`
	if [[ "$basenam" =~ "STAR.2STEP.RAW.bam" ]]
	then
		align="STAR"	
	else
		align="GSNAP"
	fi
	name=`echo $samp|awk -F ".$align" '{print $1}'`
	#val=`$SAMTOOLS flagstat $i|cut -f1-3 -d ' '|tr '\n' '\t'|sed -s 's/\t$//g'`
	val=`cat $dirnam/$basenam.flagstat|cut -f1-3 -d ' '|tr '\n' '\t'|sed -s 's/\t$//g'`
	basenam1=`echo $basenam|sed -e 's/gatkin.bam/gatkin.splitNC.realign.recaliber.ba/g'`
	rm $dirnam/$basenam1*
	#if [[ "$samp" =~ "splitNC.realign.recaliber" ]]
	#then
	#	preprocess="YES"
			#if [[ "$DELETE_BAM_POST_GATK_PROCESS" =~ "YES" ]]
			#then
	#				j=`echo $i|sed -e 's/bam$/bai/g'`
	#				rm $i $j
			#fi	
	#else
		preprocess="NO"
	#fi
	#echo -e "$name\t$align\t$preprocess\t$samp\t$val" >> HTML/samstats.txt
	echo -e "$name\t$align\t$samp\t$val" >> HTML/samstats.txt
	rm $dirnam/$basenam.flagstat
done
#cat HTML/samstats.txt|grep -v "WithMatemappedToDiffChr"|awk -F "\t" 'BEGIN {print ""} {print "<tr>"; for(i = 1; i <= NF; i++) print "<td>" $i "</td>"; print "</tr>"} END {print ""}'  >>Main_Document.html
#cat HTML/samstats.txt|sed -e 's/ + 0//g'|grep -v "WithMatemappedToDiffChr"|awk -F "\t" 'BEGIN {print ""} {print "<tr><td><a href=\"ALIGNMENT/\" target=\"_blank\" title=\"" $4 "\">" $1 "</a></td><td>" $2 "</td><td>" $3 "</td><td>" $5 "</td>"; for(i = 8; i <= NF; i++) print "<td>" $i "</td>"; print "</tr>"} END {print ""}'  >>Main_Document.html
cat HTML/samstats.txt|sed -e 's/ + 0//g'|grep -v "WithMatemappedToDiffChr"|awk -F "\t" 'BEGIN {print ""} {print "<tr><td><a href=\"ALIGNMENT/\" target=\"_blank\" title=\"" $3 "\">" $1 "</a></td><td>" $2 "</td><td>" $4 "</td>"; for(i = 7; i <= NF; i++) print "<td>" $i "</td>"; print "</tr>"} END {print ""}'  >>Main_Document.html

cat <<EOT >> Main_Document.html
</table></div><br/>
<!--	<div class="section"><object data="HTML/samstats.html" type="text/html"  width="1200" style="height: 3000px"></object></div> -->
EOT
#generating variant caller Statistics
if [ "$CALLERS" != "NA" ]
then
	if [[ "$CALLERS" =~ "GATK" ]] || [[ "$CALLERS" =~ "BCFTOOLS" ]] || [[ "$CALLERS" =~ "VARSCAN" ]]; then
cat <<EOT >> Main_Document.html
	<a name="VariantsSummary" id="VariantsSummary"></a>
	<div class="section"><a href="HTML/VariantSummary.txt" target="_blank">Called Variant Summary</a></div>
	<div class="section"><table border="1" style="width:100%" class="sortable"><tr>
	<th>Sample</th>
	<th>Aligner</th>
	<!-- <th>GatkPreprocess</th> -->
	<!-- <th>VariantCaller</th> -->
	<th><div>Event Type</div><div>(SNP/INDEL)</div></th>
	<!-- <th><div>SOMATIC CALLS</div><div>(YES/NO)</div></th> -->
	<th><div>Number of Events</div> <div>in RawOutput</div></th>
	<th><div>Number of Events</div><div> in FilteredOutput</div></th>
</tr>
EOT


	echo -e "Sample\tAligner\tGatkPreprocess\tFilename\tVariantCaller\tEvent Type(SNP/INDEL)\tSOMATIC CALLS(YES/NO)\tNumber of Events in RawOutput\tNumber of Events in FilteredOutput" > HTML/VariantSummary.txt
		
	if [[ "$CALLERS" =~ "GATK" ]]
	then
		for i in `find $rundir/SNVINDEL -name '*.GATK.Filtered*.vcf'|sort`
		do
			name=`basename $i`
			samp=$name
			
			#samp=`basename $i|sed -s 's/.GATK.Filtered.*.vcf//g'`
			fil=`grep -v '#' $i|wc -l`
			unfil=`grep -v '#' $i|grep "PASS"|wc -l`
			if [[ "$samp" =~ "STAR.gatkin" ]]
			then
				align="STAR"	
			else
				align="GSNAP"
			fi
			name=`echo $samp|awk -F ".$align" '{print $1}'`
			if [[ "$samp" =~ "splitNC.realign.recaliber" ]]
			then
				preprocess="YES"	
			else
				preprocess="NO"
			fi
			j=`echo $i|sed -e 's/.gatkin.splitNC.realign.recaliber//g'`
			j1=`basename $j`.gz
			echo -e "$name\t$align\t$preprocess\t$samp\tGATK\tSNP/INDEL\tNO\t$fil\t$unfil" >> HTML/VariantSummary.txt
			#echo -e "<tr><td><a href=\"SNVINDEL/$align\" target=\"_blank\" title=\"$j\">$name</a></td><td>$align</td><td>$preprocess</td><td>GATK</td><td>SNP/INDEL</td><td>NO</td><td>$fil</td><td>$unfil</td></tr>" >> Main_Document.html
			echo -e "<tr><td><a href=\"SNVINDEL/$align\" target=\"_blank\" title=\"$j1\">$name</a></td><td>$align</td><td>SNP/INDEL</td><td>$fil</td><td>$unfil</td></tr>" >> Main_Document.html
			mv $i $j
		done
	fi
	#BCFTOOLS single sample
	if [[ "$CALLERS" =~ "BCFTOOLS" ]]
	then
		for i in `find $rundir/SNVINDEL -name '*.bcftools.*.vcf'|sort`
		do
			name=`basename $i`
			samp=$name
			#samp=`basename $i|sed -s 's/.bcftools.*.vcf//g'`
			fil=`grep -v '#' $i|wc -l`
			#unfil=`grep -v '#' $i|grep "PASS"|wc -l`
			unfil="NA"
			if [[ "$samp" =~ "STAR.gatkin" ]]
			then
				align="STAR"	
			else
				align="GSNAP"
			fi
			name=`echo $samp|awk -F ".$align" '{print $1}'`
			if [[ "$samp" =~ "splitNC.realign.recaliber" ]]
			then
				preprocess="YES"	
			else
				preprocess="NO"
			fi
			echo -e "$name\t$align\t$preprocess\t$samp\tBCFTOOLS\tSNP/INDEL\tNO\t$fil\t$unfil" >> HTML/VariantSummary.txt
			#echo -e "<tr><td><a href=\"SNVINDEL/$align\" target=\"_blank\" title=\"$samp\">$name</a></td><td>$align</td><td>$preprocess</td><td>BCFTOOLS</td><td>SNP/INDEL</td><td>NO</td><td>$fil</td><td>$unfil</td></tr>" >> Main_Document.html
			echo -e "<tr><td><a href=\"SNVINDEL/$align\" target=\"_blank\" title=\"$samp\">$name</a></td><td>$align</td><td>SNP/INDEL</td><td>$fil</td><td>$unfil</td></tr>" >> Main_Document.html
		done
	fi
	
	
cat <<EOT >> Main_Document.html
</table></div><br/>
EOT
	fi
	#VARSCAN Somatic 
	if [[ "$CALLERS" =~ "VARSCAN_SOMATIC" ]] || [[ "$CALLERS" =~ "STRELKA_SOMATIC" ]]; then
cat <<EOT >> Main_Document.html
	<div class="section"><a href="HTML/SomaticVariantSummary.txt" target="_blank">Called Somatic Variant Summary</a></div>
	<div class="section"><table border="1" style="width:100%" class="sortable"><tr>
	<th>Sample</th>
	<th>Aligner</th>
	<!-- <th>GatkPreprocess</th> -->
	<!-- <th>VariantCaller</th> -->
	<th><div>Event Type</div><div>(SNP/INDEL)</div></th>
	<!-- <th><div>SOMATIC CALLS</div><div>(YES/NO)</div></th> -->
	<th><div>Number of Events</div> <div>in RawOutput</div></th>
	<th><div>Number of Events</div><div> in FilteredOutput</div></th>
</tr>
EOT
	
	#STRELKA Somatic 
	if [[ "$CALLERS" =~ "STRELKA_SOMATIC" ]]
	then
		for i in `find $rundir/SOMATIC_SNVINDEL -name '*.strelka.all.somatic.snvs*.vcf'|sort`
		do
			dname=`dirname $i`
			name=`basename $i`
			samp=$name
			#samp=`basename $i|sed -s 's/.strelka.all.somatic.snvs*.vcf//g'`
			snp=`basename $i`
			snpfilter=`basename $i|sed -s 's/all.somatic.snvs.vcf/passed.somatic.snvs*.vcf/g'`
			indel=`basename $i|sed -s 's/all.somatic.snvs.vcf/all.somatic.indels*.vcf/g'`
			indelfilter=`basename $i|sed -s 's/all.somatic.snvs.vcf/passed.somatic.indels*.vcf/g'`
			countsnp=`cat $dname/$snp|grep -v "#"|wc -l`
			countindel=`cat $dname/$indel|grep -v "#"|wc -l`
			countsnpfilter=`cat $dname/$snpfilter|grep -v "#"|wc -l`
			countindelfilter=`cat $dname/$indelfilter|grep -v "#"|wc -l`
			if [[ "$samp" =~ "STAR.gatkin" ]]
			then
				align="STAR"	
			else
				align="GSNAP"
			fi
			name=`echo $samp|awk -F ".$align" '{print $1}'`
			if [[ "$samp" =~ "splitNC.realign.recaliber" ]]
			then
				preprocess="YES"	
			else
				preprocess="NO"
			fi
			samp1=`echo $samp|sed -e 's/.gatkin.splitNC.realign.recaliber//g'`.gz
			echo -e "$name\t$align\t$preprocess\t$samp1\tSTRELKA\tSNP\tNO\t$countsnp\t$countsnpfilter" >> HTML/SomaticVariantSummary.txt
			echo -e "<tr><td><a href=\"SOMATIC_SNVINDEL/$align\" target=\"_blank\" title=\"$samp1\">$name</a></td><td>$align</td><td>SNP</td><td>$countsnp</td><td>$countsnpfilter</td></tr>" >> Main_Document.html
			samp1=`echo $samp1|sed -e 's/snvs/indels/g'`
			echo -e "$name\t$align\t$preprocess\t$samp1\tSTRELKA\tINDEL\tNO\t$countindel\t$countindelfilter" >> HTML/SomaticVariantSummary.txt
			echo -e "<tr><td><a href=\"SOMATIC_SNVINDEL/$align\" target=\"_blank\" title=\"$samp1\">$name</a></td><td>$align</td><td>INDEL</td><td>$countindel</td><td>$countindelfilter</td></tr>" >> Main_Document.html
			j=`echo $i|sed -e 's/.gatkin.splitNC.realign.recaliber//g'`
			mv $i $j
			i1=`echo $i|sed -s 's/all.somatic.snvs.vcf/passed.somatic.snvs*.vcf/g'`
			j=`echo $i1|sed -e 's/.gatkin.splitNC.realign.recaliber//g'`
			mv $i1 $j
			i1=`echo $i|sed -s 's/all.somatic.snvs.vcf/all.somatic.indels*.vcf/g'`
			j=`echo $i1|sed -e 's/.gatkin.splitNC.realign.recaliber//g'`
			mv $i1 $j
			i1=`echo $i|sed -s 's/all.somatic.snvs.vcf/passed.somatic.indels*.vcf/g'`
			j=`echo $i1|sed -e 's/.gatkin.splitNC.realign.recaliber//g'`
			mv $i1 $j
			
		done
	fi

cat <<EOT >> Main_Document.html
</table></div><br/>
EOT
	fi
	#ANNOVAR 
	echo -e "Sample\tAligner\tGatkPreprocess\tFilename\tTotalNumofVariants\tdownstream\texonic\texonic"'\\x'"3bsplicing\tintergenic\tintronic\tncRNA_exonic\tncRNA_intronic\tsplicing\tupstream\tupstream"'\\x3'"bdownstream\tUTR3\tUTR5" > HTML/AnnovarSummary.txt
	if [ "$ANNOVAR_OPTION" != "NA" ] && [ "$ANNOVAR_OPTION" != "na" ] 
	then
		for i in `find $rundir/ -name '*ANNOVAR.vcf*'|sort`
		do
			name=`basename $i`
			samp=$name
			if [[ "$samp" =~ "STAR.gatkin" ]]
			then
				align="STAR"	
			else
				align="GSNAP"
			fi
			name=`echo $samp|awk -F ".$align" '{print $1}'`
			#if [[ "$samp" =~ "splitNC.realign.recaliber" ]]
			#then
				preprocess="YES"	
			#else
			#	preprocess="NO"
			#fi
			#samp=`basename $i|sed -s 's/.strelka.all.somatic.snvs*.vcf//g'`
			total=`grep -v '#' $i|wc -l`
			downstream=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "downstream"|wc -l`
			exonic=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "exonic"|wc -l`
			exonic_splicing=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "bsplicing"|wc -l`
			intergenic=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "intergenic"|wc -l`
			intronic=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "intronic"|wc -l`
			ncRNA_exonic=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "ncRNA_exonic"|wc -l`
			ncRNA_intronic=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "ncRNA_intronic"|wc -l`
			splicing=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "splicing"|wc -l`
			upstream=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "upstream"|wc -l`
			upstream_downstream=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "bdownstream"|wc -l`
			UTR3=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "UTR3"|wc -l`
			UTR5=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'Func.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "UTR5"|wc -l`
			echo -e "$name\t$align\t$preprocess\t$samp\t$total\t$downstream\t$exonic\t$exonic_splicing\t$intergenic\t$intronic\t$ncRNA_exonic\t$ncRNA_intronic\t$splicing\t$upstream\t$upstream_downstream\t$UTR3\t$UTR5">> HTML/AnnovarSummary.txt
		done

if [[ "GATK_HAPLOTYPE_CALLER_OPTION" =~ "-L" ]]
then
cat <<EOT >> Main_Document.html

	<a name="ANNOVARSummary" id="AnnovarSummary"></a>
	<div class="section"><a href="HTML/AnnovarSummary.txt" target="_blank">Variant Gene Annotation Summary</a></div>
	<div class="section"><table border="1" style="width:100%" class="sortable"><tr>
	<th>Sample</th>
	<th>Aligner</th>
	<!-- <th>GatkPreprocess</th> -->
	<th>TotalNumOfVar</th>
	<th>downstream</th>
	<th>exonic</th>
	<!--<th>exonic\x3bsplicing</th>-->
	<th>intergenic</th>
	<th>intronic</th>
	<th><div>ncRNA</div><div>exonic</div></th>
	<th><div>ncRNA</div><div>intronic</div></th>
	<th>splicing</th>
	<th>upstream</th>
	<!--<th>upstream\x3bdownstream</th>-->
	<th>UTR3</th>
	<th>UTR5</th>
	</tr>
EOT
#cat HTML/AnnovarSummary.txt|grep -v "Sample"|awk -F "\t" 'BEGIN {print ""} {print "<tr><td><a href=\"SNVINDEL/\" target=\"_blank\" title=\"" $4 "\">" $1 "</a></td><td>" $2 "</td><td>" $3 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td><td>" $7 "</td><td>" $9 "</td><td>" $10 "</td><td>" $11 "</td><td>" $12 "</td><td>" $13 "</td><td>" $14 "</td><td>" $16 "</td><td>" $17 "</td>"; print "</tr>"} END {print ""}' >>Main_Document.html
cat HTML/AnnovarSummary.txt|grep -v "Sample"|awk -F "\t" 'BEGIN {print ""} {print "<tr><td><a href=\"SNVINDEL/\" target=\"_blank\" title=\"" $4 "\">" $1 "</a></td><td>" $2 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td><td>" $7 "</td><td>" $9 "</td><td>" $10 "</td><td>" $11 "</td><td>" $12 "</td><td>" $13 "</td><td>" $14 "</td><td>" $16 "</td><td>" $17 "</td>"; print "</tr>"} END {print ""}' >>Main_Document.html
fi
cat <<EOT >> Main_Document.html
</table></div><br/>
EOT
		#ANNOVAR FUNCTION
		echo -e "Sample\tAligner\tGatkPreprocess\tFilename\tTotalNumofVariants\tframeshift_deletion\tframeshift_insertion\tnonframeshift_deletion\tnonframeshift_insertion\tnonsynonymous_SNV\tstopgain\tstoploss\tsynonymous_SNV\tunknown" > HTML/AnnovarSummaryFunc.txt
		for i in `find $rundir/ -name '*ANNOVAR.vcf*'|sort`
		do
			samp=`basename $i|sed -s 's/.strelka.all.somatic.snvs*.vcf//g'`
			if [[ "$samp" =~ "STAR." ]]
			then
				align="STAR"	
			else
				align="GSNAP"
			fi
			align1='.'$align.'.'
			name=`echo $samp|awk -F "$align1" '{print $1}'`
			#if [[ "$samp" =~ "splitNC.realign.recaliber" ]]
			#then
				preprocess="YES"	
			#else
			#	preprocess="NO"
			#fi
			total=`grep -v '#' $i|wc -l`
			frameshift_deletion=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "frameshift_deletion"|wc -l`
			frameshift_insertion=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "frameshift_insertion"|wc -l`
			nonframeshift_deletion=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "nonframeshift_deletion"|wc -l`
			nonframeshift_insertion=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "nonframeshift_insertion"|wc -l`
			nonsynonymous_SNV=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "nonsynonymous_SNV"|wc -l`
			stopgain=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "stopgain"|wc -l`
			stoploss=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "stoploss"|wc -l`
			synonymous_SNV=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "synonymous_SNV"|wc -l`
			unknown=`grep -v '#' $i|cut -f8|sed -e 's/ref/ens/g'|sed -e 's/known/ens/g'|awk -F 'ExonicFunc.ensGene=' '{print $2}'|cut -f1 -d ';'|sort|grep "unknown"|wc -l`
			echo -e "$name\t$align\t$preprocess\t$samp\t$total\t$frameshift_deletion\t$frameshift_insertion\t$nonframeshift_deletion\t$nonframeshift_insertion\t$nonsynonymous_SNV\t$stopgain\t$stoploss\t$synonymous_SNV\t$unknown">> HTML/AnnovarSummaryFunc.txt
		done	
cat <<EOT >> Main_Document.html
	<a name="ANNOVARSummaryFunc" id="AnnovarSummaryFunc"></a>
	<div class="section"><a href="HTML/AnnovarSummaryFunc.txt" target="_blank">Variant Function Impact Class Summary</a></div>
	<div class="section"><table border="1" style="width:100%" class="sortable"><tr>
	<th>Sample</th>
	<th>Aligner</th>
	<!-- <th>GatkPreprocess</th> -->
	<th>TotalNumOfVar</th>
	<th><div>frameshift</div><div>deletion</div></th>
	<th><div>frameshift</div><div>insertion</div></th>
	<th><div>nonframeshift</div><div>deletion</div></th>
	<th><div>nonframeshift</div><div>insertion</div></th>
	<th><div>nonsynonymous</div><div>SNV</div></th>
	<th>stopgain</th>
	<th>stoploss</th>
	<th><div>synonymous</div><div>SNV</div></th>
	<th>unknown</th>
	</tr>
EOT
		#cat HTML/AnnovarSummaryFunc.txt|grep -v "Sample"|awk -F "\t" 'BEGIN {print ""} {print "<tr><td><a href=\"SNVINDEL/\" target=\"_blank\" title=\"" $4 "\">" $1 "</a></td><td>" $2 "</td><td>" $3 "</td>"; for(i = 5; i <= NF; i++) print "<td>" $i "</td>"; print "</tr>"} END {print ""}'  >>Main_Document.html
		cat HTML/AnnovarSummaryFunc.txt|grep -v "Sample"|awk -F "\t" 'BEGIN {print ""} {print "<tr><td><a href=\"SNVINDEL/\" target=\"_blank\" title=\"" $4 "\">" $1 "</a></td><td>" $2 "</td>"; for(i = 5; i <= NF; i++) print "<td>" $i "</td>"; print "</tr>"} END {print ""}'  >>Main_Document.html
cat <<EOT >> Main_Document.html
</table></div><br/>
EOT
	fi
find $rundir -name '*idx'|xargs rm 2> /dev/null
#if [[ "$COMPRESS_VARIANT_OUTPUT" =~ "YES" ]] || [[ "$COMPRESS_VARIANT_OUTPUT" =~ "yes" ]]
#then
	#find $rundir -name '*vcf'|xargs $HTSDIR/bgzip 2> /dev/null
for i in `find $rundir -name '*vcf'`
do
	$HTSDIR/bgzip $i  2> /dev/null
	$HTSDIR/tabix -p vcf $i.gz  2> /dev/null
done
	
	find $rundir -name '*snp'|xargs gzip 2> /dev/null
	find $rundir -name '*indel'|xargs gzip 2> /dev/null
	find $rundir -name '*filter'|xargs gzip 2> /dev/null
	find $rundir -name 'sambamba-pid*'|xargs rmdir 2> /dev/null
	find $rundir -name '_STARtmp'|xargs rmdir 2> /dev/null
	find $rundir -name '*.STAR.process_dir'|xargs rmdir 2> /dev/null
	find $rundir -name '*.so'|xargs rm 2> /dev/null
#fi 	
cat <<EOT >> Main_Document.html
	</table></div><br/>
EOT
fi

#STAR FUSION
if [[ "$CALLERS" =~ "STAR_FUSION" ]]
then
cat <<EOT >> Main_Document.html
	<a name="StarFusionSummary" id="StarFusionSummary"></a>
	<div class="section">StarFusion Summary</div>
	<div class="section"><table border="1" style="width:100%" class="sortable"><tr>
	<th>Sample</th>
	<th>RawFusions</th>
	<th>FilteredFusions</th>
	<th>RawCounts(UNIQUE)</th>
	<th>FilteredCounts(UNIQUE)</th>
	</tr>
EOT
	# mkdir -p $rundir/FUSIONS
	# for i in `find $rundir/ALIGNMENT -name 'star-fusion.fusion_candidates.final.abridged.FFPM'|sort`
	# do
		# sampname=`dirname $i|xargs dirname|xargs basename|sed -s 's/.STAR.process_dir_pass2//g'`
		# count=`cat $i|wc -l`
		# count=$((count -1))
		# targ=`echo $i|awk -F "$rundir" '{print "."$2}'`
		# cp $i $rundir/FUSIONS/$sampname.star_fusion.txt	
		# n1=`head -1 $rundir/FUSIONS/$sampname.star_fusion.txt|tr '\t' '\n'|grep -n "J_FFPM"|cut -f1 -d ':'`
		# n2=`head -1 $rundir/FUSIONS/$sampname.star_fusion.txt|tr '\t' '\n'|grep -n "S_FFPM"|cut -f1 -d ':'`
		# n3=`head -1 $rundir/FUSIONS/$sampname.star_fusion.txt|tr '\t' '\n'|grep -n "LargeAnchorSupport"|cut -f1 -d ':'`
		# head -1  $rundir/FUSIONS/$sampname.star_fusion.txt > $rundir/FUSIONS/$sampname.star_fusion_filtered.txt
		# awk -F "\t" -v x=$n1 -v y=$n2 -v z=$n3 '{if($x+$y > 0.1 && $z=="YES_LDAS")print $0}' $rundir/FUSIONS/$sampname.star_fusion.txt >> $rundir/FUSIONS/$sampname.star_fusion_filtered.txt
		# fcount=`cat $rundir/FUSIONS/$sampname.star_fusion_filtered.txt|wc -l`
		# fcount=$((fcount -1))
		# echo -e "<tr><td>$sampname</td><td><a href=\"FUSIONS/$sampname.star_fusion.txt\" target=\"_blank\" title=\"$sampname\">Raw</a></td><td><a href=\"FUSIONS/$sampname.star_fusion_filtered.txt\" target=\"_blank\" title=\"$sampname\">Filtered</a></td><td>$count</td><td>$fcount</td></tr>">> Main_Document.html
		# tar -zcvf $rundir/ALIGNMENT/STAR/$sampname.STARFUSIONDIR.tar.gz $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2
		# rm $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2/*
		# rm $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2/*/*
		# rm $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2/*/*/*
		# rmdir $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2/*/*
		# rmdir $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2/*
		# rmdir $rundir/ALIGNMENT/STAR/$sampname.STAR.process_dir_pass2/
	# done
for i in `find $rundir/FUSIONS -name '*.star_fusion.txt'|sort`
do
	sampname=`echo $i|xargs basename|sed -s 's/.star_fusion.txt//g'`
	count=`cat $i|wc -l`
	count=$((count -1))
	count_unique=`cut -f1 $i|sort|uniq|wc -l`
	count_unique=$((count_unique -1))
	fil=`echo $i|sed -s 's/star_fusion.txt/star_fusion_filtered.txt/g'`
	fcount=`cat $fil|wc -l`
	fcount=$((fcount -1))
	fcount_unique=`cut -f1 $fil|sort|uniq|wc -l`
	fcount_unique=$((fcount_unique -1))
	echo -e "<tr><td>$sampname</td><td><a href=\"FUSIONS/$sampname.star_fusion.txt\" target=\"_blank\" title=\"$sampname\">Raw</a></td><td><a href=\"FUSIONS/$sampname.star_fusion_filtered.txt\" target=\"_blank\" title=\"$sampname\">Filtered</a></td><td>$count($count_unique)</td><td>$fcount($fcount_unique)</td></tr>">> Main_Document.html
done

#for i in `find $rundir/FUSIONS -name '*.star_fusion.GENE_FILTER.txt'|sort`
#do
#	sampname=`echo $i|xargs basename|sed -s 's/.star_fusion.GENE_FILTER.txt//g'`
#	samename1=$sampname'.GENE_FILTER'
#	count=`cat $i|wc -l`
#	count=$((count -1))
#	fil=`echo $i|sed -s 's/.star_fusion/.star_fusion_filtered/g'`
#	fcount=`cat $fil|wc -l`
#	fcount=$((fcount -1))
#	echo -e "<tr><td>$sampname1</td><td><a href=\"FUSIONS/$sampname.star_fusion.GENE_FILTER.txt\" target=\"_blank\" title=\"$sampname1\">Raw</a></td><td><a href=\"FUSIONS/$sampname.star_fusion_filtered.GENE_FILTER.txt\" target=\"_blank\" title=\"$sampname\">Filtered</a></td><td>$count</td><td>$fcount</td></tr>">> Main_Document.html
#done		
fi	
cat <<EOT >> Main_Document.html
</table></div><br/>
EOT

#FEATURE COUNTS
if [[ "$CALLERS" =~ "FEATURECOUNTS" ]]
then
cat <<EOT >> Main_Document.html
	<a name="FeatureCountsSummary" id="FeatureCountsSummary"></a>
	<div class="section">FeatureCounts Summary</div>
	<div class="section">
	<table border="1" style="width:100%" class="sortable">
	<tr>
	<th>Aligner</th>
	<th>GeneCounts</th>
	</tr>
EOT
	if [[ "$ALIGNERS" =~ "STAR" ]]
	then
		#RAW COUNTS
		fil=`cat $rundir/CONFIG/STAR_NORMAL_UNIQUE.txt|head -1`
		fil=`echo $fil|sed -s 's/.bam/.counts/g'`
		echo -e "Geneid" > $rundir/star_featurecounts.txt
		grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/star_featurecounts.txt
		mkdir -p $rundir/GENECOUNTS/STAR
		mv $rundir/star_featurecounts.txt $rundir/GENECOUNTS/STAR/star_featurecounts.txt
		for i in `cat $rundir/CONFIG/STAR_NORMAL_UNIQUE.txt|sort`
		do
			i=`echo $i|sed -s 's/.bam/.counts/g'`
			raw=`basename $i|sed -s 's/.gatkin.counts/.RAW/g'`
			#rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
			total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
			#echo -e "$raw\t$rpkm" > $i.final
			echo -e "$raw" > $i.final
			#grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7"\t"(1000000000*$7/(x*$6))}' >> $i.final
			grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7}' >> $i.final
			paste -d "\t" $rundir/GENECOUNTS/STAR/star_featurecounts.txt $i.final > $rundir/featurecounts.tmp
			mv $rundir/featurecounts.tmp $rundir/GENECOUNTS/STAR/star_featurecounts.txt
			rm $i.final
		done
		echo -e "<tr><td>STAR</td><td><a href=\"GENECOUNTS/STAR/star_featurecounts.txt\" target=\"_blank\" title=\"star_featurecounts\">STAR_GENECOUNTS</a></td></tr>">> Main_Document.html
		#RPKM COUNTS
		fil=`cat $rundir/CONFIG/STAR_NORMAL_UNIQUE.txt|head -1`
		fil=`echo $fil|sed -s 's/.bam/.counts/g'`
		echo -e "Geneid" > $rundir/star_featurecounts_rpkm.txt
		grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/star_featurecounts_rpkm.txt
		mkdir -p $rundir/GENECOUNTS/STAR
		mv $rundir/star_featurecounts_rpkm.txt $rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.txt
		for i in `cat $rundir/CONFIG/STAR_NORMAL_UNIQUE.txt|sort`
		do
			i=`echo $i|sed -s 's/.bam/.counts/g'`
			#raw=`basename $i|sed -s 's/.gatkin.counts/.RAW/g'`
			rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
			total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
			#echo -e "$raw\t$rpkm" > $i.final
			echo -e "$rpkm" > $i.final
			#grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7"\t"(1000000000*$7/(x*$6))}' >> $i.final
			grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print (1000000000*$7/(x*$6))}' >> $i.final
			paste -d "\t" $rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.txt $i.final > $rundir/featurecounts.tmp
			mv $rundir/featurecounts.tmp $rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.txt
			rm $i $i.summary $i.final
		done
		echo -e "<tr><td>STAR</td><td><a href=\"GENECOUNTS/STAR/star_featurecounts_rpkm.txt\" target=\"_blank\" title=\"star_featurecounts\">STAR_GENECOUNTS_NORMALIZED</a></td></tr>">> Main_Document.html
		#Star tumor feature counts
		#RAW COUNTS
		if [ "$PAIRED_FASTQ" != "na" ]
		then
			fil=`cat $rundir/CONFIG/STAR_TUMOR.txt|head -1`
			fil=`echo $fil|sed -s 's/.bam/.counts/g'`
			echo -e "Geneid" > $rundir/star_featurecounts_tumor.txt
			grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/star_featurecounts_tumor.txt
			mkdir -p $rundir/GENECOUNTS/STAR
			mv $rundir/star_featurecounts_tumor.txt $rundir/GENECOUNTS/STAR/star_featurecounts_tumor.txt
			for i in `cat $rundir/CONFIG/STAR_TUMOR.txt|sort`
			do
				i=`echo $i|sed -s 's/.bam/.counts/g'`
				raw=`basename $i|sed -s 's/.gatkin.counts/.RAW/g'`
				#rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
				total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
				#echo -e "$raw\t$rpkm" > $i.final
				echo -e "$raw" > $i.final
				#grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7"\t"(1000000000*$7/(x*$6))}' >> $i.final
				grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7}' >> $i.final
				paste -d "\t" $rundir/GENECOUNTS/STAR/star_featurecounts_tumor.txt $i.final > $rundir/featurecounts_tumor.tmp
				mv $rundir/featurecounts_tumor.tmp $rundir/GENECOUNTS/STAR/star_featurecounts_tumor.txt
				rm $i.final
			done
			cut -f2- $rundir/GENECOUNTS/STAR/star_featurecounts_tumor.txt > $rundir/GENECOUNTS/STAR/star_featurecounts_tumor1.txt
			paste 	$rundir/GENECOUNTS/STAR/star_featurecounts.txt $rundir/GENECOUNTS/STAR/star_featurecounts_tumor1.txt > $rundir/GENECOUNTS/STAR/star_featurecounts_tumor.txt
			mv $rundir/GENECOUNTS/STAR/star_featurecounts_tumor.txt $rundir/GENECOUNTS/STAR/star_featurecounts.txt
			rm $rundir/GENECOUNTS/STAR/star_featurecounts_tumor1.txt
			#echo -e "<tr><td>STAR</td><td><a href=\"GENECOUNTS/STAR/star_featurecounts_tumor.txt\" target=\"_blank\" title=\"star_featurecounts_tumor\">STAR_GENECOUNTS_TUMOR</a></td></tr>">> Main_Document.html
		fi
		#if [ "$GENE_FILTER" != "NA" ] && [ "$GENE_FILTER" != "na" ] 
		#then
		#	$PYTHON  $WORKFLOW_PATH/Gene_Filter_exp.py -g $GENE_FILTER -i $rundir/GENECOUNTS/STAR/star_featurecounts.txt -o $rundir/GENECOUNTS/STAR/star_featurecounts.GENE_FILTER.txt
		#	check_variable $? $0 $sampname "GENE FILTER GENE EXP step" $EMAIL $RUNID
		#	echo -e "<tr><td>STAR</td><td><a href=\"GENECOUNTS/STAR/star_featurecounts.GENE_FILTER.txt\" target=\"_blank\" title=\"star_featurecounts\">STAR_GENECOUNTS_GENEFILTER</a></td></tr>">> Main_Document.html
		#fi
		#RPKM COUNTS
		if [ "$PAIRED_FASTQ" != "na" ]
		then
			fil=`cat $rundir/CONFIG/STAR_TUMOR.txt|head -1`
			fil=`echo $fil|sed -s 's/.bam/.counts/g'`
			echo -e "Geneid" > $rundir/star_featurecounts_tumor_rpkm.txt
			grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/star_featurecounts_tumor_rpkm.txt
			mkdir -p $rundir/GENECOUNTS/STAR
			mv $rundir/star_featurecounts_tumor_rpkm.txt $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt
			for i in `cat $rundir/CONFIG/STAR_TUMOR.txt|sort`
			do
				i=`echo $i|sed -s 's/.bam/.counts/g'`
				rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
				total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
				echo -e "$rpkm" > $i.final
				grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print (1000000000*$7/(x*$6))}' >> $i.final
				paste -d "\t" $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt $i.final > $rundir/featurecounts_tumor.tmp
				mv $rundir/featurecounts_tumor.tmp $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt
				rm $i $i.summary $i.final
			done
			cut -f2- $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt > $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm1.txt
			paste 	$rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.txt $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm1.txt > $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt
			mv $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt $rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.txt
			rm $rundir/GENECOUNTS/STAR/star_featurecounts_tumor_rpkm1.txt
			#echo -e "<tr><td>STAR</td><td><a href=\"GENECOUNTS/STAR/star_featurecounts_tumor_rpkm.txt\" target=\"_blank\" title=\"star_featurecounts_tumor\">STAR_GENECOUNTS_TUMOR_NORMALIZED</a></td></tr>">> Main_Document.html
		fi
		#if [ "$GENE_FILTER" != "NA" ] && [ "$GENE_FILTER" != "na" ] 
		#then
		#	$PYTHON  $WORKFLOW_PATH/Gene_Filter_exp.py -g $GENE_FILTER -i $rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.txt -o $rundir/GENECOUNTS/STAR/star_featurecounts_rpkm.GENE_FILTER.txt
		#	check_variable $? $0 $sampname "GENE FILTER GENE EXP step" $EMAIL $RUNID
		#	echo -e "<tr><td>STAR</td><td><a href=\"GENECOUNTS/STAR/star_featurecounts_rpkm.GENE_FILTER.txt\" target=\"_blank\" title=\"star_featurecounts\">STAR_GENECOUNTS_NORMALIZED_GENEFILTER</a></td></tr>">> Main_Document.html
		#fi	
	fi
	if [[ "$ALIGNERS" =~ "GSNAP" ]]
	then
		#RAW COUNTS
		fil=`cat $rundir/CONFIG/GSNAP_NORMAL_UNIQUE.txt|head -1`
		fil=`echo $fil|sed -s 's/.bam/.counts/g'`
		echo -e "Geneid" > $rundir/gsnap_featurecounts.txt
		grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/gsnap_featurecounts.txt
		mkdir -p $rundir/GENECOUNTS/GSNAP
		mv $rundir/gsnap_featurecounts.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.txt
		for i in `cat $rundir/CONFIG/GSNAP_NORMAL_UNIQUE.txt|sort`
		do
			i=`echo $i|sed -s 's/.bam/.counts/g'`
			raw=`basename $i|sed -s 's/.gatkin.counts/.RAW/g'`
			#rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
			total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
			#echo -e "$raw\t$rpkm" > $i.final
			echo -e "$raw" > $i.final
			#grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7"\t"(1000000000*$7/(x*$6))}' >> $i.final
			grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7}' >> $i.final
			paste -d "\t" $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.txt $i.final > $rundir/featurecounts.tmp
			mv $rundir/featurecounts.tmp $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.txt
			rm $i.final
		done
		echo -e "<tr><td>GSNAP</td><td><a href=\"GENECOUNTS/GSNAP/gsnap_featurecounts.txt\" target=\"_blank\" title=\"gsnap_featurecounts\">GSNAP_GENECOUNTS</a></td></tr>">> Main_Document.html
		#RPKM COUNTS
		fil=`cat $rundir/CONFIG/GSNAP_NORMAL_UNIQUE.txt|head -1`
		fil=`echo $fil|sed -s 's/.bam/.counts/g'`
		echo -e "Geneid" > $rundir/gsnap_featurecounts_rpkm.txt
		grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/gsnap_featurecounts_rpkm.txt
		mkdir -p $rundir/GENECOUNTS/GSNAP
		mv $rundir/gsnap_featurecounts_rpkm.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt
		for i in `cat $rundir/CONFIG/GSNAP_NORMAL_UNIQUE.txt|sort`
		do
			i=`echo $i|sed -s 's/.bam/.counts/g'`
			rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
			total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
			echo -e "$rpkm" > $i.final
			grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print (1000000000*$7/(x*$6))}' >> $i.final
			paste -d "\t" $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt $i.final > $rundir/featurecounts.tmp
			mv $rundir/featurecounts.tmp $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt
			rm $i $i.summary $i.final
		done
		echo -e "<tr><td>GSNAP</td><td><a href=\"GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt\" target=\"_blank\" title=\"gsnap_featurecounts\">GSNAP_GENECOUNTS_NORMALIZED</a></td></tr>">> Main_Document.html
		#Gsnap tumor feature counts
		#RAW COUNTS
		if [ "$PAIRED_FASTQ" != "na" ]
		then
			fil=`cat $rundir/CONFIG/GSNAP_TUMOR.txt|head -1`
			fil=`echo $fil|sed -s 's/.bam/.counts/g'`
			echo -e "Geneid" > $rundir/gsnap_featurecounts_tumor.txt
			grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/gsnap_featurecounts_tumor.txt
			mkdir -p $rundir/GENECOUNTS/GSNAP
			mv $rundir/gsnap_featurecounts_tumor.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt
			for i in `cat $rundir/CONFIG/GSNAP_TUMOR.txt|sort`
			do
				i=`echo $i|sed -s 's/.bam/.counts/g'`
				raw=`basename $i|sed -s 's/.gatkin.counts/.RAW/g'`
				#rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
				total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
				#echo -e "$raw\t$rpkm" > $i.final
				echo -e "$raw" > $i.final
				#grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7"\t"(1000000000*$7/(x*$6))}' >> $i.final
				grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print $7}' >> $i.final
				paste -d "\t" $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt $i.final > $rundir/featurecounts_tumor.tmp
				mv $rundir/featurecounts_tumor.tmp $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt
				rm $i.final
			done
			cut -f2- $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt > $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor1.txt
			paste 	$rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor1.txt > $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt
			mv $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.txt
			rm $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor1.txt
			#echo -e "<tr><td>GSNAP</td><td><a href=\"GENECOUNTS/GSNAP/gsnap_featurecounts_tumor.txt\" target=\"_blank\" title=\"gsnap_featurecounts_tumor\">GSNAP_GENECOUNTS_TUMOR</a></td></tr>">> Main_Document.html
		fi
		#if [ "$GENE_FILTER" != "NA" ] && [ "$GENE_FILTER" != "na" ] 
		#then
		#	$PYTHON  $WORKFLOW_PATH/Gene_Filter_exp.py -g $GENE_FILTER -i $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.txt -o $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts.GENE_FILTER.txt
		#	check_variable $? $0 $sampname "GENE FILTER GENE EXP step" $EMAIL $RUNID
		#	echo -e "<tr><td>GSNAP</td><td><a href=\"GENECOUNTS/GSNAP/gsnap_featurecounts.GENE_FILTER.txt\" target=\"_blank\" title=\"gsnap_featurecounts\">GSNAP_GENECOUNTS_GENEFILTER</a></td></tr>">> Main_Document.html
		#fi
		#RPKM COUNTS
		if [ "$PAIRED_FASTQ" != "na" ]
		then
			fil=`cat $rundir/CONFIG/GSNAP_TUMOR.txt|head -1`
			fil=`echo $fil|sed -s 's/.bam/.counts/g'`
			echo -e "Geneid" > $rundir/gsnap_featurecounts_tumor_rpkm.txt
			grep -v "Geneid" $fil|grep -v "Program"|cut -f1 >> $rundir/gsnap_featurecounts_tumor_rpkm.txt
			mkdir -p $rundir/GENECOUNTS/GSNAP
			mv $rundir/gsnap_featurecounts_tumor_rpkm.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt
			for i in `cat $rundir/CONFIG/GSNAP_TUMOR.txt|sort`
			do
				i=`echo $i|sed -s 's/.bam/.counts/g'`
				rpkm=`basename $i|sed -s 's/.gatkin.counts/.RPKM/g'`
				total=`grep -v "Status" $i.summary|cut -f2|paste -sd+ -|bc`
				echo -e "$rpkm" > $i.final
				grep -v "Geneid" $i|grep -v "Program"|awk -F "\t" -v x=$total '{print (1000000000*$7/(x*$6))}' >> $i.final
				paste -d "\t" $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt $i.final > $rundir/featurecounts_tumor.tmp
				mv $rundir/featurecounts_tumor.tmp $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt
				rm $i $i.summary $i.final
			done
			cut -f2- $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt > $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm1.txt
			paste 	$rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm1.txt > $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt
			mv $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt
			rm $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm1.txt
			#echo -e "<tr><td>GSNAP</td><td><a href=\"GENECOUNTS/GSNAP/gsnap_featurecounts_tumor_rpkm.txt\" target=\"_blank\" title=\"gsnap_featurecounts_tumor\">GSNAP_GENECOUNTS_TUMOR_NORMALIZED</a></td></tr>">> Main_Document.html
		fi
		#if [ "$GENE_FILTER" != "NA" ] && [ "$GENE_FILTER" != "na" ] 
		#then
		#	$PYTHON  $WORKFLOW_PATH/Gene_Filter_exp.py -g $GENE_FILTER -i $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.txt -o $rundir/GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.GENE_FILTER.txt
		#	check_variable $? $0 $sampname "GENE FILTER GENE EXP step" $EMAIL $RUNID
		#	echo -e "<tr><td>GSNAP</td><td><a href=\"GENECOUNTS/GSNAP/gsnap_featurecounts_rpkm.GENE_FILTER.txt.txt\" target=\"_blank\" title=\"gsnap_featurecounts\">GSNAP_GENECOUNTS_NORMALIZED_GENEFILTER</a></td></tr>">> Main_Document.html
		#fi
	fi
cat <<EOT >> Main_Document.html
	</table></div><br/>
EOT
fi

mkdir 	$rundir/LOG/CONFIG
mv $rundir/CONFIG/* $rundir/LOG/CONFIG
cp $rundir/LOG/CONFIG/runinfo.txt $rundir/CONFIG
cp $rundir/LOG/CONFIG/toolinfo.txt $rundir/CONFIG
cp $rundir/LOG/CONFIG/FASTQ_*.txt $rundir/CONFIG



cat <<EOT >> Main_Document.html
</body></html>
EOT

echo "Results Directory:$rundir HTML:$rundir/Main_Document.html" |mail -s  "WorkFlow:Somatic Caller workflow run  Status:Completed  RUNID:$runid directory:$rundir " $EMAIL
