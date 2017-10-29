package Net::LDAP::SimpleServer::Constant;

use strict;
use warnings;

# ABSTRACT: Constants used in Net::LDAP::SimpleServer

# VERSION

use Exporter 'import';
our @EXPORT = qw(SCOPE_BASEOBJ SCOPE_ONELEVEL SCOPE_SUBTREE
  USER_PW_NONE USER_PW_ALL USER_PW_MD5);

use constant SCOPE_BASEOBJ  => 0;
use constant SCOPE_ONELEVEL => 1;
use constant SCOPE_SUBTREE  => 2;

use constant USER_PW_NONE => 'none';
use constant USER_PW_ALL  => 'all';
use constant USER_PW_MD5  => 'md5';

1;    # Magic true value required at end of module

