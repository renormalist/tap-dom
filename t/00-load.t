#!perl -T

use Test::More tests => 1;

BEGIN { use_ok( 'TAP::DOM' ) }

diag( "Testing TAP::DOM $TAP::DOM::VERSION, Perl $], $^X" );
