#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;

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

is($tapdata->{tests_run},     8,     "tests_run");
is($tapdata->{tests_planned},  6,     "tests_planned");
is($tapdata->{version},       13,     "version");
is($tapdata->{plan},          "1..6", "plan");

is($tapdata->{lines}[2]{number},  1,     "[2] number");
is($tapdata->{lines}[2]{is_test}, 1,     "[2] is_test");
is($tapdata->{lines}[2]{is_ok},   1,     "[2] is_ok");
is($tapdata->{lines}[2]{is_ok},   1,     "[2] is_ok");

is($tapdata->{lines}[2]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");

