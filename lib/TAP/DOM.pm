package TAP::DOM;

use strict;
use warnings;

use TAP::Parser;
use YAML::Syck;
use Data::Dumper;

#use Sub::Exporter -setup => { exports => [ 'tapdata' ] };

our $VERSION = '0.01';

# plain function approach
sub new {
        # hash or hash ref
        my $class = shift;
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
                #
                # TODO this is actually a bad hack only needed for Data::DPath. It should be banned.
                # and instead provide additionall "typed interconnections" between lines.
                # One E.g.: belongs_to => (reference of line before)
                $results[-1]->{diag}{yaml} = $result->data if $result->is_yaml;

                # Wooosh!
                push @results, \%entry;
        }
        @pragmas = $parser->pragmas;

        my $tapdata = {
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
tools". I, for instance, use it with L<Data::DPath|Data::DPath>.

``Reliable'' means that this structure is kind of an API that will not
change, so your data tools (e.g. Data::DPath paths) can rely on it.

=head1 ALPHA WARNING

The module is useable and already really used but please do not rely
on it yet in production environment. There is at least one outstanding
issue that needs clarification. See L</"SOME SPECIAL HANDLING"> below.

=head1 FUNCTIONS

=head2 new

Constructor which immediately triggers parsing the TAP via TAP::Parser
and returns a big data structure containing the extracted results.

Parameters are passed through to TAP::Parser, usually one of these:

  tap => $some_tap_string

or

  source => $test_file

But there are more, see L<TAP::Parser|TAP::Parser>.

=head1 SOME SPECIAL HANDLING

=head2 yaml diag

Currently, YAML diagnostics are assigned to the line before.

It is actually a bad hack only needed for my personal style of using
Data::DPath to make evaluating the diagnostics easier when they are in
the same record as to where they semantically belong.

Anyway, it should be banned and instead additional "typed
interconnections" between lines should be established, e.g.:

 belongs_to => (reference of line before).

=head1 AUTHOR

Steffen Schwigon, C<< <schwigon at cpan.org> >>

=head1 BUGS

Currently I'm not yet sure whether the structure is already
``reliable''. I will probably call it version 1.0 once I'm fine with
it.

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


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

