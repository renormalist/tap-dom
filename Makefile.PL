use strict;
use warnings;
use inc::Module::Install;

name     'TAP-DOM';
all_from 'lib/TAP/DOM.pm';
author   'Steffen Schwigon <schwigon@cpan.org>';

author_requires 'Module::Install::AuthorTests';

requires 'Test::Harness' => '3.0';
requires 'Data::Dumper';
requires 'parent';
requires 'YAML::Syck';
requires 'Sub::Exporter';
requires 'Class::XSAccessor' => '1.05';

author_tests('xt');
test_requires 'Test::More' => 0.88;

auto_install;

repository 'git://github.com/renormalist/tap-dom.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAP-DOM';

WriteAll;
