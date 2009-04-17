package TAP::DOM;

use strict;
use warnings;

use TAP::Parser;
use TAP::Parser::Aggregator;
use YAML::Syck;
use Data::Dumper;

our $VERSION = '0.03';

# plain function approach
sub new {
        # hash or hash ref
        my $class = shift;
        my %args = @_ == 1 ? %{$_[0]} : @_;

        my @lines;
        my $plan;
        my $version;
        my @pragmas;
        my $bailout;

        my $parser = new TAP::Parser( { %args } );

        my $aggregate = new TAP::Parser::Aggregator;
        $aggregate->start;

        while ( my $result = $parser->next ) {
                no strict 'refs';

                my %entry = ();

                # test info
                $entry{$_} = $result->$_ foreach (qw(raw
                                                     as_string
                                                   ));

                if ($result->is_test) {
                        $entry{$_} = $result->$_ foreach (qw(type
                                                             directive
                                                             explanation
                                                             number
                                                             description
                                                           ));
                        $entry{$_} = $result->$_ ? 1 : 0 foreach (qw(is_ok
                                                                     is_unplanned
                                                                   ));
                }

                # plan
                $plan = $result->as_string if $result->is_plan;

                # meta info
                $entry{$_} = $result->$_ ? 1 : 0 foreach (qw(has_skip has_todo));
                $entry{$_} = $result->$_ ? 1 : 0
                    foreach (qw( is_pragma
                                 is_comment
                                 is_bailout
                                 is_plan
                                 is_version
                                 is_yaml
                                 is_unknown
                                 is_test
                                 is_bailout
                              ));
                $entry{is_actual_ok} = $result->has_todo && $result->is_actual_ok ? 1 : 0;
                $entry{data} = $result->data if $result->is_yaml;

                # yaml becomes content of line before
                #
                # TODO this is actually a bad hack only needed for Data::DPath. It should be banned.
                # and instead provide additionall "typed interconnections" between lines.
                # One E.g.: belongs_to => (reference of line before)
                # $lines[-1]->{diag}{yaml} = $result->data if $result->is_yaml;

                # Wooosh!
                if ($result->is_yaml or $result->is_comment)
                {
                        # embed yaml/comment lines to the line before,
                        # nesting like in
                        # http://cpansearch.perl.org/src/RJBS/Pod-Elemental-0.003/t/nested-over.t
                        push @{ $lines[-1]->{_children} }, \%entry;
                } else
                {
                        push @lines, \%entry;
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

That's useful when you want to analyze the TAP in detail with "data
exploration tools", like L<Data::DPath|Data::DPath>.

``Reliable'' means that this structure is kind of an API that will not
change, so your data tools can, well, rely on it.

=head1 FUNCTIONS

=head2 new

Constructor which immediately triggers parsing the TAP via TAP::Parser
and returns a big data structure containing the extracted results.

Parameters are passed through to TAP::Parser, usually one of these:

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
