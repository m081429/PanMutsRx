#!/usr/local/biotools/python/3.4.3/bin/python3
__author__ = "Naresh Prodduturi"
__email__ = "prodduturi.naresh@mayo.edu"
__status__ = "Dev"

import os
import argparse
import sys
import pwd
import time
import subprocess
import re
import shutil	
	
def input_file_validity(file):
	'''Validates the input files'''
	if os.path.exists(file)==False:
		raise argparse.ArgumentTypeError( '\nERROR:Path:\n'+file+':Does not exist')
	if os.path.isfile(file)==False:
		raise argparse.ArgumentTypeError( '\nERROR:File expected:\n'+file+':is not a file')
	if os.access(file,os.R_OK)==False:
		raise argparse.ArgumentTypeError( '\nERROR:File:\n'+file+':no read access ')
	return file


def shell_cmd(cmd):
	cmd = re.sub('\s+', ' ', cmd).strip()
	cmd = cmd.split(" ")
	m = subprocess.Popen(cmd, stdout=subprocess.PIPE)
	stdout, stderr = m.communicate()
	exitCode = m.returncode
	return exitCode

def sge_submit(cmd):
	cmd = re.sub('\s+', ' ', cmd).strip()
	if not ("QSUB" in path_dict) or path_dict["QSUB"] == "NA" or path_dict["QSUB"] == "na" or os.path.exists(path_dict["QSUB"]) == False:
		if '-t' in cmd:
			cmd=cmd.split('-t')
			cmd=cmd[1]
			cmd = cmd.split(':1')
			cmd[1] = cmd[1].strip()
			cmd[0] = cmd[0].strip()
			cmd[0]=cmd[0].replace('1-','')
			#print(cmd[0]+' s '+cmd[1])
			num_jobs=int(cmd[0])
			command=cmd[1]
			for i in range(1, num_jobs + 1):
				cmd_final = path_dict["SH"] + ' ' + command+ " -n " + str(i)
				#print("Fin "+cmd_final)
				exitcode=shell_cmd(cmd_final)
				if exitcode != 0:
					print("command failed "+cmd_final)
					sys.exit(1)
		else:
			cmd = cmd.split('-M')
			cmd[1] = cmd[1].strip()
			tcmd = cmd[1].split(' ')
			tcmd.pop(0)
			command=str.join(" ",tcmd)
			cmd_final = path_dict["SH"] + ' ' + command
			#print("Fin " + cmd_final)
			exitcode = shell_cmd(cmd_final)
			if exitcode != 0:
				print("command failed " + cmd_final)
				sys.exit(1)
		return "1"
	else:
		#print(cmd)
		cmd=cmd.split(" ")
		m = subprocess.Popen(cmd, stdout=subprocess.PIPE)
		stdout, stderr = m.communicate()
		exitCode = m.returncode
		stdout=str(stdout)
		stdout=stdout.split(" ")
		jobid=stdout[2].split(".")
		return jobid[0]
	
def create_dir(f):
	'''Checks if a directory is present or not and creates one if not present'''
	if not os.path.exists(f):
		os.makedirs(f)

def gsnap_align():
	'''Gsnap Align'''
	'''Create GSNAP Directory'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP")
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL_UNIQUE.txt', mode='wt')
	temp_dict = {}
	fastq_normal_dict_uniq=0
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
			fastq_normal_dict_uniq+=1
	fobj.close()
	myfile.close()
	
	'''Create GSNAP ALIGNED Directory'''
	#create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP")
	#cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4"+" -l h_vmem="+path_dict["GSNAP_MEM"]+" -q "+path_dict["GSNAP_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GSNAP.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4"+" -l h_vmem="+path_dict["GSNAP_MEM"]+" -q "+path_dict["GSNAP_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GSNAP.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	
	'''Checking for Tumor fastq files'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		'''Create GSNAP SOMATIC Directory'''
		#create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP")
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4"+" -l h_vmem="+path_dict["GSNAP_MEM"]+" -q "+path_dict["GSNAP_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GSNAP.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
		
def star_align():
	'''Star Align'''
	'''Create STAR Directory'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR")
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL_UNIQUE.txt', mode='wt')
	temp_dict = {}
	fastq_normal_dict_uniq=0
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
			fastq_normal_dict_uniq+=1
	fobj.close()
	myfile.close()
	
	'''Create GSNAP ALIGNED Directory'''
	#create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR")
	#cmd=path_dict["QSUB"]+" -m a -j y -pe threaded 4"+" -l h_vmem="+path_dict["STAR_MEM"]+" -q "+path_dict["STAR_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STAR.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	cmd=path_dict["QSUB"]+" -m a -j y -pe threaded 4"+" -l h_vmem="+path_dict["STAR_MEM"]+" -q "+path_dict["STAR_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STAR.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Checking for Tumor fastq files'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		'''Create GSNAP SOMATIC Directory'''
		#create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR")
		cmd=path_dict["QSUB"]+" -m a -j y -pe threaded 4"+" -l h_vmem="+path_dict["STAR_MEM"]+" -q "+path_dict["STAR_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STAR.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()

def gsnap_gatk_preprocess():
	'''Gsnap GATK Preprocess'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	if path_dict["CALLERS"].find("OPOSSUM") != -1:
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"OPOSSUM.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	else:
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_PREPROCESS_GSNAP.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Tumor sample GSNAP GATK PREPROCESS'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		if path_dict["CALLERS"].find("OPOSSUM") != -1:
			cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"OPOSSUM.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		else:
			cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_PREPROCESS_GSNAP.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()

def gsnap_featurecount():
	'''Gsnap Feature count'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE_FEATURE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1
			file=file.replace('gatkin.bam','RAW.bam')			
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_FEATURECOUNT"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"FEATURECOUNTS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE_FEATURE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Tumor sample GSNAP Feature Count'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		'''Renaming files'''
		fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt')
		myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_UNIQUE_FEATURE.txt', mode='wt')
		
		for file in fobj:
			file=file.strip()
			file=file.replace('gatkin.bam','RAW.bam')	
			myfile.write(file+"\n")
		fobj.close()
		myfile.close()
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_FEATURECOUNT"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"FEATURECOUNTS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_UNIQUE_FEATURE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()

def Star_gatk_preprocess():
	'''Star GATK Preprocess'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_UNIQUE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	if path_dict["CALLERS"].find("OPOSSUM") != -1:
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"OPOSSUM.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	else:
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_PREPROCESS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Star GATK tumor sample preprocess'''
	global fastq_tumor_dict
	
	
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		
		'''Creating input file for GSNAP Somatic preprocess'''
		if path_dict["CALLERS"].find("OPOSSUM") != -1:
			cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"OPOSSUM.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		else:
			cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_PREPROCESS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()

def Star_featurecount():
	'''Star Feature Count'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_UNIQUE_FEATURE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1
			file=file.replace('gatkin.bam','2STEP.RAW.bam')	
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_FEATURECOUNT"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"FEATURECOUNTS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_UNIQUE_FEATURE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Star GATK tumor Star Feature Count'''
	global fastq_tumor_dict


	
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		'''Renaming files'''
		fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR.txt')
		myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_UNIQUE_FEATURE.txt', mode='wt')
		
		for file in fobj:
			file=file.strip()
			file=file.replace('gatkin.bam','2STEP.RAW.bam')	
			myfile.write(file+"\n")
		fobj.close()
		myfile.close()	
		cmd=path_dict["QSUB"]+" -m a -j y  -pe threaded 4 "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_FEATURECOUNT"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"FEATURECOUNTS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_UNIQUE_FEATURE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
def Star_fusion_caller():
	'''Star Fusion Calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR")
	
	
	'''Normal Fastq Files'''
	cmd=path_dict["QSUB"]+" -m a -j y -pe threaded 4"+" -l h_vmem="+path_dict["STAR_MEM"]+" -q "+path_dict["STAR_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_FUSION"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STAR_FUSION.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Checking for Tumor fastq files'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		'''Create GSNAP SOMATIC Directory'''
		#create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR")
		cmd=path_dict["QSUB"]+" -m a -j y -pe threaded 4"+" -l h_vmem="+path_dict["STAR_MEM"]+" -q "+path_dict["STAR_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_FUSION"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STAR_FUSION.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()

def gsnap_gatk_caller():
	'''Gsnap gatk calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK_UNIQUE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_CALLER.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Gsnap gatk tumor sample calling'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_TUMOR_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_CALLER.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
def Star_gatk_caller():
	'''Star gatk calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK_UNIQUE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_CALLER.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Star gatk tumor sample calling'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		
		'''Create STAR SOMATIC Directory'''
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["GATK_MEM"]+" -q "+path_dict["GATK_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_TUMOR_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"GATK_CALLER.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()

def gsnap_bcftools_caller():
	'''Gsnap varscan calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["BCFTOOLS_MEM"]+" -q "+path_dict["BCFTOOLS_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_BCFTOOLS_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"BCFTOOLS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''
	if path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"].lower() != "no":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["BCFTOOLS_MEM"]+" -q "+path_dict["BCFTOOLS_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_BCFTOOLS_CALLING_NOGATK"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"BCFTOOLS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
	'''Gsnap varscan tumor sample calling'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["BCFTOOLS_MEM"]+" -q "+path_dict["BCFTOOLS_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_BCFTOOLS_TUMOR_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"BCFTOOLS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
		'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''
		if path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"].lower() != "no":
			cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["BCFTOOLS_MEM"]+" -q "+path_dict["BCFTOOLS_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_BCFTOOLS_TUMOR_CALLING_NOGATK"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"BCFTOOLS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
			print(cmd)
			jid=sge_submit(cmd)
			myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
			myfile.write(jid+":"+cmd+"\n")
			myfile.close()
		
def Star_bcftools_caller():
	'''Star gatk calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	'''Removing duplicates'''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK.txt')
	myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK_UNIQUE.txt', mode='wt')
	temp_dict = {}
	for file in fobj:
		file=file.strip()
		if file not in temp_dict:
			temp_dict[file]=1	
			myfile.write(file+"\n")
	fobj.close()
	myfile.close()
	
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["BCFTOOLS_MEM"]+" -q "+path_dict["BCFTOOLS_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_BCFTOOLS_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"BCFTOOLS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	'''Star gatk tumor sample calling'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		
		'''Create STAR SOMATIC Directory'''
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["BCFTOOLS_MEM"]+" -q "+path_dict["BCFTOOLS_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_BCFTOOLS_TUMOR_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"BCFTOOLS.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
def gsnap_varscan_single():
	'''Gsnap varscan calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_VARSCAN_SINGLE_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SINGLESAMPLE.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
	
	'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''
	if path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"].lower() != "no":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_VARSCAN_SINGLE_CALLING_NOGATK"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SINGLESAMPLE.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
	'''Gsnap varscan tumor sample calling'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_VARSCAN_SINGLE_TUMOR_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SINGLESAMPLE.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
		'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''
		if path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"].lower() != "no":
			cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_VARSCAN_SINGLE_TUMOR_CALLING_NOGATK"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SINGLESAMPLE.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
			print(cmd)
			jid=sge_submit(cmd)
			myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
			myfile.write(jid+":"+cmd+"\n")
			myfile.close()
				
def Star_varscan_single():
	'''Star varscan calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	global fastq_normal_dict_uniq
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_VARSCAN_SINGLE_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict_uniq)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SINGLESAMPLE.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK_UNIQUE.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	
		
	'''Star varscan tumor sample calling'''
	global fastq_tumor_dict
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_VARSCAN_SINGLE_TUMOR_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_tumor_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SINGLESAMPLE.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
			
def gsnap_varscan_somatic():
	'''Gsnap varscan Somatic calling calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_VARSCAN_SOMATIC_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+","+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SOMATIC.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK.txt'+" -s "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''
	if path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"].lower() != "no":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_VARSCAN_SOMATIC_CALLING_NOGATK"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+","+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SOMATIC.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL.txt'+" -s "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
					
def Star_varscan_somatic():
	'''Star varscan Somatic calling calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["VARSCAN_MEM"]+" -q "+path_dict["VARSCAN_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_VARSCAN_SOMATIC_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+","+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"VARSCAN_SOMATIC.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK.txt'+" -s "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''


def gsnap_strelka_somatic():
	'''Gsnap strelka Somatic calling calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["STRELKA_MEM"]+" -q "+path_dict["STRELKA_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_STRELKA_SOMATIC_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_GATK_PREPROCESS"+","+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STRELKA_SOMATIC.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK.txt'+" -s "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''
	if path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"].lower() != "no":
		cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["STRELKA_MEM"]+" -q "+path_dict["STRELKA_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_STRELKA_SOMATIC_CALLING_NOGATK"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP"+","+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"GSNAP_TUMOR"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STRELKA_SOMATIC.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL.txt'+" -s "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"GSNAP"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
		print(cmd)
		jid=sge_submit(cmd)
		myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
		myfile.write(jid+":"+cmd+"\n")
		myfile.close()
		
def Star_strelka_somatic():		
	'''Star strelka Somatic calling calling'''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["STRELKA_MEM"]+" -q "+path_dict["STRELKA_QUEUE"]+" -N "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_STRELKA_SOMATIC_CALLING"+" -hold_jid "+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_GATK_PREPROCESS"+","+"Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"STAR_TUMOR_GATK_PREPROCESS"+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" -t 1-"+str(fastq_normal_dict)+":1 "+path_dict["SCRIPTPATH"]+'/'+"STRELKA_SOMATIC.sh -c "+path_dict["TOOL_CONFIG"]+" -f "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK.txt'+" -s "+path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_GATK.txt'+" -r "+path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"STAR"+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
	'''Additional Varsscan & Strelka Analysis with out GATK preprocessing'''

		
def ensure_file(x,y):
	'''Checks if a directory is present or not and creates one if not present'''
	if not os.path.isfile(y):
		print("File not exitsts "+x+":"+y)
		global check_indicator
		check_indicator=1	

def ensure_multiple_file(x,y):
	'''Checks if a directory is present or not and creates one if not present'''
	global check_indicator
	p = y.split(",")
	for ind in p:
		if not os.path.isfile(ind):
			print("File not exitsts "+x+":"+ind)
			check_indicator=1
	
def CleanUp():
	global check_indicator
	global path_dict
	'''Reading the '''
	fobj = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt')
	ListJob=[]
	fobj.readline()
	for file in fobj:
		file=file.strip()
		p = file.split(":")
		ListJob.append(p[0])
	fobj.close()
	job_list=",".join(ListJob)
	
	cmd=path_dict["QSUB"]+" -m a -j y "+" -l h_vmem="+path_dict["STAR_MEM"]+" -q "+path_dict["STAR_QUEUE"]+" -N Somatic_caller_Workflow_"+path_dict["WORKFLOW_VERSION"]+"_"+path_dict["RUNID"]+"_"+"CleanUp"+" -hold_jid "+job_list+" -o "+path_dict["SGELOG"]+" -M "+path_dict["EMAIL"]+" "+path_dict["SCRIPTPATH"]+'/'+"CLEANUP.sh -c "+path_dict["TOOL_CONFIG"]+" -r "+path_dict["PROCESSDIR"]+" -e "+path_dict["EMAIL"]+" -i "+path_dict["RUNID"];
	print(cmd)
	jid=sge_submit(cmd)
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='a')
	myfile.write(jid+":"+cmd+"\n")
	myfile.close()
				
def ensure_inputfastq_file():
	'''Checks if fastq files are present '''
	global check_indicator
	global path_dict
	global fastq_normal_dict
	fastq_normal_dict = 0
	
	'''Normal fastq files'''
	fobj = open(path_dict["SINGLE_FASTQ"])
	myfile = open(path_dict["PROCESSDIR"]+'/'+"CONFIG"+'/'+'FASTQ_NORMAL.txt', mode='wt')
	for file in fobj:
		file=file.strip()
		file=re.sub('\t',' ', file)
		p = file.split(" ")
		'''checking length'''
		if len(p) != 3 and len(p) != 2:
			print("There should be two fastq files Read1 & Read2"+": "+file)
			check_indicator=1
		'''If name is not specified name is created'''
		if len(p) == 2:
			name=p[0].split("/")
			name=name[len(name)-1]
			name=re.sub('.gz', '', name)
			name=re.sub('.fastq', '', name)
			p.insert(0,name)
			
		'''check first fastq file'''
		if not os.path.isfile(p[1]):
			print("Read1 Fastq File not exists "+":"+p[1])
			check_indicator=1
		'''check second fastq file'''
		if not os.path.isfile(p[2]):
			print("Read2 Fastq File not exists "+":"+p[2])
			check_indicator=1
		'''Writing normal fastq files to normal fastq file'''
		fastq_normal_dict+=1
		myfile.write(p[0]+" "+p[1]+" "+p[2]+"\n")
	fobj.close()
	myfile.close()
	path_dict["SINGLE_FASTQ"]=str(path_dict["PROCESSDIR"]+'/'+"CONFIG"+'/'+'FASTQ_NORMAL.txt')
	
	'''Checking for Tumor fastq files'''
	global fastq_tumor_dict
	fastq_tumor_dict = 0
	if path_dict["PAIRED_FASTQ"].lower() != "na":
		fobj = open(path_dict["PAIRED_FASTQ"])
		myfile = open(path_dict["PROCESSDIR"]+'/'+"CONFIG"+'/'+'FASTQ_TUMOR.txt', mode='wt')
		for file in fobj:
			file=file.strip()
			file=re.sub('\t',' ', file)
			p = file.split(" ")
			'''checking length'''
			if len(p) != 3 and len(p) != 2:
				print("There should be two fastq files Read1 & Read2"+": "+file)
				check_indicator=1
			'''If name is not specified name is created'''
			if len(p) == 2:
				name=p[0].split("/")
				name=name[len(name)-1]
				name=re.sub('.gz', '', name)
				name=re.sub('.fastq', '', name)
				p.insert(0,name)
				'''check first fastq file'''
			p[0]=p[0]+".tumor";
			if not os.path.isfile(p[1]):
				print("Tumor Fastq File not exists "+":"+p[1])
				check_indicator=1
			'''check second fastq file'''
			if not os.path.isfile(p[2]):
				print("Tumor Fastq File not exists "+":"+p[2])
				check_indicator=1
			'''Writing normal fastq files to normal fastq file'''	
			myfile.write(p[0]+" "+p[1]+" "+p[2]+"\n")
			fastq_tumor_dict+=1
		fobj.close()
		myfile.close()
		
		if fastq_normal_dict != fastq_tumor_dict:
			print("Number of normal fastq files "+fastq_normal_dict+" not equal to number of tumor fastq files "+fastq_tumor_dict)
			check_indicator=1
		path_dict["PAIRED_FASTQ"]=str(path_dict["PROCESSDIR"]+'/'+"CONFIG"+'/'+'FASTQ_TUMOR.txt')			
			
def argument_parse():
	'''Parses the command line arguments'''
	parser=argparse.ArgumentParser(description='')
	parser.add_argument("-r","--run_info",help="Run information file",required="True",type=input_file_validity)
	parser.add_argument("-t","--tool_info",help="Tool information file",required="True",type=input_file_validity)
	return parser

def config_parse(RunInfofile,ToolInfofile):
	path_dict = {}
	'''Readin RunInfo File'''
	print("Input RunInfo Config File Supplied")
	file = open(RunInfofile, 'r')
	for path in file:
		path=path.strip()
		p = path.split("=")
		name=p[0]
		del p[0]
		p=str.join("=",p).strip('"')
		p.strip()
		name.strip()
		path_dict[name] = p
		print(name+' : '+p)
	'''Readin ToolInfo File'''
	print("Input ToolInfo Config File Supplied")
	file = open(ToolInfofile, 'r')
	for path in file:
		path=path.strip()
		p = path.split("=")
		name=p[0]
		del p[0]
		p=str.join("=",p).strip('"')
		p.strip()
		name.strip()
		path_dict[name] = p
		print(name+' : '+p)
	return path_dict
	
def main():	
	abspath=os.path.abspath(__file__)
	words = abspath.split("/")
	print("You are running Somatic caller Workflow "+words[len(words) - 2])
	'''reading the config filename'''
	parser=argument_parse()
	arg=parser.parse_args()
	print("Entered Run Info Config file "+arg.run_info+"\n\n")
	print("Entered Tool Info Config file "+arg.tool_info+"\n\n")
	'''Parsing the config files'''
	global path_dict
	path_dict = config_parse(arg.run_info,arg.tool_info)
	global check_indicator
	check_indicator=0
	
	'''script path'''
	del words[-1]
	path_dict["SCRIPTPATH"]=str.join('/',words)
	#path_dict["RUN_CONFIG"]=arg.run_info;
	#path_dict["TOOL_CONFIG"]=arg.tool_info;
	path_dict["WORKFLOW_VERSION"]=words[len(words) - 1];
	path_dict["VARSCAN_STRELKA_NO_GATK_PREPROCESS"]="NO"
	if not "PAIRED_FASTQ" in path_dict:
		path_dict["PAIRED_FASTQ"]="NA"
		
	#if not "GENE_FILTER" in path_dict:
	#	path_dict["GENE_FILTER"]="NA"	
		
	'''creating list for checking variables in the dict path_dict'''
	list_var = ["JAVA","PYTHON","PERL","SH","WORKFLOW_PATH","STAR_FUSION_PERL_PACKAGE","QSUB","STAR","GSNAP","SAMTOOLS","HTSDIR","FEATURECOUNTS","BCFTOOLS","SAMBLASTER","SAMBAMBA","PICARD","GATK","ANNOVAR","STRELKA_WORKFLOW","STAR_FUSION","BEDTOOLS","SAMBLASTER_OPTIONS","PICARD_ARG_OPTION","STAR_OPTION","STAR_OPTION_STEP2","GSNAP_JAVA_OPTION","GATK_JAVA_OPTION","GATK_SPLITNCIGAR_OPT","GATK_JAVA_OPTION","DEBUG","REMOVE_DUP_READS","ANNOVAR_QUEUE","ANNOVAR_MEM","BCFTOOLS_OPTIONS","SAMTOOLS_BCFTOOLS_OPTIONS","DELETE_BAM_POST_GATK_PROCESS","SAMBAMBA_PARAM","GSNAP_QUEUE","GSNAP_MEM","STAR_QUEUE","STAR_MEM","GATK_QUEUE","GATK_MEM","BCFTOOLS_QUEUE","BCFTOOLS_MEM","STRELKA_QUEUE","STRELKA_MEM","STAR_QUEUE","STAR_MEM","STRELKA_CONFIG","REF_GENOME","GATK_BASE_RECALIBRATION_KNOWNSITES","STAR_REF","GSNAP_OPTION","GATK_HAPLOTYPE_CALLER_OPTION","ANNOVAR_OPTION","STAR_FUSION_CTAT_LIB","FEATURECOUNTS_OPTION"]
	for i in range(0,len(list_var)):
		if not list_var[i] in path_dict:
			print(list_var[i]+' '+"should exist in the tool info file.")
			check_indicator = 1
			sys.exit(1)

	list_var = ["SINGLE_FASTQ", "PROCESSDIR", "PAIRED_FASTQ", "EMAIL", "RUNID", "ALIGNERS", "CALLERS", "VARSCAN_STRELKA_NO_GATK_PREPROCESS"]
	for i in range(0,len(list_var)):
		if not list_var[i] in path_dict:
			print(list_var[i] + ' ' + "should exist in the run info file.")
			check_indicator = 1
			sys.exit(1)

	'''Ensure qsub'''
	if "QSUB" in path_dict:
		if path_dict["QSUB"] != "NA" and path_dict["QSUB"] != "na":
			ensure_file("QSUB", path_dict["QSUB"])
	else:
		print("QSUB should exist in the tool info file.")
		check_indicator = 1

	'''Ensure Python'''
	ensure_file("PYTHON",path_dict["PYTHON"])
	
	'''Ensure Perl'''
	ensure_file("PERL",path_dict["PERL"])
	
	'''Ensure SH'''
	ensure_file("SH",path_dict["SH"])
	
	'''Ensure FEATURECOUNTS'''
	ensure_file("FEATURECOUNTS",path_dict["FEATURECOUNTS"])
	
	'''Ensure STAR_FUSION'''
	ensure_file("STAR_FUSION",path_dict["STAR_FUSION"])
	
	'''Ensure Samblaster'''
	ensure_file("SAMBLASTER",path_dict["SAMBLASTER"])
	
	'''Create Output Directory'''
	create_dir(path_dict["PROCESSDIR"])
	
	'''Create config Directory'''
	create_dir(path_dict["PROCESSDIR"]+'/'+"CONFIG")
	
	'''Copying the config files'''
	shutil.copy2(arg.run_info,path_dict["PROCESSDIR"]+'/'+"CONFIG/runinfo.txt")
	shutil.copy2(arg.tool_info,path_dict["PROCESSDIR"]+'/'+"CONFIG/toolinfo.txt")
	
	path_dict["RUN_CONFIG"]=path_dict["PROCESSDIR"]+'/'+"CONFIG/runinfo.txt"
	path_dict["TOOL_CONFIG"]=path_dict["PROCESSDIR"]+'/'+"CONFIG/toolinfo.txt"
	
	'''Adding missing parameters'''
	myfile = open(path_dict["RUN_CONFIG"], mode='a')
	myfile1 = open(path_dict["TOOL_CONFIG"], mode='a')
	if not "PAIRED_FASTQ" in path_dict:
		path_dict["PAIRED_FASTQ"]="NA"
		myfile.write("PAIRED_FASTQ=NA")
	#if not "GENE_FILTER" in path_dict:
	#	myfile.write("GENE_FILTER=NA")
	#else:
	#	myfile1.write("GENE_FILTER="+path_dict["GENE_FILTER"])
	myfile.close()
	myfile1.close()
	'''Ensure samtools'''
	ensure_file("SAMTOOLS",path_dict["SAMTOOLS"])
	
	'''Ensure bcftools'''
	ensure_file("BCFTOOLS",path_dict["BCFTOOLS"])

	'''Ensure samblaster'''
	ensure_file("SAMBLASTER", path_dict["SAMBLASTER"])

	'''Ensure picard'''
	ensure_file("PICARD",path_dict["PICARD"])
	
	'''Ensure Java'''
	ensure_file("JAVA",path_dict["JAVA"])
	
	'''Ensure GATK'''
	ensure_file("GATK",path_dict["GATK"])

	'''Ensure REF_GENOME'''
	ensure_file("REF_GENOME",path_dict["REF_GENOME"])
	
	'''Ensure GSNAP'''
	ensure_file("GSNAP",path_dict["GSNAP"])
	
	'''Ensure STAR'''
	ensure_file("STAR",path_dict["STAR"])

	'''Ensure INPUT_FASTQ'''
	ensure_inputfastq_file()
	
	if check_indicator != 0:
		print("Checking Failed.Please check above errors.")
		sys.exit(0)

	'''Create SGELOG Directory'''
	path_dict["SGELOG"]=path_dict["PROCESSDIR"]+'/'+"LOG";
	create_dir(path_dict["SGELOG"])

	'''Creating the SGE job log file'''
	myfile = open(path_dict["PROCESSDIR"]+'/'+'SGE_JOBID_COMMAND.txt', mode='wt')
	myfile.write("JOBID:"+"COMMAND"+"\n")
	myfile.close()
	path_dict["ALIGNERS"]=path_dict["ALIGNERS"].upper()
	path_dict["CALLERS"]=path_dict["CALLERS"].upper()
	
	'''Create Alignment Directory'''
	create_dir(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT")
	
	if path_dict["ALIGNERS"].find("GSNAP") != -1:
		'''Creating input FASTQ file for GSNAP NORMAL Alignment'''
		fobj = open(path_dict["SINGLE_FASTQ"])
		myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL.txt', mode='wt')
		for file in fobj:
			file=file.strip()
			p = file.split(" ")
			p[0] =p[0]+".GSNAP"
			myfile.write(str.join(" ",p)+"\n")
		fobj.close()
		myfile.close()
		
		'''Creating input FASTQ file for GSNAP TUMOR Alignment'''
		if path_dict["PAIRED_FASTQ"].lower() != "na":
			fobj = open(path_dict["PAIRED_FASTQ"])
			myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_TUMOR.txt', mode='wt')
			for file in fobj:
				file=file.strip()
				p = file.split(" ")
				p[0] =p[0]+".GSNAP"
				myfile.write(str.join(" ",p)+"\n")
			fobj.close()
			myfile.close()
				
		'''GSNAP Alignment'''
		gsnap_align()
		
		if path_dict["CALLERS"].lower() != "na":
			'''Create SNVINDEL Directory'''
			create_dir(path_dict["PROCESSDIR"]+'/'+"SNVINDEL")
			create_dir(path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"GSNAP")
			
			'''Creating input file for GSNAP preprocess'''
			fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL.txt')
			myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL.txt', mode='wt')
			for file in fobj:
				file=file.strip()
				p = file.split(" ")
				myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+'/'+p[0]+".gatkin.bam "+"\n")
			fobj.close()
			myfile.close()
			
			'''Creating input file for GSNAP SOMATIC GATK calling'''
			fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_NORMAL.txt')
			myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_NORMAL_GATK.txt', mode='wt')
			for file in fobj:
				file=file.strip()
				p = file.split(" ")
				myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+'/'+p[0]+".gatkin.splitNC.realign.recaliber.bam "+"\n")
			fobj.close()
			myfile.close()
			
			if path_dict["PAIRED_FASTQ"].lower() != "na":
				'''Create SOMATIC_SNVINDEL Directory'''
				create_dir(path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL")
				create_dir(path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"GSNAP")
					
				'''Creating input file for GSNAP Somatic preprocess'''
				fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_TUMOR.txt')
				myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR.txt', mode='wt')
				for file in fobj:
					file=file.strip()
					p = file.split(" ")
					myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+'/'+p[0]+".gatkin.bam "+"\n")
				fobj.close()
				myfile.close()
				
				'''Creating input file for GSNAP SOMATIC GATK calling'''
				fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_FASTQ_TUMOR.txt')
				myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'GSNAP_TUMOR_GATK.txt', mode='wt')
				for file in fobj:
					file=file.strip()
					p = file.split(" ")
					myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"GSNAP"+'/'+p[0]+".gatkin.splitNC.realign.recaliber.bam "+"\n")
				fobj.close()
				myfile.close()
				
			gsnap_gatk_preprocess()
			if path_dict["CALLERS"].find("FEATURECOUNTS") != -1:
				'''Create GENECOUNTS Directory'''
				create_dir(path_dict["PROCESSDIR"]+'/'+"GENECOUNTS")
				create_dir(path_dict["PROCESSDIR"]+'/'+"GENECOUNTS"+'/'+"GSNAP")
				gsnap_featurecount()
			if path_dict["CALLERS"].find("GATK") != -1:
				gsnap_gatk_caller()
			if path_dict["CALLERS"].find("BCFTOOLS") != -1:
				gsnap_bcftools_caller()
			if path_dict["CALLERS"].find("VARSCAN") != -1:
				gsnap_varscan_single()
			if path_dict["PAIRED_FASTQ"].lower() != "na":	
				if path_dict["CALLERS"].find("VARSCAN_SOMATIC") != -1: 
					gsnap_varscan_somatic()
				if path_dict["CALLERS"].find("STRELKA_SOMATIC") != -1: 
					gsnap_strelka_somatic()
			
			
	if path_dict["ALIGNERS"].find("STAR") != -1:
		'''Creating input FASTQ file for GSNAP NORMAL Alignment'''
		fobj = open(path_dict["SINGLE_FASTQ"])
		myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL.txt', mode='wt')
		for file in fobj:
			file=file.strip()
			p = file.split(" ")
			p[0] =p[0]+".STAR"
			myfile.write(str.join(" ",p)+"\n")
		fobj.close()
		myfile.close()
		
		'''Creating input FASTQ file for GSNAP TUMOR Alignment'''
		if path_dict["PAIRED_FASTQ"].lower() != "na":
			fobj = open(path_dict["PAIRED_FASTQ"])
			myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_TUMOR.txt', mode='wt')
			for file in fobj:
				file=file.strip()
				p = file.split(" ")
				p[0] =p[0]+".STAR"
				myfile.write(str.join(" ",p)+"\n")
			fobj.close()
			myfile.close()
		
		'''STAR Alignment'''
		star_align()	
		if path_dict["CALLERS"].lower() != "na":
			'''Create SNVINDEL Directory'''
			create_dir(path_dict["PROCESSDIR"]+'/'+"SNVINDEL")
			create_dir(path_dict["PROCESSDIR"]+'/'+"SNVINDEL"+'/'+"STAR")
			
			'''Creating input file for STAR preprocess'''
			fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL.txt')
			myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL.txt', mode='wt')
			for file in fobj:
				file=file.strip()
				p = file.split(" ")
				myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+'/'+p[0]+".gatkin.bam "+"\n")
			fobj.close()
			myfile.close()
			
			'''Creating input file for STAR GATK calling'''
			fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_NORMAL.txt')
			myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_NORMAL_GATK.txt', mode='wt')
			for file in fobj:
				file=file.strip()
				p = file.split(" ")
				myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+'/'+p[0]+".gatkin.splitNC.realign.recaliber.bam "+"\n")
			fobj.close()
			myfile.close()
			
			if path_dict["PAIRED_FASTQ"].lower() != "na":
				'''Create SOMATIC_SNVINDEL Directory'''
				create_dir(path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL")
				create_dir(path_dict["PROCESSDIR"]+'/'+"SOMATIC_SNVINDEL"+'/'+"STAR")
				
				fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_TUMOR.txt')
				myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR.txt', mode='wt')
				for file in fobj:
					file=file.strip()
					p = file.split(" ")
					myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+'/'+p[0]+".gatkin.bam "+"\n")
				fobj.close()
				myfile.close()
				
				'''Creating input file for STAR SOMATIC GATK calling'''
				fobj = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_FASTQ_TUMOR.txt')
				myfile = open(path_dict["PROCESSDIR"]+'/'+'CONFIG'+'/'+'STAR_TUMOR_GATK.txt', mode='wt')
				for file in fobj:
					file=file.strip()
					p = file.split(" ")
					myfile.write(path_dict["PROCESSDIR"]+'/'+"ALIGNMENT"+'/'+"STAR"+'/'+p[0]+".gatkin.splitNC.realign.recaliber.bam "+"\n")
				fobj.close()
				myfile.close()
				
			Star_gatk_preprocess()
			if path_dict["CALLERS"].find("FEATURECOUNTS") != -1:
				'''Create GENECOUNTS Directory'''
				create_dir(path_dict["PROCESSDIR"]+'/'+"GENECOUNTS")
				create_dir(path_dict["PROCESSDIR"]+'/'+"GENECOUNTS"+'/'+"STAR")
				Star_featurecount()
			if path_dict["CALLERS"].find("STAR_FUSION") != -1:
				'''Create STAR FUSIONS Directory'''
				create_dir(path_dict["PROCESSDIR"]+'/'+"FUSIONS")	
				Star_fusion_caller()
			if path_dict["CALLERS"].find("GATK") != -1:
				Star_gatk_caller()
			if path_dict["CALLERS"].find("BCFTOOLS") != -1:
				Star_bcftools_caller()
			if path_dict["CALLERS"].find("VARSCAN") != -1:
				Star_varscan_single()
			if path_dict["PAIRED_FASTQ"].lower() != "na":	
				if path_dict["CALLERS"].find("VARSCAN_SOMATIC") != -1: 
					Star_varscan_somatic()
				if path_dict["CALLERS"].find("STRELKA_SOMATIC") != -1: 
					Star_strelka_somatic()			
	
	#if path_dict["CALLERS"].lower() != "na":
	#	Annovar_fileprep()
	#	Annovar()
	CleanUp()
	
	
	
if __name__ == "__main__":
	main()