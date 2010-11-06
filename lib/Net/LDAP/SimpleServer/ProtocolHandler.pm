package Net::LDAP::SimpleServer::ProtocolHandler;

use strict;
use warnings;

use Net::LDAP::Server;
use base 'Net::LDAP::Server';
use fields qw(store);

use Carp;
use Net::LDAP::LDIF;

use version; our $VERSION = qv('0.0.9');

sub new {
    my $class = shift;
    my $store = shift;
    my $self  = $class->SUPER::new(@_);

    #printf "Accepted connection from: %s\n", $sock->peerhost();
    $self->{store} = $store;

    croak 'Must pass store!' unless $store;

    return $self;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::LDAP::SimpleServer::ProtocolHandler - LDAP protocol handler used with C<Net::LDAP::SimpleServer>

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer::ProtocolHandler;

    my $store = Net::LDAP::SimpleServer::LDIFStore->new( $datafile );
    my $handler =
      Net::LDAP::SimpleServer::ProtocolHandler->new( $store, $socket );

=head1 DESCRIPTION

This module provides an interface between Net::LDAP::SimpleServer and the
underlying data store. Currently only L<Net::LDAP::SimpleServer::LDIFStore>
is available.

=head1 CONSTRUCTOR 

=over

=item new( STORE, OPTIONS )

Creates a new handler for the LDAP protocol, using STORE as the backend
where the directory data is stored. The rest of the OPTIONS are the same
as in the L<Net::LDAP::Server> module.

=back

=head1 METHODS

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

L<< UNIVERSAL::isa >>

L<< Scalar::Util >>

L<< Net::LDAP::LDIF >>

L<< Net::LDAP::Server >>

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

