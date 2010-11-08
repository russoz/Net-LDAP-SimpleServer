use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Net::LDAP::SimpleServer',
    license           => 'perl',
    dist_author       => 'Alexei Znamensky <russoz@cpan.org>',
    dist_version_from => 'lib/Net/LDAP/SimpleServer.pm',
    requires          => {
        'Net::Server'       => 0.91,     # must have a new() method
        'Net::LDAP'         => 0.4001,
        'Net::LDAP::Server' => 0.43,     # must support 2-params constructor
        'UNIVERSAL::isa'    => 0,
        'Scalar::Util'      => 0,
        'File::Path'        => 0,
        'File::Spec'        => 0,
        'File::HomeDir'     => 0,
        'File::Basename'    => 0,
        'Test::More'        => 0,
        'IO::Pipe'          => 0,
        'common::sense'     => 0,
        'version'           => 0,
        'Carp'              => 0,
    },
    add_to_cleanup => ['Net-LDAP-SimpleServer-*'],
);

$builder->create_build_script();
