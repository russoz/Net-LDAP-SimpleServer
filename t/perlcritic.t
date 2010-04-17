#!perl

use Test::More;

SKIP: {
    skip "Author tests aren't required to install this module", 1
      unless $ENV{RUSSOZ_IS_IN_THE_HOUSE};

    diag("Who's in the house? Russoz is in the house! Uh Uh!");

    eval 'require Test::Perl::Critic';

    if ($@) {
        Test::More::plan( skip_all =>
              "Test::Perl::Critic required for testing PBP compliance" );
    }

    Test::Perl::Critic::all_critic_ok();

}

done_testing();

