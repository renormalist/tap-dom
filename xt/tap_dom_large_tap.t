#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

use TAP::DOM;
use Data::Dumper;
use Benchmark ':all', ':hireswallclock';
use Devel::Size 'total_size';

my $tap;
{
        local $/;
        open (TAP, "< xt/regexp-common.tap") or die "Cannot read xt/regexp-common.tap";
        $tap = <TAP>;
        close TAP;
}

my $tapdata;

my $count = 3;
my $t = timeit ($count, sub { $tapdata = new TAP::DOM( tap => $tap ) });
my $n = $t->[5];
my $throughput = $n / $t->[0];

diag "Data size: ".total_size ($tapdata);

diag Dumper($t);
is($tapdata->{tests_run},      41499,     "tests_run");
is($tapdata->{tests_planned},  41499,     "tests_planned");
is($tapdata->{version},        12,        "version");
is($tapdata->{plan},          "1..41499", "plan");

is($tapdata->{lines}[41483]{number},  41483,     "[2] number");
is($tapdata->{lines}[41483]{is_test}, 1,     "[2] is_test");
is($tapdata->{lines}[41483]{is_ok},   1,     "[2] is_ok");
is($tapdata->{lines}[41483]{is_ok},   1,     "[2] is_ok");
is($tapdata->{lines}[41483]{description},  '- "-----Another /* comment\n"              ([SB/F/NM] ZZT-OOP)', "[41483] description");
is($tapdata->{lines}[41483]{raw}, 'ok 41483 - "-----Another /* comment\n"              ([SB/F/NM] ZZT-OOP)', "[41483] raw");

ok(1, "benchmark");
print "  ---\n";
print "  benchmark:\n";
print "    timestr:    ".timestr($t), "\n";
print "    wallclock:  $t->[0]\n";
print "    usr:        $t->[1]\n";
print "    sys:        $t->[2]\n";
print "    throughput: $throughput\n";
print "  ...\n";

