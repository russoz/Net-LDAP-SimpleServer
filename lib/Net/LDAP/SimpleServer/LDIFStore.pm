package Net::LDAP::SimpleServer::LDIFStore;

use strict;
use warnings;

# ABSTRACT: Data store to support Net::LDAP::SimpleServer

# VERSION

use 5.010;
use Carp qw/carp croak/;
use UNIVERSAL::isa;
use Scalar::Util qw(blessed reftype);

use Net::LDAP::LDIF;
use Net::LDAP::Util qw/canonical_dn/;

use Net::LDAP::SimpleServer::Constant;

sub new {
    my ( $class, $param ) = @_;
    croak 'Must pass parameter!' unless defined($param);

    # empty defaults
    my $data = {
        ldif_object => undef,
        tree        => {},
    };

    my $self = bless( $data, $class );
    $self->load($param);
    return $self;
}

sub load {
    my ( $self, $param ) = @_;

    croak 'Must pass parameter!' unless $param;

    if ( blessed($param) && $param->isa('Net::LDAP::LDIF') ) {
        $self->{ldif_object} = $param;
    }
    else {
        $self->_open_ldif($param);
    }
    $self->_load_ldif();
    return;
}

sub ldif {
    my $self = shift;
    return $self->{ldif_object};
}

#
# opens a filename, a file-handle, or a Net::LDAP::LDIF object
#
sub _open_ldif {
    my $self = shift;
    my $param = shift // '';

    my $reftype = reftype($param) // '';
    if ( $reftype eq 'HASH' ) {
        croak q{Hash parameter must contain a "ldif" parameter}
          unless exists $param->{ldif};

        $self->{ldif_object} = Net::LDAP::LDIF->new(
            $param->{ldif},
            'r',
            (
                exists $param->{ldif_options}
                ? %{ $param->{ldif_options} }
                : undef
            )
        );
        return;
    }

    # Then, it must be a filename
    croak q{Cannot read file "} . $param . q{"} unless -r $param;

    $self->{ldif_object} = Net::LDAP::LDIF->new($param);
}

sub _make_entry_path {
    my $dn = shift;

    $dn = $dn->dn() if $dn->isa('Net::LDAP::Entry');

    return [ reverse( split( ',', canonical_dn($dn) ) ) ];
}

sub _make_entry {
    my ( $entry, $tree, $current_dn, @path ) = @_;

    $tree = {} unless defined($tree);
    if ( scalar(@path) == 0 ) {
        $tree->{_object} = $entry;
    }
    else {
        my $next = $path[0];
        $tree->{_object} = Net::LDAP::Entry->new($current_dn)
          unless exists $tree->{_object};
        $tree->{$next} = _make_entry(
            $entry, $tree->{$next},
            join( q{,}, $next, $current_dn ),
            @path[ 1 .. $#path ]
        );
    }

    return $tree;
}

sub _add {
    my ( $self, $entry ) = @_;

    my @path = @{ _make_entry_path($entry) };
    my $tree = $self->{tree};
    my $next = $path[0];
    $tree->{$next} = _make_entry( $entry, $tree->{$next}, @path );

    # line above is equivalent to
    # _make_entry( $entry, $tree->{$next}, $next, @path[ 1 .. $#path ] );
}

#
# loads a LDIF file
#
sub _load_ldif {
    my $self = shift;
    my $ldif = $self->{ldif_object};

    while ( not $ldif->eof() ) {
        my $entry = $ldif->read_entry();
        if ( $ldif->error() ) {
            print STDERR "Error msg: ",    $ldif->error(),       "\n";
            print STDERR "Error lines:\n", $ldif->error_lines(), "\n";
            next;
        }

        $self->_add($entry);
    }
    $ldif->done();
}

sub _find_subtree {
    my ( $tree, $rdn, @path ) = @_;

    return unless exists $tree->{$rdn};
    return $tree->{$rdn} if scalar(@path) == 0;
    return _find_subtree( $tree->{$rdn}, @path );
}

sub find_tree {
    my $self = shift;
    my $dn   = shift;
    $dn = $dn->dn() if $dn->isa('Net::LDAP::Entry');

    return _find_subtree( $self->{tree}, @{ _make_entry_path($dn) } );
}

sub exists_dn {
    my ( $self, $dn ) = @_;

    my $tree = $self->find_tree($dn);
    return defined($tree);
}

sub find_entry {
    my ( $self, $dn ) = @_;

    my $tree = $self->find_tree($dn);
    return $tree->{_object} if defined($tree);
    return;
}

sub _list {
    my $tree = shift;

    my @children_trees =
      map { $tree->{$_} } ( grep { $_ ne '_object' } keys( %{$tree} ) );

    return ( $tree->{_object}, ( map { ( _list($_) ) } @children_trees ) );
}

sub list {
    my $self = shift;
    my $tree = shift // $self->{tree}->{ ( keys( %{ $self->{tree} } ) )[0] };

    return [ _list($tree) ];
}

sub _list_baseobj {
    my $self  = shift;
    my $dn    = shift;
    my $entry = $self->find_entry($dn);

    return unless defined($entry);

    return [$entry];
}

sub _list_onelevel {
    my $self = shift;
    my $dn   = shift;
    my $tree = $self->find_tree($dn);

    return unless defined($tree);
    my @children =
      map { $tree->{$_}->{_object} }
      ( grep { $_ ne '_object' } keys( %{$tree} ) );

    return [ $tree->{_object}, @children ];
}

sub _list_subtree {
    my $self = shift;
    my $dn   = shift;
    my $tree = $self->find_tree($dn);

    return unless defined($tree);
    return [ _list($tree) ];
}

sub list_with_dn_scope {
    my ( $self, $dn, $scope ) = @_;

    my @funcs = ( \&_list_baseobj, \&_list_onelevel, \&_list_subtree );
    return $funcs[$scope]->( $self, $dn );
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

=head1 DESCRIPTION

This module provides an interface between Net::LDAP::SimpleServer and a
LDIF file where the data is stored.

As of now, this interface is quite simple, and so is the underlying data
structure, but this can be easily improved in the future.

=method new()

Creates a store with no data in it. It cannot be really used like that, you
B<must> C<< load() >> some data with the C<load()> method before being able
to use it.

=method new( FILE )

Create the data store by reading FILE, which may be the name of a file or an
already open filehandle. It is passed directly to
L<<  Net::LDAP::LDIF >>.

Constructor. Expects either: a filename, a file handle, a hash reference or
a reference to a C<Net::LDAP::LDIF> object.

=method new( HASHREF )

Create the data store using the parameters in HASHREF. The associative-array
referenced by HASHREF B<must> contain a key named C<< ldif >>, which must
point to either a filename or a file handle, and it B<may> contain a key named
C<< ldif_options >>, which may contain optional parameters used in the
3-parameter version of the C<Net::LDAP::LDIF> constructor. The LDIF file will
be used for reading the data.

=method new( LDIF )

Uses an existing C<< Net::LDAP::LDIF >> as the source for the directory data.

=method load( PARAM )

Loads data from a source specified by PARAM. The argument may be in any of the
forms accepted by the constructor, except that it B<must> be specified.

=method ldif()

Returns the underlying C<< Net::LDAP::LDIF >> object.

=method find_tree( (DN|ENTRY) )

Search the store for a subtree, rooted on an entry that has the DN passed,
or the DN of the C<< Net::LDAP::Entry >> object passed.
Returns C<<undef>> if not found.

B<WARNING:> this tree reflects the internal data structure of the store,
and should not be used lightly. Whenever possible, use C<< find_entry() >>, C<exists_dn()>
or C<< list() >>.

=method find_entry( (DN|ENTRY) )

Search the store for an entry, based on the DN passed,
or the DN of the C<< Net::LDAP::Entry >> object passed.
Returns C<<undef>> if not found.

=method exists_dn( (DN|ENTRY) )

Boolean version of C<<find_entry()>>

=method list()

Returns the list of C<< Net::LDAP::Entry >> objects in the store.

=method list_with_dn_scope( DN, SCOPE )

Returns a list of C<< Net::LDAP::Entry >> objects that conforms to the SCOPE
applied to a DN, using standard LDAP rules.

=cut

