package Net::LDAP::SimpleServer::ProtocolHandler;

use common::sense;

use Net::LDAP::Server;
use base 'Net::LDAP::Server';
use fields qw(store root_dn root_pw);

use Carp;
use Net::LDAP::LDIF;
use Net::LDAP::Util qw{canonical_dn};
use Scalar::Util qw{blessed reftype looks_like_number};
use UNIVERSAL::isa;

use Data::Dumper;

use version; our $VERSION = qv('0.0.12');

my %_ldap_cache = ();

sub _get_ldap_constant {
    my $code = shift;
    return $code if looks_like_number($code);
    return $_ldap_cache{$code} if exists $_ldap_cache{$code};
    return $_ldap_cache{$code} = eval qq{
        use Net::LDAP::Constant qw|$code|;
        $code;
    };
}

sub _make_result {
    my $code = shift;
    my $dn   = shift || '';
    my $msg  = shift || '';

    return {
        matchedDN    => $dn,
        errorMessage => $msg,
        resultCode   => _get_ldap_constant($code),
    };
}

sub new {
    my $class  = shift;
    my $params = shift;
    my $self   = $class->SUPER::new(@_);

    croak 'First parameter must be an ARRAYREF'
      unless reftype($params) eq 'HASH';

    croak 'Must pass store!' unless exists $params->{store};
    croak 'Not an object!'   unless blessed( $params->{store} );
    croak 'Not a LDIFStore!'
      unless $params->{store}->isa('Net::LDAP::SimpleServer::LDIFStore');

    croak 'Must pass root_dn!' unless exists $params->{root_dn};

    #my $canon_dn;
    croak 'Invalid root DN'
      unless my $canon_dn = canonical_dn( $params->{root_dn} );

    $self->{store}   = $params->{store};
    $self->{root_dn} = $canon_dn;
    $self->{root_pw} = $params->{root_pw} || '';
    chomp( $self->{root_pw} );

    return $self;
}

sub bind {

    #    my $r = _bind(@_);
    #    print STDERR q{response = } . Dumper($r);
    #    return $r;
    #}
    #
    #sub _bind {
    my ( $self, $request ) = @_;

    #print STDERR '=' x 70 . "\n";
    #print STDERR Dumper($request);
    my $ok = _make_result(qw/LDAP_SUCCESS/);
    return $ok unless $request->{name};

    #print STDERR qq{not anonymous\n};
    return _make_result(qw/LDAP_AUTH_UNKNOWN/)
      unless exists $request->{authentication}->{simple};

    #print STDERR qq{is simple authentication\n};
    return _make_result(qw/LDAP_INVALID_CREDENTIALS/)
      unless my $binddn = canonical_dn( $request->{name} );

    #print STDERR qq#binddn is ok ($request->{name}) => ($binddn)\n#;
    #print STDERR qq#handler dn is $self->{root_dn}\n#;
    return _make_result(qw/LDAP_INVALID_CREDENTIALS/)
      unless uc($binddn) eq uc( $self->{root_dn} );

    #print STDERR qq{binddn is good\n};
    my $bindpw = $request->{authentication}->{simple};
    chomp($bindpw);

    #print STDERR qq|comparing ($bindpw) eq ($self->{root_pw})\n|;
    return _make_result(qw/LDAP_INVALID_CREDENTIALS/)
      unless $bindpw eq $self->{root_pw};

    return $ok;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::LDAP::SimpleServer::ProtocolHandler - LDAP protocol handler used with C<Net::LDAP::SimpleServer>

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

=head1 CONSTRUCTOR 

=over

=item new( OPTIONS, IOHANDLES )

Creates a new handler for the LDAP protocol, using STORE as the backend
where the directory data is stored. The rest of the IOHANDLES are the same
as in the L<Net::LDAP::Server> module.

=back

=head1 METHODS

=over

=item bind( REQUEST )

Handles a bind REQUEST from the LDAP client.

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
  
Net::LDAP::SimpleServer::ProtocolHandler requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<< common::sense >>

L<< Net::LDAP::Server >>

L<< Carp >>;

L<< Net::LDAP::LDIF >>

L<< Net::LDAP::Util >>

L<< Scalar::Util >>

L<< UNIVERSAL::isa >>

L<< Net::LDAP::Constant >>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

This store does not yet support writing to a LDIF file, which makes the 
C<< Net::LDAP::SimpleServer >> a read-only server.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-ldap-simpleserver@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Alexei Znamensky  C<< <russoz@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Alexei Znamensky C<< <russoz@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

