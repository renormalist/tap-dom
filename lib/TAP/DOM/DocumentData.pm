package TAP::DOM::DocumentData;
# ABSTRACT: TAP::DOM::DocumentData - Accessors for key/value document data

use 5.006;
use strict;
use warnings;

sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{$key} = $value;
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

1;

__END__

=head1 DESCRIPTION

A document can contain comment lines which actually contain key/value
data, like this:

  # Test-vendor-id:  GenuineIntel
  # Test-cpu-model:  Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz
  # Test-cpu-family: 6
  # Test-flags.fpu:  1

Those lines are converted into a hash by splitting it at the C<:>
delimiter and stripping the C<# Test-> prefix. The resulting data
structure looks like this:

  # ... inside TAP::DOM ...
  document_data => {
                    'vendor-id' => 'GenuineIntel',
                    'cpu-model' => #Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz',
                    'cpu-family' => 6,
                    'flags.fpu' =>  1,
                   },

=head1 ACCESSORS & METHODS

=head2 new - constructor

=head2 set($key, $value)

Sets the value for a key.

=head2 get($key)

Returns the value for a key.

=cut
