#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TAP::Data' );
}

diag( "Testing TAP::Data $TAP::Data::VERSION, Perl $], $^X" );
