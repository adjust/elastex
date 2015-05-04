use strict;
use warnings;
use 5.010;

use Test::More tests => 4;

use App::Elastex::Command::pull;

{
    my @dates = App::Elastex::Command::pull::compile_dates(
        {
            from     => '2014-04-27',
            to       => '2014-04-27',
            period   => 'daily',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(2014.04.27*)], 'single day with daily';
}

{
    my @dates = App::Elastex::Command::pull::compile_dates(
        {
            from     => '2014-04-27',
            to       => '2014-04-28',
            period   => 'daily',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(2014.04.27* 2014.04.28*)],
      'multiple days with daily';
}

{
    my @dates = App::Elastex::Command::pull::compile_dates(
        {
            from     => '2014-04-27 00:00:00',
            to       => '2014-04-27 00:00:00',
            period   => 'hourly',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(2014.04.27.00)], 'multiple hours with hourly';
}

{
    my @dates = App::Elastex::Command::pull::compile_dates(
        {
            from     => '2014-04-27 00:00:00',
            to       => '2014-04-27 01:00:00',
            period   => 'hourly',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(2014.04.27.00 2014.04.27.01)],
      'multiple hours with hourly';
}
