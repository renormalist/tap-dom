package TAP::Data;

use strict;
use warnings;

use TAP::Parser;
use YAML::Syck;
use Data::Dumper;

use Sub::Exporter -setup => { exports => [ 'tapdata' ] };

our $VERSION = '0.01';

# plain function approach
sub tapdata {
        # hash or hash ref
        my %args = @_ == 1 ? %{$_[0]} : @_;

        my @results;
        my $plan;
        my $version;
        my @pragmas;
        my $bailout;

        my $parser = new TAP::Parser( { %args } );
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

                # yaml becomes content of line before
                $results[-1]->{diag}{yaml} = $result->data if $result->is_yaml;

                # Wooosh!
                push @results, \%entry;
        }
        @pragmas = $parser->pragmas;

        my $tapdata = {
                       tap => {
                               plan          => $plan,
                               results       => \@results,
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
                              },
                      };
}


1; # End of TAP::Data

__END__

=pod

=head1 NAME

TAP::Data - TAP as a consistent data structure.

=head1 SYNOPSIS

    use TAP::Data 'tapdata';
    my $tapdata = tapdata( tap => $tap ); # same options as TAP::Parser
    print Dumper($tapdata);


=head1 DESCRIPTION

The only purpose of this module is
A) to define a B<reliable> data structure and
B) to help create this structure from TAP.

That's useful when you want to analyze the TAP in detail with "data
tools", e.g., I want to use it with L<Data::DPath|Data::DPath>.

``Reliable'' means that this structure is kind of an API that will not
change, so your data tools (e.g. Data::DPath paths) can rely on it.


=head1 FUNCTIONS

=head2 tapdata

This is the only interesting function. It triggers parsing the TAP via
TAP::Parser and returns a big data structure containing the extracted
results. No rocket science, just that.

Parameters are passed through to TAP::Parser, usually one of these:

  tap => $some_tap_string

or

  source => $test_file

But there are more, see L<TAP::Parser|TAP::Parser>.

=head1 SOME SPECIAL HANDLING

=head2 yaml diag

YAML diagnostics are assigned to the line before.

I'm not yet sure whether that's a good idea, but it makes evaluating
the diagnostics easier when they are in the same record as to where
they should belong.

I admit that it looks somewhat inconsistent to have only the yaml data
assigned to the entry before and everything else in the yaml entry
itself.

I'm not sure, help me with feedback.

=head1 AUTHOR

Steffen Schwigon, C<< <schwigon at cpan.org> >>

=head1 BUGS

Currently I'm not yet sure whether the structure is already
``reliable''. I will probably call it version 1.0 once I'm fine with
it.

Please report any bugs or feature requests to C<bug-tap-data at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAP-Data>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TAP::Data


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TAP-Data>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TAP-Data>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TAP-Data>

=item * Search CPAN

L<http://search.cpan.org/dist/TAP-Data>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

