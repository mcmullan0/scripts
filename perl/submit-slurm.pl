#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

# Write a slurm script for given input (see help = run with no flags)
my %opts;
getopts('q:N:n:c:t:j:i:m:d:er', \%opts);
my $status = '--mail-type=END,FAIL';
my $email = '--mail-user=mark.mcmullan@tgac.ac.uk';
my $datestring = localtime();
my $hashes ='##########################';

unless ($opts{i})
{
  print STDOUT "\nWrite a slurm script for given input\n";
  print STDOUT "profile  -j jobID (default = bash)\n";
  print STDOUT "         -i \"command line\" (REQUIRED)\n";
  print STDOUT "         -q queue (default = tgac-short (-6h); OR: tgac-medium (-2d), tgac-long)\n";
  print STDOUT "         -N nodes (default = 1)\n";
  print STDOUT "         -n tasks (default = 1)\n";
  print STDOUT "         -c cores/threads (default = 4)\n";
  print STDOUT "         -m memory (in mb; default = 4096)\n";
  print STDOUT "         -t time (default = 0-0:20 (20 mins); -t no longer than queue)\n";
  print STDOUT "         -e (if you want it to email you on complete.  Default = n)\n";
  print STDOUT "         -r Do not remove the run file (default = rm MM-runfile-MM)\n";
  print STDOUT "Appends this run info to your .out and .err files (before slurm); --open-mode=append\n";
  print STDOUT "Then writes the slrum file and runs\n";
  exit;
}

# Variables that have defaults
unless ($opts{j})
{
  $opts{j}="bash";
}
unless ($opts{q})
{
  $opts{q}="tgac-short";
}
unless ($opts{N})
{
  $opts{N}=1;
}
unless ($opts{n})
{
  $opts{n}=1;
}
unless ($opts{c})
{
  $opts{c}=4;
}
unless ($opts{t})
{
  $opts{t}="0-0:20";
}
unless ($opts{m})
{
  $opts{m}="4096";
}

# Add run info to slurm .out & .err files
# .out.slurm
open(OUTFILE, ">>$opts{j}.out.slurm");
print OUTFILE "$hashes\n$datestring\n$hashes\n";
print OUTFILE "#!/bin/bash -e\n";
print OUTFILE "#SBATCH -p $opts{q} # partition (queue)\n";
print OUTFILE "#SBATCH -N $opts{N} # number of nodes\n";
print OUTFILE "#SBATCH -n $opts{n} # number of tasks\n";
print OUTFILE "#SBATCH -c $opts{c} # number of cores\n";
print OUTFILE "#SBATCH --mem $opts{m} # memory pool for all cores\n";
print OUTFILE "#SBATCH -t $opts{t} # time (D-HH:MM)\n";
print OUTFILE "#SBATCH -o $opts{j}.out.slurm # STDOUT\n";
print OUTFILE "#SBATCH -e $opts{j}.err.slurm # STDERR\n";
print OUTFILE "#SBATCH --open-mode=append\n";
if ($opts{e})
{
  print OUTFILE "#SBATCH $status # notifications for job done & fail\n";
  print OUTFILE "#SBATCH $email # send-to address\n";
}
print OUTFILE "\n$opts{i}\n";
print OUTFILE "$hashes\n\n\n";
close(OUTFILE);
# .err.slurm
open(ERRFILE, ">>$opts{j}.err.slurm");
print ERRFILE "$hashes\n$datestring\n$hashes\n";
print ERRFILE "#!/bin/bash -e\n";
print ERRFILE "#SBATCH -p $opts{q} # partition (queue)\n";
print ERRFILE "#SBATCH -N $opts{N} # number of nodes\n";
print ERRFILE "#SBATCH -n $opts{n} # number of tasks\n";
print ERRFILE "#SBATCH -c $opts{c} # number of cores\n";
print ERRFILE "#SBATCH --mem $opts{m} # memory pool for all cores\n";
print ERRFILE "#SBATCH -t $opts{t} # time (D-HH:MM)\n";
print ERRFILE "#SBATCH -o $opts{j}.out.slurm # STDOUT\n";
print ERRFILE "#SBATCH -e $opts{j}.err.slurm # STDERR\n";
print ERRFILE "#SBATCH --open-mode=append\n";
if ($opts{e})
{
  print ERRFILE "#SBATCH $status # notifications for job done & fail\n";
  print ERRFILE "#SBATCH $email # send-to address\n";
}
print ERRFILE "\n$opts{i}\n";
print ERRFILE "$hashes\n\n\n";
close(ERRFILE);

# Make my submision file for SLURM
open(SLURMFILE, ">MM-$opts{j}.slurm-MM");
print SLURMFILE "#!/bin/bash -e\n";
print SLURMFILE "#SBATCH -p $opts{q} # partition (queue)\n";
print SLURMFILE "#SBATCH -N $opts{N} # number of nodes\n";
print SLURMFILE "#SBATCH -n $opts{n} # number of tasks\n";
print SLURMFILE "#SBATCH -c $opts{c} # number of cores\n";
print SLURMFILE "#SBATCH --mem $opts{m} # memory pool for all cores\n";
print SLURMFILE "#SBATCH -t $opts{t} # time (D-HH:MM)\n";
print SLURMFILE "#SBATCH -o $opts{j}.out.slurm # STDOUT\n";
print SLURMFILE "#SBATCH -e $opts{j}.err.slurm # STDERR\n";
print SLURMFILE "#SBATCH --open-mode=append\n";
if ($opts{e})
{
  print SLURMFILE "#SBATCH $status # notifications for job done & fail\n";
  print SLURMFILE "#SBATCH $email # send-to address\n";
}
print SLURMFILE "\n$opts{i}\n";
close(SLURMFILE);

# Here we then run SLURMFILE 
system("sbatch MM-$opts{j}.slurm-MM");

# Collect job id then if failed -send me an email
#my $bashout = <STDIN>;
#my @bashout = split(/ /,$bashout);
#my $jobid = $bashout[3];
#print STDOUT "this is the job id $jobid";
#exit;
#
# afternotok:job_id[:jobid...]
# This job can begin execution after the specified jobs have terminated in some failed state (non-zero exit code, node failure, timed out, etc).
# afterok:job_id[:jobid...]
# This job can begin execution after the specified jobs have successfully executed (ran to completion with an exit code of zero).
#
unless ($opts{r})
{
  system("sleep 1; rm MM-$opts{j}.slurm-MM")
}
