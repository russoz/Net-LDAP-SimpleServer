#!/usr/bin/env perl

use strict;
use warnings;

# PODNAME:  ldapd.pl
# ABSTRACT: Script to invoke the LDAP server.

# VERSION

use Net::LDAP::SimpleServer;

my $server =
  @ARGV
  ? Net::LDAP::SimpleServer->new( {@ARGV} )
  : Net::LDAP::SimpleServer->new;

$server->run();

__END__

=head1 SYNOPSIS

	host:~ # ldapd.pl

=head1 DESCRIPTION

This script simply instantiates and executes a L<Net::LDAP::SimpleServer>
server.

=cut

