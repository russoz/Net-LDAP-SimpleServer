use Test::More tests => 9;

use Proc::Fork;
use Net::LDAP;
use Net::LDAP::SimpleServer;

use Data::Dumper;

use constant TESTHOST   => 'localhost';
use constant TESTPORT   => 10389;
use constant TESTDATA   => 'examples/single-entry.ldif';
use constant TESTROOTDN => 'cn=root';
use constant TESTROOTPW => 'testpw';

#sub diag { print STDERR @_; }

sub ldapconnect {
    return Net::LDAP->new( TESTHOST, port => TESTPORT );
}

sub run_test {
    my $mesg = undef;

    my $ldap = ldapconnect();
    ok($ldap);

    diag('Performing an anonymous bind');
    $mesg = $ldap->bind;
    ok( !$mesg->code, $mesg->error_desc );

    $mesg = $ldap->unbind;
    ok( !$mesg->code, $mesg->error_desc );

    diag('Performing an authenticated bind');
    $ldap = ldapconnect();
    $mesg = $ldap->bind( TESTROOTDN, password => TESTROOTPW );
    ok( !$mesg->code, $mesg->error_desc );

    $mesg = $ldap->unbind;
    ok( !$mesg->code, $mesg->error_desc );

    diag('Performing an authenticated bind, upper case DN');
    $ldap = ldapconnect();
    $mesg = $ldap->bind( uc(TESTROOTDN), password => TESTROOTPW );
    ok( !$mesg->code, $mesg->error_desc );

    $mesg = $ldap->unbind;
    ok( !$mesg->code, $mesg->error_desc );

    diag('Performing an authenticated bind with wrong password');
    $ldap = ldapconnect();
    $mesg = $ldap->bind( TESTROOTDN, password => 'some-wrong-password' );
    ok( $mesg->code, $mesg->error_desc );

    $mesg = $ldap->unbind;
    ok( !$mesg->code, $mesg->error_desc );

}

run_fork {
    parent {
        my $child = shift;

        # give the server some time to start
        sleep 10;

        # run client
        run_test();
        kill 15, $child;
    }
    child {
        my $s = Net::LDAP::SimpleServer->new();

        # run server
        diag('Starting Net::LDAP::SimpleServer [Fork]');
        $s->run(
            {
                port      => TESTPORT,
                ldap_data => TESTDATA,
                root_pw   => TESTROOTPW,
            }
        );
        diag('Server has quit');
    }
};

