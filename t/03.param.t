use Test::More tests => 6;

use Proc::Fork;
use IO::Pipe;

$alarm_wait = 5;

sub _eval_param {
    my @a      = @_;
    my $result = undef;

    $p = IO::Pipe->new;

    run_fork {
        child {
            $p->writer;
            sub quit { print $p shift; exit; }

            alarm 0;
            local $SIG{ALRM} = sub { quit('OK') };
            alarm $alarm_wait;

            eval {
                use Net::LDAP::SimpleServer qw{Fork};

                # passing custom options in the construtor does not seem to
                # work with Net::Server, thus we pass them in run()
                my $s = Net::LDAP::SimpleServer->new();

                diag('Starting Net::LDAP::SimpleServer');
                $s->run(@a);
            };

            quit('NOK');
        }
    };

    # parent code
    $p->reader;
    $result = <$p>;

    #diag( 'got result: ' . $result );
    return $result eq 'OK';
}

diag('Testing the constructor params for SimpleServer');

# ===========================================================================
# expect failure
ok( !_eval_param() );
ok( !_eval_param( {} ) );

# Cannot test for non-existent configuration file right now
# because Net::Server calls exit() when that happens >:-\
#
#_eval_param( { conf_file => 'examples/no/file.conf' } );
ok( !_eval_param( { ldap_data => 'examples/test1.ldif' } ) );
ok( !_eval_param( { conf_file => 'examples/empty.conf' } ) );

# ===========================================================================
# expect success
ok(
    _eval_param(
        {
            port      => 20000,
            ldap_data => 'examples/single-entry.ldif',
        }
    )
);
ok( _eval_param( { conf_file => 'examples/single-entry.conf' } ) );

