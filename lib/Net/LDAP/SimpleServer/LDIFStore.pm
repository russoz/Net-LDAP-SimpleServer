package Net::LDAP::SimpleServer::LDIFStore;

use strict;
use warnings;
use diagnostics;

# ABSTRACT: Data store to support Net::LDAP::SimpleServer

# VERSION

use Carp;
use UNIVERSAL::isa;
use Scalar::Util qw(blessed reftype);
use Net::LDAP::LDIF;

sub new {
    my ( $class, $param ) = @_;
    my $self = bless( { list => undef }, $class );

    croak 'Must pass parameter' unless $param;

    $self->load($param);

    return $self;
}

sub load {
    my ( $self, $param ) = @_;

    croak 'Must pass parameter!' unless $param;

    $self->{ldifobj} = _open_ldif($param);
    $self->{list}    = _load_ldif( $self->{ldifobj} );
}

sub ldif {
    my $self = shift;
    return $self->{ldifobj};
}

#
# opens a filename, a file-handle, or a Net::LDAP::LDIF object
#
sub _open_ldif {
    my $param = shift // '';

    return $param if blessed($param) && $param->isa('Net::LDAP::LDIF');

    my $reftype = reftype($param) // '';
    if ( $reftype eq 'HASH' ) {
        croak q{Hash parameter must contain a "ldif" parameter}
          unless exists $param->{ldif};

        return Net::LDAP::LDIF->new(
            $param->{ldif},
            'r',
            (
                exists $param->{ldif_options}
                ? %{ $param->{ldif_options} }
                : undef
            )
        );
    }

    # Then, it must be a filename
    croak q{Cannot find file "} . $param . q{"} unless -r $param;

    return Net::LDAP::LDIF->new($param);
}

#
# loads a LDIF file
#
sub _load_ldif {
    my $ldif = shift;

    my @list = ();
    while ( not $ldif->eof() ) {
        my $entry = $ldif->read_entry();
        if ( $ldif->error() ) {
            print STDERR "Error msg: ",    $ldif->error(),       "\n";
            print STDERR "Error lines:\n", $ldif->error_lines(), "\n";
            next;
        }

        push @list, $entry;
    }
    $ldif->done();

    my @sortedlist = sort { uc( $a->dn() ) cmp uc( $b->dn() ) } @list;

    return \@sortedlist;
}

sub filter {
    my ( $self, $sub ) = @_;
    return () unless $self->{list};

    my @list = @{ $self->{list} };

    foreach my $index ( 0 .. $#list ) {
        delete $list[$index] unless $sub->( $list[$index] );
    }
    return @list;
}

1;    # Magic true value required at end of module

__END__

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer::LDIFStore;

    my $store = Net::LDAP::SimpleServer::LDIFStore->new();
    $store->load( "data.ldif" );

    my $store =
      Net::LDAP::SimpleServer::LDIFStore->new({ ldif => 'data.ldif' });

    my $ldif = Net::LDAP::LDIF->new( "file.ldif" );
    my $store = Net::LDAP::SimpleServer::LDIFStore->new($ldif);

    my $result = $store->filter( sub {
      $a = shift;
      $a->get_value('cn') =~ m/joe/i;
    } );

=head1 DESCRIPTION

This module provides an interface between Net::LDAP::SimpleServer and a
LDIF file where the data is stored.

As of now, this interface is quite simple, and so is the underlying data
structure, but this can be easily improved in the future.

=head1 CONSTRUCTOR

=over

=item new()

Creates a store with no data in it. It cannot be really used like that, you
B<must> C<< load() >> some data in it first.

=item new( FILE )

Create the data store by reading FILE, which may be the name of a file or an
already open filehandle. It is passed directly to
L<<  Net::LDAP::LDIF >>.

Constructor. Expects either: a filename, a file handle, a hash reference or
a reference to a C<Net::LDAP::LDIF> object.

=item new( HASHREF )

Create the data store using the parameters in HASHREF. The associative-array
referenced by HASHREF B<must> contain a key named C<< ldif >>, which must
point to either a filename or a file handle, and it B<may> contain a key named
C<< ldif_options >>, which may contain optional parameters used in the
3-parameter version of the C<Net::LDAP::LDIF> constructor. The LDIF file will
be used for reading the data.

=item new( LDIF )

Uses an existing C<< Net::LDAP::LDIF >> as the source for the directory data.

=back

=head1 METHODS

=over

=item load( PARAM )

Loads data from a source specified by PARAM. The argument may be in any of the
forms accepted by the constructor, except that it B<must> be specified.

=item ldif()

Returns the underlying C<< Net::LDAP::LDIF >> object.

=item filter( SUBREF )

Returns a list of entries for which the function referenced by SUBREF returns
C<true>.

=back

=for head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.
    =over
    =item C<< Error message here, perhaps with %s placeholders >>
    [Description of error here]
    =item C<< Another error message here >>
    [Description of error here]
    [Et cetera, et cetera]
    =back

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Net::LDAP::SimpleServer requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<< UNIVERSAL::isa >>

L<< Scalar::Util >>

L<< Net::LDAP::LDIF >>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

This store does not yet support writing to a LDIF file, which makes the
C<< Net::LDAP::SimpleServer >> a read-only server.
