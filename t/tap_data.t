#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use TAP::Data 'tapdata';
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap.txt") or die "Cannot read t/some_tap.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = tapdata( tap => $tap );
#my $tapdata = tapdata( source => '../data-dpath/t/data_dpath.t' );
print Dumper($tapdata);

is($tapdata->{tap}{tests_run},     10,     "tests_run");
is($tapdata->{tap}{tests_planned},  8,     "tests_planned");
is($tapdata->{tap}{version},       13,     "version");
is($tapdata->{tap}{plan},          "1..8", "plan");

is($tapdata->{tap}{results}[2]{number},  1,     "[2] number");
is($tapdata->{tap}{results}[2]{is_test}, 1,     "[2] is_test");
is($tapdata->{tap}{results}[2]{is_ok},   1,     "[2] is_ok");

is($tapdata->{tap}{results}[2]{diag}{yaml}[0]{name}, "Hash one",     "[2]{yaml} Hash one");
