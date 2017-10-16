use strict;
use warnings;
use Test::More;

done_testing();
__END__

use Net::LDAP::SimpleServer::LDIFStore;

sub _check_param {
    eval { my $o = Net::LDAP::SimpleServer::LDIFStore->new(@_); };
    return $@;
}

sub check_param_success {
    ok( not _check_param(@_) );
}

sub check_param_failure {
    ok( _check_param(@_) );
}

my $obj = undef;

#$obj = new_ok( 'Net::LDAP::SimpleServer::LDIFStore', [ 'name/of/a/file/that/will/never/ever/exist.ldif' ] );
check_param_failure('');
check_param_failure('name/of/a/file/that/will/never/ever/exist.ldif');
$obj =
  new_ok( 'Net::LDAP::SimpleServer::LDIFStore',
    ['examples/single-entry.ldif'] );

my $list = $obj->list;
ok( $list, 'Returns a list' );
is( ref($list), 'ARRAY', 'The list is an array-reference' );

is( scalar(@{$list}), 1, 'the list contains one element' );

done_testing();
