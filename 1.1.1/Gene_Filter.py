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
import gzip
	
def input_file_validity(file):
	'''Validates the input files'''
	if os.path.exists(file)==False:
		raise argparse.ArgumentTypeError( '\nERROR:Path:\n'+file+':Does not exist')
	if os.path.isfile(file)==False:
		raise argparse.ArgumentTypeError( '\nERROR:File expected:\n'+file+':is not a file')
	if os.access(file,os.R_OK)==False:
		raise argparse.ArgumentTypeError( '\nERROR:File:\n'+file+':no read access ')
	return file

def input_dir_validity(file):
	'''Checks if a directory is present or not and creates one if not present'''
	if os.path.exists(file) == False:
		raise argparse.ArgumentTypeError( '\nERROR: Directory not exists ')
	return file


def argument_parse():
	'''Parses the command line arguments'''
	parser=argparse.ArgumentParser(description='')
	parser.add_argument("-g","--gene_filter",help="Gene_Filter gene list",required="True",type=input_file_validity)
	parser.add_argument("-i","--input",help="Input file or Input directory",required="True")
	parser.add_argument("-f","--filter_type",help="Filter Type",required="True")
	parser.add_argument("-o","--output_file",help="Output file",required="True")
	return parser


def main():	
	abspath=os.path.abspath(__file__)
	words = abspath.split("/")
	print("You are running GeneFilter "+words[len(words) - 2])
	'''reading the config filename'''
	parser=argument_parse()
	arg=parser.parse_args()
	print("Entered Gene Filter file "+arg.gene_filter)
	print("Entered Input file "+arg.input)
	print("Entered Output file "+arg.output_file)
	print("Entered Filter type "+arg.filter_type)
	
	if not (arg.filter_type == "variant" or arg.filter_type == "somatic" or arg.filter_type == "expression" or arg.filter_type == "fusion"):
		print('Entered Filtered type should be vairant or somatic or expression or fusion')
		sys.exit(1)
	if arg.filter_type == "variant" or arg.filter_type == "somatic":
		if not os.path.isdir(arg.input):
			print("Input Variant Directory not exitsts "+arg.input)
			sys.exit(1)
	elif arg.filter_type == "expression":
		if not os.path.isfile(arg.input):
			print("Input gene expression not exitsts "+arg.input)
			sys.exit(1)
	else:
		if not os.path.isdir(arg.input):
			print("Input fusion directory not exitsts "+arg.input)
			sys.exit(1)
	if not os.path.isfile(arg.gene_filter):
		print("File not exitsts "+arg.gene_filter)
		sys.exit(1)
	
	dict_genelist = {}	
	
	'''reading the gene filter file'''
	fobj = open(arg.gene_filter)
	for file in fobj:
		file=file.strip()
		dict_genelist[file]=1
	fobj.close()
	
	'''variant'''
	if arg.filter_type == "variant":
		list_samples=[]
		list_variants=[]
		dict_var={}
		output_flag=0
		'''readin vcf and writing the output file'''
		dirs = os.listdir(arg.input)
		tmp_str=""
		for infile in dirs:
			if infile.endswith(".vcf.gz") or infile.endswith(".vcf"):
				output_flag=1
				samp=infile.replace('.GATK.Filtered.ANNOVAR.vcf', '')
				samp=samp.replace('.gz', '')
				print("Processing file "+samp+"....")
				list_samples.append(samp)
				if infile.endswith(".vcf.gz"):
					fobj = gzip.open(arg.input+'/'+infile,'rb')
				else:
					fobj = open(arg.input+'/'+infile)
				for file in fobj:
					file = file.strip()
					if infile.endswith(".vcf.gz"):
						file=file.decode('ascii')
					if not file.startswith('#'):
						p = file.split("\t")
						var=p[0]+'_'+p[1]+'_'+p[3]+'_'+p[4]
						p1 = p[7].split('Gene.refGene=')
						p2 = p1[1].split(';')
						genes = p2[0].split(',')
						k=0
						tmp_gene=""
						tmp_str=p[8]
						for i in range(0, len(genes)):
							if genes[i] in dict_genelist:
								k=1
								tmp_gene=genes[i]
						if k==1:
							var=var+'_'+tmp_gene
							if not var in list_variants:
								list_variants.append(var)	
							dict_var[samp+'__'+var]=p[9]	
				fobj.close()
		if output_flag==1:		
			print("Writing output")		
			myfile = open(arg.output_file, mode='wt')
			tmp_str="variant_"+tmp_str+"_chr\tpos\tref\talt\tgene\t"+str.join('\t',list_samples)
			myfile.write(tmp_str + "\n")
			strt=""
			for i in range(0,len(list_variants)):
				lv=list_variants[i].replace('_', '\t')
				myfile.write(lv)
				for j in range(0,len(list_samples)):	
					strt=list_samples[j]+'__'+list_variants[i]
					if strt in dict_var:
						myfile.write("\t"+dict_var[strt])
					else:
						myfile.write("\tNA")
				myfile.write("\n")	
			myfile.close()
	

		'''somatic'''
	if arg.filter_type == "somatic":
		list_samples=[]
		list_samples1=[]
		list_variants=[]
		dict_var={}
		output_flag=0
		'''readin vcf and writing the output file'''
		dirs = os.listdir(arg.input)
		tmp_str=""
		for infile in dirs:
			if infile.endswith(".snvs.ANNOVAR.vcf.gz") or infile.endswith(".snvs.ANNOVAR.vcf"):
				output_flag=1
				samp=infile.replace('.strelka.passed.somatic.snvs.ANNOVAR.vcf', '')
				samp=samp.replace('.gz', '')
				print("Processing file "+samp+"....")
				list_samples.append(samp+'.NORMAL')
				list_samples.append(samp+'.TUMOR')
				list_samples1.append(samp)
				if infile.endswith(".vcf.gz"):
					fobj = gzip.open(arg.input+'/'+infile,'rb')
				else:
					fobj = open(arg.input+'/'+infile)
				for file in fobj:
					file = file.strip()
					if infile.endswith(".vcf.gz"):
						file=file.decode('ascii')
					if not file.startswith('#'):
						p = file.split("\t")
						var=p[0]+'_'+p[1]+'_'+p[3]+'_'+p[4]
						p1 = p[7].split('Gene.refGene=')
						p2 = p1[1].split(';')
						genes = p2[0].split(',')
						k=0
						tmp_gene=""
						tmp_str=p[8]
						for i in range(0, len(genes)):
							if genes[i] in dict_genelist:
								k=1
								tmp_gene=genes[i]
						if k==1:
							var=var+'_'+tmp_gene
							if not var in list_variants:
								list_variants.append(var)	
							dict_var[samp+'__'+var+'__normal']=p[9]
							dict_var[samp+'__'+var+'__tumor']=p[10]							
				fobj.close()
			if infile.endswith(".indels.ANNOVAR.vcf.gz") or infile.endswith(".indels.ANNOVAR.vcf"):
				samp=infile.replace('.strelka.passed.somatic.indels.ANNOVAR.vcf', '')
				samp=samp.replace('.gz', '')
				print("Processing indel file "+samp+"....")
				if infile.endswith(".vcf.gz"):
					fobj = gzip.open(arg.input+'/'+infile,'rb')
				else:
					fobj = open(arg.input+'/'+infile)
				for file in fobj:
					file = file.strip()
					if infile.endswith(".vcf.gz"):
						file=file.decode('ascii')
					if not file.startswith('#'):
						p = file.split("\t")
						var=p[0]+'_'+p[1]+'_'+p[3]+'_'+p[4]
						p1 = p[7].split('Gene.refGene=')
						p2 = p1[1].split(';')
						genes = p2[0].split(',')
						k=0
						tmp_gene=""
						tmp_str=p[8]
						for i in range(0, len(genes)):
							if genes[i] in dict_genelist:
								k=1
								tmp_gene=genes[i]
						if k==1:
							var=var+'_'+tmp_gene
							if not var in list_variants:
								list_variants.append(var)	
							dict_var[samp+'__'+var+'__normal']=p[9]
							dict_var[samp+'__'+var+'__tumor']=p[10]							
				fobj.close()
		if output_flag==1:		
			print("Writing output")		
			myfile = open(arg.output_file, mode='wt')
			tmp_str="variant_"+tmp_str+"_chr\tpos\tref\talt\tgene\t"+str.join('\t',list_samples)
			myfile.write(tmp_str + "\n")
			strt=""
			for i in range(0,len(list_variants)):
				lv=list_variants[i].replace('_', '\t')
				myfile.write(lv)
				for j in range(0,len(list_samples1)):	
					strt=list_samples1[j]+'__'+list_variants[i]+'__normal'
					if strt in dict_var:
						myfile.write("\t"+dict_var[strt])
					else:
						myfile.write("\tNA")
					strt=list_samples1[j]+'__'+list_variants[i]+'__tumor'
					if strt in dict_var:
						myfile.write("\t"+dict_var[strt])
					else:
						myfile.write("\tNA")	
				myfile.write("\n")	
			myfile.close()
		
	'''expression'''
	if arg.filter_type == "expression":
		'''readin vcf and writing the output file'''
		fobj = open(arg.input)
		myfile = open(arg.output_file, mode='wt')
		header=fobj.readline()
		header = header.strip()
		myfile.write(header + "\n")
		for file in fobj:
			file = file.strip()
			p = file.split("\t")
			genes = p[0]
			if genes in dict_genelist:
				myfile.write(file + "\n")
		fobj.close()
		myfile.close()
		
	'''fusion'''
	if arg.filter_type == "fusion":
		list_samples=[]
		list_fusions=[]
		dict_fusions={}
		output_flag=0
		'''readin vcf and writing the output file'''
		dirs = os.listdir(arg.input)
		tmp_str=""
		for infile in dirs:
			if infile.endswith(".star_fusion_filtered.txt") or infile.endswith(".star_fusion.txt"):
				output_flag=1
				if infile.endswith(".star_fusion.txt"):
					samp=infile.replace('.star_fusion.txt', '')
				else:
					samp=infile.replace('.star_fusion_filtered.txt', '.FILTERED')
				print("Processing file "+samp+"....")
				list_samples.append(samp)
				fobj = open(arg.input+'/'+infile)
				header=fobj.readline()
				header = header.strip()
				for file in fobj:
					file = file.strip()
					p = file.split("\t")
					genes = p[0].split('--')
					k=0
					for i in range(0, len(genes)):
						if genes[i] in dict_genelist:
							k=1
					if k==1:
						if not p[0] in list_fusions:
							list_fusions.append(p[0])
						dict_fusions[samp+'__'+p[0]]="YES"
				fobj.close()
				
		if output_flag==1:		
			print("Writing output")		
			myfile = open(arg.output_file, mode='wt')
			tmp_str="FUSION\t"+str.join('\t',list_samples)
			myfile.write(tmp_str + "\n")
			strt=""
			for i in range(0,len(list_fusions)):
				myfile.write(list_fusions[i])
				for j in range(0,len(list_samples)):	
					strt=list_samples[j]+'__'+list_fusions[i]
					if strt in dict_fusions:
						myfile.write("\t"+dict_fusions[strt])
					else:
						myfile.write("\tNO")
				myfile.write("\n")	
			myfile.close()
		
if __name__ == "__main__":
	main()