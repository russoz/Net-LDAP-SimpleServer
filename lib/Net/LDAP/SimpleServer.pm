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
use Net::LDAP::SimpleServer::Constant;

my $BASEDIR             = File::Spec->catfile( home(),   '.ldapsimple' );
my $DEFAULT_CONFIG_FILE = File::Spec->catfile( $BASEDIR, 'server.conf' );
my $DEFAULT_DATA_FILE   = File::Spec->catfile( $BASEDIR, 'server.ldif' );
my $DEFAULT_LOG_FILE    = File::Spec->catfile( $BASEDIR, 'server.log' );

my @LDAP_PRIVATE_OPTIONS = qw/store input output/;
my @LDAP_PUBLIC_OPTIONS =
  qw/data_file root_dn root_pw allow_anon user_passwords user_id_attr user_pw_attr user_filter/;

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
    $v->{log_file}  = $DEFAULT_LOG_FILE;
    $v->{conf_file} = $DEFAULT_CONFIG_FILE if -r $DEFAULT_CONFIG_FILE;
    $v->{syslog_ident} =
      'Net::LDAP::SimpleServer [' . $Net::LDAP::SimpleServer::VERSION . ']';

    $v->{allow_anon}     = 1;
    $v->{root_dn}        = 'cn=root';
    $v->{data_file}      = $DEFAULT_DATA_FILE if -r $DEFAULT_DATA_FILE;
    $v->{user_passwords} = USER_PW_NONE;
    $v->{user_filter}    = '(objectClass=person)';
    $v->{user_id_attr}   = 'uid';
    $v->{user_pw_attr}   = 'userPassword';

    #use Data::Dumper; print STDERR Dumper($v);
    return $v;
}

sub post_configure_hook {
    my $self = shift;
    my $prop = $self->{server};

    # create server directory in home dir
    make_path($BASEDIR);

    #use Data::Dumper; print STDERR '# ' . Dumper( $prop );
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
    $params->{sock} = $self->{server}->{client};
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

    # make it spin with options
    $server->run({ allow_anon => 0 });

=head1 DESCRIPTION

As the name suggests, this module aims to implement a simple LDAP server,
using many components already available in CPAN. It can be used for
prototyping and/or development purposes. This is B<NOT> intended to be a
production-grade server, although some brave souls in small offices might
use it as such.

As of April 2010, the server will load a LDIF file and serve its
contents through the LDAP protocol. Many operations are B<NOT> available yet,
notably writing into the directory tree.

The constructors will follow the rules defined by L<Net::Server>, but the most
useful are the two forms described below.

C<Net::LDAP::SimpleServer> will use the directory C<< ${HOME}/.ldapsimple >>
as a C<BASEDIR> for server files. If there exists a file:

    BASEDIR/server.conf

it will be used as the default configuration file. Similarly, if there exists
a file:

    BASEDIR/server.ldif

it will be used as the default data file for this server.

=method new()

Instantiates a server object. If the default configuration file is available,
the options in it will be used.

=method new( HASHREF )

Instantiates a server object using the options specified in a hash
reference.

=method options()

As specified in L<Net::Server>, this method creates new options for the,
server, namely:

=begin :list

* data_file - the LDIF data file used by LDIFStore
* root_dn - the administrator DN of the repository
* root_pw - the password for root_dn
* allow_anon - whether to allow for anonymous binds

=end :list

=method default_values()

As specified in L<Net::Server>, this method provides default values for a
number of options.

Notice that we do set a default password for the C<< cn=root >> DN. This
allows for out-of-the-box testing, but make sure you change the password
when putting this to production use.

=method post_configure_hook()

Method specified by L<Net::Server> to validate the parameters used in the
server instance.

=method process_request()

Method specified by L<Net::Server> to actually handle one connection. In this
module it basically delegates the processing to
L<Net::LDAP::SimpleServer::ProtocolHandler>.

=head1 CONFIGURATION AND ENVIRONMENT

Net::LDAP::SimpleServer may use a configuration file to specify the
server settings. If no file is specified and options are not passed
in a hash, this module will look for a default configuration file named
C<< BASEDIR/server.conf >>.

    data_file /path/to/a/ldif/file.ldif
    #port 389
    #root_dn cn=root
    #root_pw somepassword

=cut

=head1 TODO

We plan to implement more options in Net::LDAP::SimpleServer. Some ideas are:

    #objectclass_req (true|false)
    #user_tree dc=some,dc=subtree,dc=com
    #user_id_attr uid
    #user_pw_attr password

Keeping in mind we do NOT want to implement a full blown LDAP server.

=cut

