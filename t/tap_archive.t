#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM::Archive;
use Data::Dumper;
use Scalar::Util 'blessed';

my $source = 't/tap-archive-1.tgz';

my $tapdom = TAP::DOM::Archive->new (source => $source);

#diag "tapdom: ".Dumper($tapdom);
#diag "tojson: ".Dumper($tapdom->TO_JSON);

is (@{$tapdom->{dom}},              4, "count tap docs");
is (@{$tapdom->{meta}{file_order}}, 4, "count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "meta file 3");

is (blessed($tapdom),               'TAP::DOM::Archive',    'tapdom blessed by default');
is (blessed($tapdom->TO_JSON),      undef,                  'json unblessed by default');

done_testing();
