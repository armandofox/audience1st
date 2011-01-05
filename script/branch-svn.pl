#!/opt/local/bin/perl

$no = 1, shift @ARGV if $ARGV[0] =~ /^-n/;
die "Usage: $0 branchname" unless ($branch = shift @ARGV);
die "Must be in trunk directory to branch" unless (`pwd` =~ m!/trunk$!);

$msg = "New branch for $branch";

$repo = `svn info|sed -ne 's/Repository Root: //p'`;
chomp $repo;
$head = int(1 + `svn up|sed -ne 's/At revision //p'`);
$bname = "r$head-$branch";
$cmd = "svn cp $repo/trunk $repo/branches/$bname -m '$msg'  &&  cd ../branches && svn up $bname && cd $bname && make dev";

printf STDERR "Executing: $cmd\n";
system($cmd) unless $no;





