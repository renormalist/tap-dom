package TAP::DOM;

use 5.006;
use strict;
use warnings;

use TAP::DOM::Entry;
use TAP::Parser;
use TAP::Parser::Aggregator;
use YAML::Syck;
use Data::Dumper;

our $VERSION = '0.08';

our $IS_PLAN      = 1;
our $IS_OK        = 2;
our $IS_TEST      = 4;
our $IS_COMMENT   = 8;
our $IS_UNKNOWN   = 16;
our $IS_ACTUAL_OK = 32;
our $IS_VERSION   = 64;
our $IS_PRAGMA    = 128;
our $IS_UNPLANNED = 256;
our $IS_BAILOUT   = 512;
our $IS_YAML      = 1024;
our $HAS_SKIP     = 2048;
our $HAS_TODO     = 4096;

use Exporter 'import';
our @EXPORT_OK = qw( $IS_PLAN
                     $IS_OK
                     $IS_TEST
                     $IS_COMMENT
                     $IS_UNKNOWN
                     $IS_ACTUAL_OK
                     $IS_VERSION
                     $IS_PRAGMA
                     $IS_UNPLANNED
                     $IS_BAILOUT
                     $IS_YAML
                     $HAS_SKIP
                     $HAS_TODO
                  );

our %EXPORT_TAGS = (constants => [ qw( $IS_PLAN
                                       $IS_OK
                                       $IS_TEST
                                       $IS_COMMENT
                                       $IS_UNKNOWN
                                       $IS_ACTUAL_OK
                                       $IS_VERSION
                                       $IS_PRAGMA
                                       $IS_UNPLANNED
                                       $IS_BAILOUT
                                       $IS_YAML
                                       $HAS_SKIP
                                       $HAS_TODO
                                    ) ] );

sub new {
        # hash or hash ref
        my $class = shift;
        my %args = @_ == 1 ? %{$_[0]} : @_;

        my @lines;
        my $plan;
        my $version;
        my @pragmas;
        my $bailout;

        my %IGNORE      = map { $_ => 1 } @{$args{ignore}};
        my $IGNORELINES = $args{ignorelines};
        my $USEBITSETS  = $args{usebitsets};
        delete $args{ignore};
        delete $args{ignorelines};
        delete $args{usebitsets};

        my $parser = new TAP::Parser( { %args } );

        my $aggregate = new TAP::Parser::Aggregator;
        $aggregate->start;

        while ( my $result = $parser->next ) {
                no strict 'refs';

                next if $IGNORELINES && $result->raw =~ m/$IGNORELINES/;

                my $entry = TAP::DOM::Entry->new;

                # test info
                foreach (qw(raw as_string )) {
                        $entry->{$_} = $result->$_ unless $IGNORE{$_};
                }

                if ($result->is_test) {
                        foreach (qw(type directive explanation number description )) {
                                $entry->{$_} = $result->$_ unless $IGNORE{$_};
                        }
                        foreach (qw(is_ok is_unplanned )) {
                                if ($USEBITSETS) {
                                        $entry->{is_has} |= ${uc $_} unless $IGNORE{$_};
                                } else {
                                        $entry->{$_} = $result->$_ ? 1 : 0 unless $IGNORE{$_};
                                }
                        }
                }

                # plan
                $plan = $result->as_string if $result->is_plan;

                # meta info
                foreach ((qw(has_skip has_todo))) {
                        if ($USEBITSETS) {
                                $entry->{is_has} |= ${uc $_} unless $IGNORE{$_};
                        } else {
                                $entry->{$_} = $result->$_ ? 1 : 0 unless $IGNORE{$_};
                        }
                }
                # Idea:
                # use constants
                # map to constants
                # then loop
                foreach (qw( is_pragma is_comment is_bailout is_plan
                             is_version is_yaml is_unknown is_test is_bailout ))
                {
                        if ($USEBITSETS) {
                                $entry->{is_has} |= ${uc $_} unless $IGNORE{$_};
                        } else {
                                $entry->{$_} = $result->$_ ? 1 : 0 unless $IGNORE{$_};
                        }
                }
                if (! $IGNORE{is_actual_ok}) {
                        my $is_actual_ok = $result->has_todo && $result->is_actual_ok ? 1 : 0;
                        if ($USEBITSETS) {
                                $entry->{is_has} |= $is_actual_ok ? $IS_ACTUAL_OK : 0;
                        } else {
                                $entry->{is_actual_ok} = $is_actual_ok;
                        }
                }
                $entry->{data}         = $result->data if $result->is_yaml && !$IGNORE{data};


                # yaml and comments are taken as children of the line before
                if ($result->is_yaml or $result->is_comment and @lines)
                {
                        push @{ $lines[-1]->{_children} }, $entry;
                }
                else
                {
                        push @lines, $entry;
                }
        }
        @pragmas = $parser->pragmas;

        $aggregate->add( main => $parser );
        $aggregate->stop;

        my %summary = (
                       failed          => scalar $aggregate->failed,
                       parse_errors    => scalar $aggregate->parse_errors,
                       passed          => scalar $aggregate->passed,
                       skipped         => scalar $aggregate->skipped,
                       todo            => scalar $aggregate->todo,
                       todo_passed     => scalar $aggregate->todo_passed,
                       wait            => scalar $aggregate->wait,
                       exit            => scalar $aggregate->exit,
                       elapsed         => $aggregate->elapsed,
                       elapsed_timestr => $aggregate->elapsed_timestr,
                       all_passed      => $aggregate->all_passed ? 1 : 0,
                       status          => $aggregate->get_status,
                       total           => $aggregate->total,
                       has_problems    => $aggregate->has_problems ? 1 : 0,
                       has_errors      => $aggregate->has_errors ? 1 : 0,
                      );

        my %tapdom_config = (
                             ignore      => \%IGNORE,
                             ignorelines => $IGNORELINES,
                             usebitsets  => $USEBITSETS,
                            );

        my $tapdata = {
                       plan          => $plan,
                       lines         => \@lines,
                       pragmas       => \@pragmas,
                       tests_planned => $parser->tests_planned,
                       tests_run     => $parser->tests_run,
                       version       => $parser->version,
                       is_good_plan  => $parser->is_good_plan,
                       skip_all      => $parser->skip_all,
                       start_time    => $parser->start_time,
                       end_time      => $parser->end_time,
                       has_problems  => $parser->has_problems,
                       exit          => $parser->exit,
                       parse_errors  => [ $parser->parse_errors ],
                       summary       => \%summary,
                       tapdom_config => \%tapdom_config,
                      };
        return bless $tapdata, $class;
}


1; # End of TAP::DOM

__END__

=pod

=head1 NAME

TAP::DOM - TAP as document data structure.

=head1 SYNOPSIS

 use TAP::DOM;
 my $tapdata = new TAP::DOM( tap => $tap ); # same options as TAP::Parser
 print Dumper($tapdata);


=head1 DESCRIPTION

The purpose of this module is
A) to define a B<reliable> data structure and
B) to help create this structure from TAP.

That is useful when you want to analyze the TAP in detail with "data
exploration tools", like L<Data::DPath|Data::DPath>.

``Reliable'' means that this structure is kind of an API that will not
change, so your data tools can, well, rely on it.

=head1 FUNCTIONS

=head2 new

Constructor which immediately triggers parsing the TAP via TAP::Parser
and returns a big data structure containing the extracted results.

All parameters (except C<ignore> and C<ignorelines>, see section "HOW
TO STRIP DETAILS") are passed through to TAP::Parser. Usually just one
of those:

  tap => $some_tap_string

or

  source => $test_file

But there are more, see L<TAP::Parser|TAP::Parser>.

=head1 STRUCTURE

The data structure is basically a nested hash/array structure with
keys named after the functions of TAP::Parser that you normally would
use to extract results.

See the TAP example file in C<t/some_tap.txt> and its corresponding
result structure in C<t/some_tap.dom>.

Here is a slightly commented and beautified excerpt of
C<t/some_tap.dom>. Due to it's beeing manually washed for readability
there might be errors in it, so for final reference, dump a DOM by
yourself.

 bless( {
  'version'       => 13,
  'plan'          => '1..6',
  'tests_planned' => 6
  'tests_run'     => 8,
  'is_good_plan'  => 0,
  'has_problems'  => 2,
  'skip_all'      => undef,
  'parse_errors'  => [
                      'Bad plan.  You planned 6 tests but ran 8.'
                     ],
  'pragmas'       => [
                      'strict'
                     ],
  'exit'          => 0,
  'start_time'    => '1236463400.25151',
  'end_time'      => '1236463400.25468',
  # for the meaning of this summary see also TAP::Parser::Aggregator.
  'summary' => {
                 'status'          => 'FAIL',
                 'total'           => 8,
                 'passed'          => 6,
                 'failed'          => 2,
                 'all_passed'      => 0,
                 'skipped'         => 1,
                 'todo'            => 4,
                 'todo_passed'     => 2,
                 'parse_errors'    => 1,
                 'has_errors'      => 1,
                 'has_problems'    => 1,
                 'exit'            => 0,
                 'wait'            => 0
                 'elapsed'         => bless( [
                                              0,
                                              '0',
                                              0,
                                              0,
                                              0,
                                              0
                                             ], 'Benchmark' ),
                 'elapsed_timestr' => ' 0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)',
               },
  'lines' => [
              {
               'is_actual_ok' => 0,
               'is_bailout'   => 0,
               'is_comment'   => 0,
               'is_plan'      => 0,
               'is_pragma'    => 0,
               'is_test'      => 0,
               'is_unknown'   => 0,
               'is_version'   => 1,                      # <---
               'is_yaml'      => 0,
               'has_skip'     => 0,
               'has_todo'     => 0,
               'raw'          => 'TAP version 13'
               'as_string'    => 'TAP version 13',
              },
              {
                'is_actual_ok' => 0,
                'is_bailout'   => 0,
                'is_comment'   => 0,
                'is_plan'      => 1,                     # <---
                'is_pragma'    => 0,
                'is_test'      => 0,
                'is_unknown'   => 0,
                'is_version'   => 0,
                'is_yaml'      => 0,
                'has_skip'     => 0,
                'has_todo'     => 0,
                'raw'          => '1..6'
                'as_string'    => '1..6',
              },
              {
                'is_actual_ok' => 0,
                'is_bailout'   => 0,
                'is_comment'   => 0,
                'is_ok'        => 1,                     # <---
                'is_plan'      => 0,
                'is_pragma'    => 0,
                'is_test'      => 1,                     # <---
                'is_unknown'   => 0,
                'is_unplanned' => 0,
                'is_version'   => 0,
                'is_yaml'      => 0,
                'has_skip'     => 0,
                'has_todo'     => 0,
                'number'       => '1',                   # <---
                'type'         => 'test',
                'raw'          => 'ok 1 - use Data::DPath;'
                'as_string'    => 'ok 1 - use Data::DPath;',
                'description'  => '- use Data::DPath;',
                'directive'    => '',
                'explanation'  => '',
                '_children'    => [
                                   # ----- children are the subsequent comment/yaml lines -----
                                   {
                                     'is_actual_ok' => 0,
                                     'is_unknown'   => 0,
                                     'has_todo'     => 0,
                                     'is_bailout'   => 0,
                                     'is_pragma'    => 0,
                                     'is_version'   => 0,
                                     'is_comment'   => 0,
                                     'has_skip'     => 0,
                                     'is_test'      => 0,
                                     'is_yaml'      => 1,              # <---
                                     'is_plan'      => 0,
                                     'raw'          => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...'
                                     'as_string'    => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...',
                                     'data'         => [
                                                        {
                                                          'value' => '1',
                                                          'name' => 'Hash one'
                                                        },
                                                        {
                                                          'value' => '2',
                                                          'name' => 'Hash two'
                                                        }
                                                       ],
                                 }
                               ],
              },
              {
                'is_actual_ok' => 0,
                'is_bailout'   => 0,
                'is_comment'   => 0,
                'is_ok'        => 1,                     # <---
                'is_plan'      => 0,
                'is_pragma'    => 0,
                'is_test'      => 1,                     # <---
                'is_unknown'   => 0,
                'is_unplanned' => 0,
                'is_version'   => 0,
                'is_yaml'      => 0,
                'has_skip'     => 0,
                'has_todo'     => 0,
                'explanation'  => '',
                'number'       => '2',                   # <---
                'type'         => 'test',
                'description'  => '- KEYs + PARENT',
                'directive'    => '',
                'raw'          => 'ok 2 - KEYs + PARENT'
                'as_string'    => 'ok 2 - KEYs + PARENT',
              },
              # etc., see the rest in t/some_tap.dom ...
             ],
 }, 'TAP::DOM')                                          # blessed


=head1 NESTED LINES

As you can see above, diagnostic lines (comment or yaml) are nested
into the line before under a key C<_children> which simply contains an
array of those comment/yaml line elements.

With this you can recognize where the diagnostic lines semantically
belong.

=head1 HOW TO STRIP DETAILS

You can make the DOM a bit more terse (i.e., less blown up) if you do
not need every detail.

=head2 Strip unneccessary TAP-DOM fields

For this provide the C<ignore> option to new(). It is an array ref
specifying keys that should not be contained in the TAP-DOM. Currently
supported are:

 has_todo
 has_skip
 directive
 as_string
 explanation
 description
 is_unplanned
 is_actual_ok
 is_bailout
 is_unknown
 is_version
 is_bailout
 is_comment
 is_pragma
 is_plan
 is_test
 is_yaml
 is_ok
 number
 type
 raw

Use it like this:

   $tapdom = TAP::DOM->new (tap    => $tap,
                            ignore => [ qw( raw as_string ) ],
                           );

=head2 Strip unneccessary lines

You can ignore complete lines from the input TAP as if they weren't
existing. Of course you can break the TAP with this, so usually you
only apply this to non-TAP lines or diagnostics you are not interested
in.

My primary use-case is TAP with large parts of logfiles included with
a prefixed "## " just for dual-using the TAP also as an archive of the
log. When evaluating the TAP later I leave those log lines out because
they only blow up the memory for the TAP-DOM:

   $tapdom = TAP::DOM->new (tap         => $tap,
                            ignorelines => qr/^## /,
                           );

See C<t/some_tap_ignore_lines.t> for an example.

=head1 AUTHOR

Steffen Schwigon, C<< <schwigon at cpan.org> >>

=head1 BUGS

Currently I'm not yet sure whether the structure is already
``reliable'' and ``stable'' as is stated in the B<DESCRIPTION>. I will
probably call it version C<1.0> once I'm fine with it.

Please report any bugs or feature requests to C<bug-tap-data at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAP-DOM>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TAP::DOM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TAP-DOM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TAP-DOM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TAP-DOM>

=item * Search CPAN

L<http://search.cpan.org/dist/TAP-DOM>

=back


=head1 REPOSITORY

The public repository is hosted on github:

  git clone git://github.com/renormalist/tap-dom.git


=head1 COPYRIGHT & LICENSE

Copyright 2009 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
