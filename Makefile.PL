use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::LDAP::SimpleServer',
    AUTHOR              => 'Alexei Znamensky <russoz@cpan.org>',
    VERSION_FROM        => 'lib/Net/LDAP/SimpleServer.pm',
    ABSTRACT_FROM       => 'lib/Net/LDAP/SimpleServer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-LDAP-SimpleServer-*' },
);
