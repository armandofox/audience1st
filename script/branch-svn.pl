#!/opt/local/bin/perl

$no = 1, shift @ARGV if $ARGV[0] =~ /^-n/;
die "Usage: $0 branchname 'commit message'" unless ($#ARGV == 1);
die "Must be in trunk directory to branch" unless (`pwd` =~ m!/trunk$!);

$branch = shift @ARGV;
$msg = shift @ARGV;

$repo = `svn info|sed -ne 's/Repository Root: //p'`;
chomp $repo;
$head = int(1 + `svn up|sed -ne 's/At revision //p'`);

$cmd = "svn cp $repo/trunk $repo/branches/r$head-$branch -m '$msg'";

printf STDERR "Executing: $cmd\n";
system($cmd) unless $no;





