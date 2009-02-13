#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap.txt") or die "Cannot read t/some_tap.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = new TAP::DOM( tap => $tap );
#my $tapdata = tapdata( tap => $tap );
print Dumper($tapdata);

is($tapdata->{tests_run},     10,     "tests_run");
is($tapdata->{tests_planned},  8,     "tests_planned");
is($tapdata->{version},       13,     "version");
is($tapdata->{plan},          "1..8", "plan");

is($tapdata->{results}[2]{number},  1,     "[2] number");
is($tapdata->{results}[2]{is_test}, 1,     "[2] is_test");
is($tapdata->{results}[2]{is_ok},   1,     "[2] is_ok");

is($tapdata->{results}[2]{diag}{yaml}[0]{name}, "Hash one",     "[2]{yaml} Hash one");
