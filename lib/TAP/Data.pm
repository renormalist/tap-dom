package TAP::Data;

use strict;
use warnings;

use TAP::Parser;
use YAML::Syck;

our $VERSION = '0.01';

sub tap2data {
        my %args = @_;

        my @results;
        my $plan;
        my $version;
        my @pragmas;
        my $bailout;

        my $parser = new TAP::Parser( { %args } );
        while ( my $result = $parser->next ) {
                #print ".";
                #print $result->as_string;

                no strict 'refs';

                my %entry = ();

                # basic info
                foreach (qw(type as_string raw directive
                            explanation number description))
                {
                        $entry{$_} = $result->$_ unless ( $result->is_plan or $result->is_comment or $result->is_version or $result->is_yaml);
                }

                # only occasionally basic info
                foreach (qw(pragma comment bailout)) {
                        my $meth = "is_$_";
                        $entry{$meth} = $result->$meth ? 1 : 0;
                }

                # more basic info
                foreach (qw(ok unplanned)) {
                        my $meth = "is_$_";
                        $entry{$meth} = $result->$meth ? 1 : 0 unless ( $result->is_plan or $result->is_comment or $result->is_version or $result->is_yaml);
                }
                $entry{is_actual_ok} = $result->is_actual_ok if $result->has_todo;

                # even more basic info
                foreach (qw(skip todo)) {
                        my $meth = "has_$_";
                        $entry{$meth} = $result->$meth ? 1 : 0;
                }

                # carve out plan
                $plan = $result->as_string if $result->is_plan;

                # yaml becomes content of line before
                $results[-1]->{diag}{yaml} = Load($entry{as_string}) if ($result->is_yaml);

                # pragmas
                my @pragmas = $parser->pragmas;# unless $result->is_plan;
                push @{$entry{pragmas}}, \@pragmas;

                # Wooosh!
                push @results, \%entry;
        }

        my $tapdata = {
                       tap => {
                               plan          => $plan,
                               results       => \@results,
                               version       => $parser->version,
                               tests_planned => $parser->tests_planned,
                               tests_run     => $parser->tests_run,
                               skip_all      => $parser->skip_all,
                               start_time    => $parser->start_time,
                               end_time      => $parser->end_time,
                              },
                      };

}


1; # End of TAP::Data

__END__

=pod

=head1 NAME

TAP::Data - TAP as a consistent data structure.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use TAP::Data;
    use Data::Dumper;
    
    my $tapdata = TAP::Data->new( source => $source );
    print Dumper($tapdata);

=head1 FUNCTIONS

=head2 new

This is the only interesting functions. Every actions are already
triggered on instancing.

=head1 AUTHOR

Steffen Schwigon, C<< <schwigon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tap-data at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAP-Data>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




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

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

