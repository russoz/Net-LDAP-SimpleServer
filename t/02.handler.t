use Test::More tests => 2;

use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::ProtocolHandler;

my $store =
  Net::LDAP::SimpleServer::LDIFStore->new('examples/single-entry.ldif');

sub _check_param {
    my @p = @_;
    eval { my $o = Net::LDAP::SimpleServer::ProtocolHandler->new(@p); };
    return $@;
}

sub check_param_success {
    my $p = _check_param(@_);
    ok( not $p );
}

sub check_param_failure {
    my $p = _check_param(@_);
    ok($p);
}

diag("Testing the constructor params for ProtocolHandler\n");

my $obj = new_ok(
    'Net::LDAP::SimpleServer::ProtocolHandler',
    [ $store, *STDIN{IO}, *STDOUT{IO} ]
);

check_param_failure('non/existent/file.ldif');
