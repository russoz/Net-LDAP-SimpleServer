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

sub ldapconnect {
    return Net::LDAP->new( TESTHOST, port => TESTPORT );
}

sub run_test {
    my $mesg = undef;

    my $ldap = ldapconnect();
    ok($ldap);

    $mesg = $ldap->bind;
    ok( !$mesg->code, $mesg->error_desc );

    # no results for this one
    $mesg = $ldap->search( base => 'DC=org', filter => '(dn=*)' );
    ok( !$mesg->code, $mesg->error_desc );
    my @entries = $mesg->entries;
    is( scalar @entries, 0 );

    my $dn1 =
      'CN=Alexei Znamensky,OU=SnakeOil,OU=Extranet,DC=sa,DC=mynet,DC=net';
    $mesg = $ldap->search(
        base   => 'DC=net',
        filter => '(distinguishedname=' . $dn1 . ')'
    );
    ok( !$mesg->code, $mesg->error_desc );
    @entries = $mesg->entries;
    is( scalar @entries, 1 );
    my $e = shift @entries;
    is( $e->dn,              $dn1 );
    is( $e->get_value('sn'), 'Znamensky' );

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

