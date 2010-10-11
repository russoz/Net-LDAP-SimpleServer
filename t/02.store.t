use Test::More tests => 1;

use Net::LDAP::SimpleServer::LDIFStore;

sub _check_param {
    my @p = @_;
    eval { my $o = Net::LDAP::SimpleServer::LDIFStore->new(@p); };
}

sub check_param_success {
    my $p = _check_param(@_);
    ok($p);
}

sub check_param_failure {
    my $p = _check_param(@_);
    ok( not $p );
}

diag("Testing parameters for the constructor\n");

check_param_failure('name/of/a/file/that/will/never/ever/exist.ldif');

#if ( -r $cfgfile ) {
#    diag( "Using default cfg file: " . $cfgfile );
#    check_param_success();
#}
#else {
#    diag("Default cfg file not found");
#    check_param_failure();
#}

#SKIP: {
#    skip "Not messing with your default configuration file", 1
#        if -r $cfgfile;

