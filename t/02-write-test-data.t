#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use RF::Component;
use File::Temp qw/tempfile/;

use Test::More tests => 1944;

my $datadir = 't/test-data/muRata';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = grep { /\.s\dp$/i } readdir($dir);
closedir($dir);

my ($fh, $tfn) = tempfile();
close($fh);

$tfn .= ".s2p";
END { unlink $tfn };

my $tolerance = 1e-6;

# For each file, permute {MA, RI, DB} <=> {S, Y, A} <=> {khz, MHz, GHz}
# and see if we hit any errors:

foreach my $fn (@files)
{
	my $c = RF::Component->load("$datadir/$fn");

	foreach my $fmt (qw/MA RI DB/)
	{
		# Exclude Z, it is prone to singularities 
		# (and I think that is expected, but patches welcome!)
		foreach my $param (qw/S Y A/)
		{
			foreach my $hz (qw/khz MHz GHz/) # mixed case
			{
				$c->save($tfn,
					output_fmt => $fmt,
					param_type => $param,
					output_f_unit => $hz);

				my $c2 = RF::Component->load($tfn);

				verify_sum($c->S, $c2->S, "$fn: $param $fmt $hz: S", $tolerance);
				verify_sum($c->Y, $c2->Y, "$fn: $param $fmt $hz: Y", $tolerance);
				verify_sum($c->A, $c2->A, "$fn: $param $fmt $hz: A", $tolerance);

				# Frequency tolerances aren't quite as tight
				# when scaling between SI units, but this is OK
				# since even 1e-3 Hz (milli-Hz) is negligable.
				verify_max($c->freqs, $c2->freqs, "$fn: $param $fmt $hz: freqs", 1e-3);
			}
		}

	}
}

sub verify_sum
{
	my ($m, $inverse, $msg, $tolerance) = @_;

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$msg: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$msg: imag error ($im_err) < $tolerance");
}

sub verify_max
{
	my ($m, $inverse, $msg, $tolerance) = @_;

	my $re_err = max(($m-$inverse)->re->abs);
	my $im_err = max(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$msg: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$msg: imag error ($im_err) < $tolerance");
}
