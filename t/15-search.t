use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Helper qw(ldap_client test_requests);

use Net::LDAP::Constant (
    qw/LDAP_SUCCESS LDAP_AUTH_UNKNOWN LDAP_INVALID_CREDENTIALS/,
    qw/LDAP_AUTH_METHOD_NOT_SUPPORTED LDAP_INVALID_SYNTAX LDAP_NO_SUCH_OBJECT/
);
use Net::LDAP::SimpleServer::Constant
  qw/SCOPE_BASEOBJ SCOPE_ONELEVEL SCOPE_SUBTREE/;

use Data::Dumper;

my $DATA    = 'examples/single-entry.ldif';
my $ROOT_PW = 'testpw';

test_requests(
    server_opts => {
        data_file => $DATA,
        root_pw   => $ROOT_PW,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        ok($ldap);

        $mesg = $ldap->bind;
        ok( !$mesg->code, $mesg->error_desc );

        # no results for this one
        $mesg = $ldap->search( base => 'DC=org', filter => '(dn=*)' );
        is( $mesg->code, LDAP_NO_SUCH_OBJECT, $mesg->error_desc );
        my @entries = $mesg->entries;
        is( scalar @entries, 0 );

        my $dn1 =
          'CN=Alexei Znamensky,OU=SnakeOil,OU=Extranet,DC=sa,DC=mynet,DC=net';
        $mesg = $ldap->search(
            base   => 'DC=net',
            filter => '(distinguishedname=' . $dn1 . ')'
        );

        #use Data::Dumper; diag( '\nAAA\n' . Dumper($mesg) . '\n\n');
        is( $mesg->code, LDAP_SUCCESS, $mesg->error_desc );
        @entries = $mesg->entries;
        is( scalar @entries, 1 );
        my $e = shift @entries;

        is( $e->dn, $dn1 );

        is( $e->get_value('sn'), 'Znamensky' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code, $mesg->error_desc );
    }
);

done_testing();
