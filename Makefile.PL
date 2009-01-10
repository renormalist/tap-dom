use strict;
use warnings;
use inc::Module::Install;

name     'TAP-Data';
all_from 'lib/TAP/Data.pm';
author   'Steffen Schwigon <schwigon@cpan.org>';

requires 'perl'            => 5.010;
requires 'parent'          => 0;
requires 'Test::Harness'   => 3.0;

test_requires 'Test::More';
tests_recursive;

auto_install;

makemaker_args dist => { PREOP => 'pod2text lib/TAP/Data.pm > README' } ;

WriteAll;

