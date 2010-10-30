package Net::LDAP::SimpleServer::ProtocolHandler;

use strict;
use warnings;

use Carp;
use UNIVERSAL::isa;
use Scalar::Util qw(blessed reftype);
use Net::LDAP::LDIF;

use version; our $VERSION = qv('0.0.4');

use Net::LDAP::Server;
use base 'Net::LDAP::Server';
use fields qw(store);

sub new {
    my ( $class, $store, $sock ) = @_;
    my $self = $class->SUPER::new($sock);
    #printf "Accepted connection from: %s\n", $sock->peerhost();
    $self->{store} = $store;

    croak 'Must pass store and socket!' unless ($store and $sock);

    return $self;
}


1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::LDAP::SimpleServer::ProtocolHandler - Data store to support C<Net::LDAP::SimpleServer>

=head1 VERSION

This document describes Net::LDAP::SimpleServer::ProtocolHandler version 0.0.4

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer::ProtocolHandler;

    my $store = Net::LDAP::SimpleServer::ProtocolHandler->new();
    $store->load( "data.ldif" );

    my $store =
      Net::LDAP::SimpleServer::ProtocolHandler->new({ ldif => 'data.ldif' });

    my $ldif = Net::LDAP::LDIF->new( "file.ldif" );
    my $store = Net::LDAP::SimpleServer::ProtocolHandler->new($ldif);

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

