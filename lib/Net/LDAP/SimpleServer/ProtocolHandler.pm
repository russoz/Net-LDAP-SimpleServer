package Net::LDAP::SimpleServer::ProtocolHandler;

use strict;
use warnings;

# ABSTRACT: LDAP protocol handler used with Net::LDAP::SimpleServer

# VERSION

use Net::LDAP::Server;
use base 'Net::LDAP::Server';
use fields qw(store root_dn root_pw allow_anon);

use Carp;
use Net::LDAP::LDIF;
use Net::LDAP::Util qw{canonical_dn};
use Net::LDAP::Filter;
use Net::LDAP::FilterMatch;

use Net::LDAP::Constant qw/
  LDAP_SUCCESS LDAP_INVALID_CREDENTIALS LDAP_AUTH_METHOD_NOT_SUPPORTED
  LDAP_INVALID_SYNTAX LDAP_NO_SUCH_OBJECT/;

use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::Constant;

use Scalar::Util qw{reftype};
use UNIVERSAL::isa;

sub _make_result {
    my $code = shift;
    my $dn   = shift // '';
    my $msg  = shift // '';

    return {
        matchedDN    => $dn,
        errorMessage => $msg,
        resultCode   => $code,
    };
}

sub new {
    my $class = shift;
    my $params = shift || croak 'Must pass parameters!';

    croak 'Parameter must be a HASHREF' unless reftype($params) eq 'HASH';
    for my $p (qw/store root_dn sock/) {
        croak 'Must pass option {' . $p . '}' unless exists $params->{$p};
    }
    croak 'Not a LDIFStore'
      unless $params->{store}->isa('Net::LDAP::SimpleServer::LDIFStore');

    croak 'Option {root_dn} can not be empty' unless $params->{root_dn};
    croak 'Invalid root DN'
      unless my $canon_dn = canonical_dn( $params->{root_dn} );

    my $self = $class->SUPER::new( $params->{sock} );
    $self->{store}      = $params->{store};
    $self->{root_dn}    = $canon_dn;
    $self->{root_pw}    = $params->{root_pw};
    $self->{allow_anon} = $params->{allow_anon};
    chomp( $self->{root_pw} );

    return $self;
}

sub unbind {
    my $self = shift;

    $self->{store}   = undef;
    $self->{root_dn} = undef;
    $self->{root_pw} = undef;

    return _make_result(LDAP_SUCCESS);
}

sub bind {
    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $request ) = @_;

    my $OK = _make_result(LDAP_SUCCESS);

    # anonymous bind
    if (    not $request->{name}
        and exists $request->{authentication}->{simple}
        and $self->{allow_anon} )
    {
        return $OK;
    }

    # As of now, accepts only simple authentication
    return _make_result(LDAP_AUTH_METHOD_NOT_SUPPORTED)
      unless exists $request->{authentication}->{simple};

    return _make_result(LDAP_INVALID_CREDENTIALS)
      unless my $binddn = canonical_dn( $request->{name} );

    return _make_result(LDAP_INVALID_CREDENTIALS)
      unless uc($binddn) eq uc( $self->{root_dn} );

    my $bindpw = $request->{authentication}->{simple};
    chomp($bindpw);

    return _make_result(LDAP_INVALID_CREDENTIALS)
      unless $bindpw eq $self->{root_pw};

    return $OK;
}

sub _match {
    my ( $filter_spec, $elems ) = @_;

    my $f = bless $filter_spec, 'Net::LDAP::Filter';
    return [ grep { $f->match($_) } @{$elems} ];
}

sub search {
    my ( $self, $request ) = @_;

    my $list;
    if ( defined( $request->{baseObject} ) ) {
        my $basedn = canonical_dn( $request->{baseObject} );
        my $scope = $request->{scope} || SCOPE_SUBTREE;

        $list = $self->{store}->list_with_dn_scope( $basedn, $scope );
        return _make_result( LDAP_NO_SUCH_OBJECT, '',
            'Cannot find BaseDN "' . $basedn . '"' )
          unless defined($list);
    }
    else {
        $list = $self->{store}->list();
    }

    my $match = _match( $request->{filter}, $list );
    return ( _make_result(LDAP_SUCCESS), @{$match} );
}

1;    # Magic true value required at end of module

__END__

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer::ProtocolHandler;

    my $store = Net::LDAP::SimpleServer::LDIFStore->new($datafile);
    my $handler =
      Net::LDAP::SimpleServer::ProtocolHandler->new({
          store   => $datafile,
          root_dn => 'cn=root',
          root_pw => 'somepassword'
      }, $socket );

=head1 DESCRIPTION

This module provides an interface between Net::LDAP::SimpleServer and the
underlying data store. Currently only L<Net::LDAP::SimpleServer::LDIFStore>
is available.

=method new( OPTIONS, IOHANDLES )

Creates a new handler for the LDAP protocol, using STORE as the backend
where the directory data is stored. The rest of the IOHANDLES are the same
as in the L<Net::LDAP::Server> module.

=method bind( REQUEST )

Handles a bind REQUEST from the LDAP client.

=method unbind()

Unbinds the connection to the server.

=method search( REQUEST )

Performs a search in the data store. The search filter, baseObject and scope are supported.

=cut

