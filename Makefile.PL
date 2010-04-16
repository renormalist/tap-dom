use strict;
use warnings;
use inc::Module::Install;

name     'TAP-DOM';
all_from 'lib/TAP/DOM.pm';
author   'Steffen Schwigon <schwigon@cpan.org>';

requires 'Test::Harness' => 3.0;
requires 'Data::Dumper';
requires 'YAML::Syck';
requires 'Sub::Exporter';

test_requires 'Test::More';
tests_recursive;

auto_install;

repository 'git://github.com/renormalist/tap-dom.git';

WriteAll;
