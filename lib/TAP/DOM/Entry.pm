package TAP::DOM::Entry;

use 5.006;
use strict;
use warnings;

require TAP::DOM;

sub new {
        # hash or hash ref
        my $class = shift;
        my %args = @_ == 1 ? %{$_[0]} : @_;

        my $entry = { };
        return bless $entry, $class;
}

BEGIN {
    no strict 'refs';

    for my $method (qw( is_plan is_ok is_test is_comment is_unknown is_actual_ok is_version
                        is_pragma is_unplanned is_bailout is_yaml has_skip has_todo ))
    {
            *{$method} = sub {
                    my ($self) = @_;
                    defined $self->{is_has} ? $self->{is_has} | ${"TAP::DOM::".uc($method)} : $self->{$method}
            }
    }
}

# sub is_test {
#     my ($self) = @_;
#     defined $self->{is_has} ? $self->{is_has} | $TAP::DOM::IS_TEST : $self->{is_test};
# }

1;
