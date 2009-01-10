#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use TAP::Data;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap.txt") or die "Cannot read t/some_tap.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = TAP::Data::tap2data( tap => $tap );
print Dumper($tapdata);

ok(1, "dummy");
