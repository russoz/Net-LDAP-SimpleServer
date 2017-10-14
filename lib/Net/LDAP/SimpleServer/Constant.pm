package Net::LDAP::SimpleServer::Constant;

use strict;
use warnings;

# ABSTRACT: Constants used in Net::LDAP::SimpleServer

# VERSION

use Exporter 'import';
our @EXPORT_OK = qw(SCOPE_BASEOBJ SCOPE_ONELEVEL SCOPE_SUBTREE);

use constant SCOPE_BASEOBJ  => 0;
use constant SCOPE_ONELEVEL => 1;
use constant SCOPE_SUBTREE  => 2;

1;    # Magic true value required at end of module

