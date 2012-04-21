package Net::LDAP::SimpleServer;

use strict;
use warnings;

# ABSTRACT: Minimal-configuration, read-only LDAP server

# VERSION

use 5.008;
use Carp;
use common::sense;

our $personality = undef;

sub import {
    my $pkg = shift;
    $personality = shift || 'Fork';

    use Net::Server;
    eval "use base qw{Net::Server::$personality}";    ## no critic
    croak $@ if $@;

    @Net::LDAP::SimpleServer::ISA = qw(Net::Server);

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

## no critic
use constant BASEDIR => File::Spec->catfile( home(),  '.ldapsimpleserver' );
use constant LOGDIR  => File::Spec->catfile( BASEDIR, 'log' );
use constant DEFAULT_CONFIG_FILE => File::Spec->catfile( BASEDIR, 'config' );
use constant DEFAULT_DATA_FILE => File::Spec->catfile( BASEDIR, 'server.ldif' );
## use critic

make_path(LOGDIR);

my $_add_option = sub {
    my ( $template, $prop, $opt, $initial ) = @_;

    $prop->{$opt}     = $initial;
    $template->{$opt} = \$prop->{$opt};
};

sub options {
    my ( $self, $template ) = @_;
    ### setup options in the parent classes
    $self->SUPER::options($template);

    ### add a single value option
    my $prop = $self->{server};
    $_add_option->( $template, $prop, 'ldap_data', undef );
    $_add_option->( $template, $prop, 'root_dn',   undef );
    $_add_option->( $template, $prop, 'root_pw',   undef );

    #use Data::Dumper;
    #print STDERR Data::Dumper->Dump( [$self], ['options_END'] );
    return;
}

sub default_values {
    my $self = @_;

    my $v = {};
    $v->{port}     = 389;
    $v->{root_dn}  = 'cn=root';
    $v->{root_pw}  = 'ldappw';
    $v->{log_file} = File::Spec->catfile( LOGDIR, 'server.log' );

    #$v->{pid_file} = File::Spec->catfile( LOGDIR, 'server.pid' );
    $v->{conf_file} = DEFAULT_CONFIG_FILE if -r DEFAULT_CONFIG_FILE;
    $v->{ldap_data} = DEFAULT_DATA_FILE   if -r DEFAULT_DATA_FILE;
    $v->{syslog_ident} =
      'Net::LDAP::SimpleServer-' . $Net::LDAP::SimpleServer::VERSION;
    return $v;
}

sub _make_dir {
    my $file = shift;
    return unless $file;

    my $dir = dirname($file);
    return unless $dir;
    return if -d $dir;

    make_path($dir);
    return;
}

sub post_configure_hook {
    my $self = shift;
    my $prop = $self->{server};

    #use Data::Dumper;
    #print STDERR '# ' . Data::Dumper->Dump( [$self], ['post_configure_hook'] );
    croak q{Cannot find conf file "} . $self->{server}->{conf_file} . q{"}
      if $self->{server}->{conf_file} and not -r $self->{server}->{conf_file};
    _make_dir( $self->{server}->{log_file} );
    _make_dir( $self->{server}->{pid_file} );
    croak q{Configuration has no "ldap_data" file!}
      unless exists $prop->{ldap_data};
    croak qq{Cannot read ldap_data file "} . $prop->{ldap_data} . q{"}
      unless -r $prop->{ldap_data};

    $prop->{store} =
         Net::LDAP::SimpleServer::LDIFStore->new( $prop->{ldap_data} )
      || croak q{Cannot create data store!};
    return;
}

sub process_request {
    my $self = shift;

    my $in  = *STDIN{IO};
    my $out = *STDOUT{IO};
    my $params =
      { map { ( $_ => $self->{server}->{$_} ) } qw/store root_dn root_pw/ };
    my $handler =
      Net::LDAP::SimpleServer::ProtocolHandler->new( $params, $in, $out );

    until ( $handler->handle ) {

        # intentionally empty loop
    }
    return;
}

1;    # Magic true value required at end of module

__END__

=head1 SYNOPSIS

    package MyServer;

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
        ldap_data => '/path/to/data.ldif',
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

ldap_data - the LDIF data file used by LDIFStore

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
            conf_file => DEFAULT_CONFIG_FILE,
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

    ldap_data /path/to/a/ldif/file.ldif
    #port 389
    #root_dn cn=root
    #root_pw somepassword
    #objectclass_req (true|false)
    #user_tree dc=some,dc=subtree,dc=com
    #user_id_attr uid
    #user_pw_attr password

=cut

