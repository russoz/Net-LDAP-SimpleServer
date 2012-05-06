package Net::LDAP::SimpleServer;

use strict;
use warnings;

# ABSTRACT: Minimal-configuration, read-only LDAP server

# VERSION

use 5.008;
use Carp;

our $personality = undef;

sub import {
    my $pkg = shift;
    $personality = shift || 'Fork';

    eval "use base qw{Net::Server::$personality}";    ## no critic
    croak $@ if $@;

    push @Net::LDAP::SimpleServer::ISA, qw(Net::Server);

    #use Data::Dumper;
    #print STDERR Data::Dumper->Dump( [ \@Net::LDAP::SimpleServer::ISA ],
    #    ['ISA'] );
    return;
}

use File::Basename;
use File::HomeDir;
use File::Spec;
use File::Path 2.08 qw{make_path};
use Scalar::Util qw{reftype};
use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::ProtocolHandler;

my $BASEDIR             = File::Spec->catfile( home(),   '.ldapsimple' );
my $DEFAULT_CONFIG_FILE = File::Spec->catfile( $BASEDIR, 'server.conf' );
my $DEFAULT_DATA_FILE   = File::Spec->catfile( $BASEDIR, 'server.ldif' );

my @LDAP_PRIVATE_OPTIONS = ( 'store', 'input', 'output' );
my @LDAP_PUBLIC_OPTIONS = ( 'data_file', 'root_dn', 'root_pw', 'allow_anon' );

make_path($BASEDIR);

sub options {
    my ( $self, $template ) = @_;
    my $prop = $self->{server};

    ### setup options in the parent classes
    $self->SUPER::options($template);

    ### add a single value option
    for (@LDAP_PUBLIC_OPTIONS) {
        $prop->{$_} = undef unless exists $prop->{$_};
        $template->{$_} = \$prop->{$_};
    }

    #use Data::Dumper;
    #print STDERR Data::Dumper->Dump( [$self->{server}], ['server'] );
    return;
}

sub default_values {
    my $self = @_;

    my $v = {};
    $v->{port}      = 389;
    $v->{log_file}  = File::Spec->catfile( $BASEDIR, 'server.log' );
    $v->{conf_file} = $DEFAULT_CONFIG_FILE if -r $DEFAULT_CONFIG_FILE;
    $v->{syslog_ident} =
      'Net::LDAP::SimpleServer [' . $Net::LDAP::SimpleServer::VERSION . ']';

    $v->{allow_anon} = 1;
    $v->{root_dn}    = 'cn=root';
    $v->{data_file}  = $DEFAULT_DATA_FILE if -r $DEFAULT_DATA_FILE;

    #use Data::Dumper; print STDERR Dumper($v);
    return $v;
}

sub post_configure_hook {
    my $self = shift;
    my $prop = $self->{server};

    # create server directory in home dir
    make_path($BASEDIR);

    #use Data::Dumper; print STDERR '# ' . Dumper( $prop );
    croak q{Cannot read configuration file (} . $prop->{conf_file} . q{)}
      if ( $prop->{conf_file} && !-r $prop->{conf_file} );
    croak q{Configuration has no "data_file" file!}
      unless $prop->{data_file};
    croak qq{Cannot read data_file file (} . $prop->{data_file} . q{)}
      unless -r $prop->{data_file};

    # data_file is not a "public" option in the server, it is created here
    $prop->{store} =
         Net::LDAP::SimpleServer::LDIFStore->new( $prop->{data_file} )
      || croak q{Cannot create data store!};

    return;
}

sub process_request {
    my $self = shift;
    my $prop = $self->{server};

    my $params = { map { ( $_ => $prop->{$_} ) } @LDAP_PUBLIC_OPTIONS };
    for (@LDAP_PRIVATE_OPTIONS) {
        $params->{$_} = $prop->{$_} if $prop->{$_};
    }
    $params->{input}  = *STDIN{IO};
    $params->{output} = *STDOUT{IO};
    my $handler = Net::LDAP::SimpleServer::ProtocolHandler->new($params);

    until ( $handler->handle ) {

        # intentionally empty loop
    }
    return;
}

1;    # Magic true value required at end of module

__END__

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer;

    # Or, specifying a Net::Server personality
    use Net::LDAP::SimpleServer 'PreFork';

    # using default configuration file
    my $server = Net::LDAP::SimpleServer->new();

    # passing a specific configuration file
    my $server = Net::LDAP::SimpleServer->new({
        conf_file => '/etc/ldapconfig.conf'
    });

    # passing configurations in a hash
    my $server = Net::LDAP::SimpleServer->new({
        port => 5000,
        data_file => '/path/to/data.ldif',
    });

    # make it spin
    $server->run();

The default configuration file is:

    ${HOME}/.ldapsimpleserver/config

=head1 DESCRIPTION

As the name suggests, this module aims to implement a simple LDAP server,
using many components already available in CPAN. It can be used for
prototyping and/or development purposes. This is B<NOT> intended to be a
production-grade server, altough some brave souls in small offices might
use it as such.

As of April 2010, the server will load a LDIF file and serve its
contents through the LDAP protocol. Many operations are B<NOT> available yet,
notably writing into the directory tree.

The constructors will follow the rules defined by L<Net::Server>, but the most
useful are the two forms described below.

=method new()

Attempts to create a server by using the default configuration file,
C<< ${HOME}/.ldapsimpleserver/config >>.

=method new( HASHREF )

Attempts to create a server by using the options specified in a hash
reference rather than reading them from a configuration file.

=method options()

As specified in L<Net::Server>, this method creates new options for the,
server, namely:

=over

data_file - the LDIF data file used by LDIFStore

root_dn - the administrator DN of the repository

root_pw - the password for root_dn

=back

=method default_values()

As specified in L<Net::Server>, this method provides default values for a
number of options. In Net::LDAP::SimpleServer, this method is defined as:

    sub default_values {
        return {
            host         => '*',
            port         => 389,
            proto        => 'tcp',
            root_dn      => 'cn=root',
            root_pw      => 'ldappw',
            syslog_ident => 'Net::LDAP::SimpleServer-'
                . $Net::LDAP::SimpleServer::VERSION,
            conf_file => $DEFAULT_CONFIG_FILE,
        };
    }

Notice that we do set a default password for the C<< cn=root >> DN. This
allows for out-of-the-box testing, but make sure you change the password
when putting this to production use.

=method post_configure_hook()

Method specified by L<Net::Server> to validate the passed options

=method process_request()

Method specified by L<Net::Server> to actually handle one connection. In this
module it basically delegates the processing to
L<Net::LDAP::SimpleServer::ProtocolHandler>.

=head1 CONFIGURATION AND ENVIRONMENT

Net::LDAP::SimpleServer may use a configuration file to specify the
server settings. If no file is specified and options are not passed
in a hash, this module will look for a default configuration file named
C<< ${HOME}/.ldapsimpleserver/config >>.

    data_file /path/to/a/ldif/file.ldif
    #port 389
    #root_dn cn=root
    #root_pw somepassword
    #objectclass_req (true|false)
    #user_tree dc=some,dc=subtree,dc=com
    #user_id_attr uid
    #user_pw_attr password

=cut

