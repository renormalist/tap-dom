package TAP::DOM::Archive;
# ABSTRACT: Handle TAP:Archive files

use 5.006;
use strict;
use warnings;

sub TO_JSON {
    require Data::Structure::Util;
    require Cpanel::JSON::XS;
    require Storable;

    my $copy = Storable::dclone($_[0]);
    return  Cpanel::JSON::XS::encode_json(Data::Structure::Util::unbless($copy));
}

sub new {
        # hash or hash ref
        my $class = shift;

        my %args = (@_ == 1) ? %{$_[0]} : @_;

        # Drop arguments which don't make sense here and would confuse
        # TAP::Parser called via TAP::DOM later.
        delete $args{tap};
        delete $args{sources};
        delete $args{exec};

        require TAP::DOM;
        my $tap_documents = _read_tap_from_archive(\%args);
        my $tap_dom_list  = {
            meta => $tap_documents->{meta},
            dom  => [ map { TAP::DOM->new(tap => $_) } @{$tap_documents->{tap}} ],
        };
        return bless $tap_dom_list, $class;
}

sub _read_tap_from_archive
{
        my ($args) = @_;

        require Archive::Tar;
        require YAML::Tiny;
        require IO::String;
        require IO::Zlib;

        my $content;
        if ($args->{filecontent}) {
            $content = $args->{filecontent};
        } else {
            $content = do {
                local $/;
                open my $F, '<', $args->{source} or die 'Can not read '.$args->{source};
                <$F>
            };
        }

        # some stacking to enable Archive::Tar read compressed in-memory string
        my $TARSTR       = IO::String->new($content);
        my $TARZ         = IO::Zlib->new($TARSTR, "rb");
        my $tar          = Archive::Tar->new($TARZ);

        my $meta         = YAML::Tiny::Load($tar->get_content("meta.yml"));
        my @tap_sections = map {
            # try different variants of filenames that meta.yml gave us
            my $f1 = $_;                  # original name as-is
            my $f2 = $_; $f2 =~ s,^\./,,; # force no-leading-dot
            my $f3 = $_; $f3 = "./$_";    # force    leading-dot
            local $Archive::Tar::WARN = 0;

            my $tap;
            $tap = "# Bummer! No tar."    unless defined $tar; # no error balloon hint
            $tap = $tar->get_content($f1) unless defined $tap;
            $tap = $tar->get_content($f2) unless defined $tap;
            $tap = $tar->get_content($f3) unless defined $tap;
            $tap;
        } @{$meta->{file_order}};
        return {
            meta => $meta,
            tap  => \@tap_sections,
        };
}

1; # End of TAP::DOM::Archive

__END__

=head1 SYNOPSIS

 # Create a DOM from TAP archive file
 use TAP::DOM::Archive;
 my $tapdom = TAP::DOM::Archive->new( source => $taparchive_filename );
 print Dumper($tapdom);

=head1 DESCRIPTION

This is a frontend to L<TAP::DOM|TAP::DOM> which handles TAP::Archive
files. It reads the archive file and returns an array of TAP::DOMs.

=head1 Super DOM

The resulting TAP::DOM::Archive data structure looks like this:

 $VAR1 = bless( {
                  'meta' => {
                              'file_order' => [
                                                't/some-test.t',
                                                # ... more ...
                                              ],
                              'file_attributes' => [
                                                   {
                                                     'end_time' => '1288275207.07508',
                                                     'start_time' => '1288275206.97027',
                                                     'description' => 't/some-test.t'
                                                   },
                                                   # ... more ...
                                                 ],
                              'start_time' => '1288275206',
                              'stop_time' => '1288275207',
                            },
                  'dom' => [
                             bless( {...}, 'TAP::DOM' ),
                             bless( {...}, 'TAP::DOM' ),
                             # ... more ...
                           ],

=head1 METHODS

=head2 new

Constructor which immediately triggers reading the TAP archive file
and parsing its contained TAP files via TAP::Parser. It returns an
array of the extracted TAP::DOMs.

All parameters are passed through to TAP::DOM, except C<source> which
specifies the file to parse and C<tap> which is ignored.

=head2 TO_JSON

Returns JSON formatted string based on L<Cpanel::JSON::XS>.

Usually be used implicitely by JSON aware fromeworks like Mojo.

=cut
