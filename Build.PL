use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::LDAP::SimpleServer',
    license             => 'perl',
    dist_author         => 'Alexei Znamensky <russoz@cpan.org>',
    dist_version_from   => 'lib/Net/LDAP/SimpleServer.pm',
    requires => {
        'UNIVERSAL::isa'  => 0,
        'File::Spec::Functions' => 0,
        'Scalar::Util'    => 0,
        'Config::General' => 0,
        'File::HomeDir'   => 0,
        'Test::More'      => 0,
        'version'         => 0,
        'Carp'            => 0,
    },
    add_to_cleanup      => [ 'Net-LDAP-SimpleServer-*' ],
);

$builder->create_build_script();
