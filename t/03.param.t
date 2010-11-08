use Test::More tests => 3;

sub _check_param {

    #diag( join ',', @_ );
    eval {
        use Net::LDAP::SimpleServer;
        my $s = Net::LDAP::SimpleServer->new(@_);
        $s->run();
    };

    #diag( '$@ = ' . $@ );
    return $@;
}

sub check_failure {
    ok( _check_param(@_) );
}

diag('Testing the constructor params for SimpleServer');

check_failure();
check_failure( {} );

# Cannot test for non-existent configuration file right now
# because Net::Server calls exit() when that happens >:-\
#
#check_failure( { conf_file => 'examples/no/file.conf' } );

check_failure( { data => 'examples/test1.ldif' } );
