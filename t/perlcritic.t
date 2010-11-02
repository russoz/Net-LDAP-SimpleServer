#!perl

use Test::More;

if ( !exists $ENV{RUSSOZ_IS_IN_THE_HOUSE} ) {
    plan skip_all => "Author tests aren't required to install this module";
}

diag("Who's in the house? Russoz is in the house! Uh Uh!");

eval { require Test::Perl::Critic; };

if ($@) {
    plan skip_all => "Test::Perl::Critic required for testing PBP compliance";
}

Test::Perl::Critic::all_critic_ok();

#done_testing();

