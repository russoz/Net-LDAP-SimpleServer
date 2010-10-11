package Net::LDAP::SimpleServer::LDIFStore;

use strict;
use warnings;
use diagnostics;

use Carp;
use UNIVERSAL::isa;
use Scalar::Util qw(blessed reftype openhandle);
use Net::LDAP::LDIF;

use version; our $VERSION = qv('0.0.3');

sub new {
    my ( $class, $param ) = @_;

    croak 'Must pass argument!' unless $param;

    my $list = [];
    my $reftype = reftype ($param) || '';
    if ( $reftype eq 'HASH' ) {

        # LDIF file parameter
        #   - a file name
        #   - a file handle
        #   - a Net::LDAP::LDIF object
        if ( exists $param->{ldif} ) {
            $list = _load_ldif( $param->{ldif}, $param->{ldif_options} );
        }
    }
    elsif ( blessed($param) ) {

        # an object!
        if ( $param->isa('Net::LDAP::LDIF') ) {
            $list = _load_ldif($param);
        }
    }
    else {
        croak 'Invalid argument!';
    }

    return bless( { list => $list }, $class );
}

#
# loads a filename, a file-handle, or a Net::LDAP::LDIF object
#
sub _load_ldif {
    my ( $protoself, $ldifspec, $options ) = @_;

    my $ldif;
    my @list = ();
    if ( blessed($ldifspec) ) {
        croak "Not an Net::LDAP::LDIF object!!"
          unless $ldif->isa('Net::LDAP::LDIF');
        $ldif = $ldifspec;
    }
    else {
        if ($options) {
            $ldif = Net::LDAP::LDIF->new( $ldifspec, 'r', %{$options} );
        }
        else {
            $ldif = Net::LDAP::LDIF->new($ldifspec);
        }
    }

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

sub _add_ldap_entry {
    my ( $self, $entry ) = @_;

    my @newlist =
      sort { uc( $a->dn() ) cmp uc( $b->dn() ) } ( @{ $self->{list} }, $entry );

    $self->{list} = \@newlist;
}

sub add_node {
    my ( $self, $param, %attrs ) = @_;

    my $entry;
    if ( blessed($param) ) {
        carp 'Must pass a Net::LDAP::Entry object'
          if !$param->isa('Net::LDAP::Entry');

        $entry = $param;
    }
    else {
        my $entry = Net::LDAP::Entry->( $param, %attrs );
    }
    $self->_add_ldap_entry($entry);
}

sub filter {
    my ( $self, $sub ) = @_;
    my @list = @{ $self->{list} };

    foreach my $index ( 0 .. $#list ) {
        delete $list[$index] unless $sub->( $list[$index] );
    }
    return @list;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::LDAP::SimpleServer::LDIFStore - Data tree to support C<Net::LDAP::SimpleServer>

=head1 VERSION

This document describes Net::LDAP::SimpleServer::LDIFStore version 0.0.3

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer::LDIFStore;

    my $tree = Net::LDAP::SimpleServer::LDIFStore->new();

Using, respectively, the default configuration file, which is

    {HOME}/.netldapsimpleserver.conf

Or using a specified file as the configuration file.
Alternatively, all the configuration can be passed as a hash reference:

    my $server = Net::LDAP::SimpleServer->new({
        port => 5000,
        data => '/path/to/data.ldif',
    });
    $server->run();


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 new()



=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

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

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

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

