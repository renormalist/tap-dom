package TAP::DOM::Config;

use 5.006;
use strict;
use warnings;

use Class::XSAccessor
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( ignore
                        ignorelines
                        usebitsets
                     )];

1;

__END__

=pod

=head1 NAME

TAP::DOM::Config - Accessors for TAP::DOM specific parse config

=head1 DESCRIPTION

The C<tapdom_config> part covers TAP::DOM specific parse options.

=head1 ACCESSORS

=head2 ignore

=head2 ignorelines

=head2 usebitsets

=cut
