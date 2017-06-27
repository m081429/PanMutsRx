$infile=$ARGV[0];
$outfile=$ARGV[1];
open(BUFF,$infile) or die "no $infile found\n";
open(WRBUFF,">$outfile") or die "not able to write the file $outfile\n";
while(<BUFF>){
	chomp($_);
	@a=split("\t",$_);
	if($a[2] =~ m/^chr\d+$/)
	{
		$a[9] =~ s/,$//g;
		$a[10] =~ s/,$//g;
		@start=split(',',$a[9]);
		@stop=split(',',$a[10]);
		for($i=0;$i<@start;$i++)
		{
			print WRBUFF $a[2]."\t".$start[$i]."\t".$stop[$i]."\n";
		}
	}
}
close(BUFF);
close(WRBUFF);