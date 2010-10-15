package Net::LDAP::SimpleServer;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.6');

use File::HomeDir;
use File::Spec::Functions qw(catfile);
use Scalar::Util qw(reftype);
use Config::General qw(ParseConfig);
use Net::LDAP::SimpleServer::LDIFStore;

use constant DEFAULT_CONFIG_FILE => '.ldapsimpleserver.conf';

sub new {
    my ( $class, $param ) = @_;
    my $self = bless( {}, $class );

    my $config;
    if ( reftype($param) eq 'HASH' ) {

        # $param is a hash with configuration
        $config = $param;
    }
    else {

        # or a configuration file
        my $file = $param
          || File::Spec->catfile( home(), DEFAULT_CONFIG_FILE );

        $config = _read_config_file($file);
        $self->{config_file} = $file;
    }

    eval { _config_ok($config); };
    croak $@ if $@;

    $self->{config} = $config;

    return $self;
}

sub _config_ok {
    my $config = shift;

    croak q{Configuration has no data file."}
      unless exists $config->{data};

    return 1;
}

sub _read_config_file {
    my $file = shift;

    croak q{Cannot read the configuration file "} . $file . q{".}
      unless -r $file;

    my %config = ParseConfig(
        -ConfigFile           => $file,
        -AllowMultiOptions    => 'no',
        -UseApacheInclude     => 1,
        -MergeDuplicateBlocks => 1,
        -AutoTrue             => 1,
        -CComments            => 0,
    );

    return \%config;
}

sub refresh_config {
    my $self = shift;
    return unless exists $self->{config_file};

    my $config = _read_config_file( $self->{config_file} );

    eval { _config_ok($config); };
    croak $@ if $@;

    $self->{config} = $config;
}

sub _load_data {
    my $self = shift;

    return unless $self->{loaded};

    $self->{store} =
      Net::LDAP::SimpleServer::LDIFStore->new( $self->{config}->{DataFile} );
    $self->{loaded} = 1;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::LDAP::SimpleServer - Minimal-configuration, read-only LDAP server

=head1 VERSION

This document describes Net::LDAP::SimpleServer version 0.0.6

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer;

    # using default configuration file
    my $server = Net::LDAP::SimpleServer->new();

    # passing a specific configuration file
    my $server = Net::LDAP::SimpleServer->new( 'ldapconfig.conf' );

    # passing configurations in a hash
    my $server = Net::LDAP::SimpleServer->new({
        port => 5000,
        data => '/path/to/data.ldif',
    });

    # make it spin
    $server->run();

The default configuration file is:

    ${HOME}/.ldapsimpleserver.conf

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

B<< WORK IN PROGRESS!! NOT READY TO USE YET!! >>

As the name suggests, this module aims to implement a simple LDAP server, 
using many components already available in CPAN. It can be used for
prototyping and/or development purposes. This is B<NOT> intended to be a
production-grade server, altough some brave souls in small offices might
use it as such.

As of October 2010, the server will simply load a LDIF file and serve its
contents through the LDAP protocol. Many operations are B<NOT> available yet,
notably writing into the directory tree, but we would like to implement that
in a near future.


=head1 CONSTRUCTOR 

=over

=item new()

Attempts to create a server by using the default configuration file,
C<< ${HOME}/.ldapsimpleserver.conf >>.

=item new( FILE )

Attempts to create a server using the specified configuration file.

=item new( HASHREF )

Attempts to create a server by using the options specified in a hash
reference rather than reading them from a configuration file.

=back

=head1 METHODS 

=over

=item refresh_config()

If the server was constructed using a configuration file, this method
will attempt to reload the options from that file.

=back


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
  
Net::LDAP::SimpleServer may use a configuration file to specify the
server settings. If no file is specified and options are not passed
in a hash, this module will look for a default configuration file named
C<< ${HOME}/.ldapsimpleserver.conf >>. 

    data /path/to/a/ldif/file.ldif
    #port 389
    #root_id cn=root
    #root_pw somepassword
    #objectclass_req (true|false)
    #user_tree dc=some,dc=subtree,dc=com
    #user_id_attr uid
    #user_pw_attr password


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

L<< Carp >>

L<< File::HomeDir >>

L<< File::Spec::Functions >>

L<< Scalar::Util >>

L<< Config::General >>

L<< Net::LDAP::SimpleServer::LDIFStore >>


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

