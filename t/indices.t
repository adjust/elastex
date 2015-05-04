use strict;
use warnings;
use lib 'lib';

use Test::More tests => 4;

use App::Elastex::Command;

{
    my @dates = App::Elastex::Command->compile_indices(
        {
            prefix   => 'logstash-',
            from     => '2014-04-27',
            to       => '2014-04-27',
            period   => 'daily',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(logstash-2014.04.27*)], 'single daily index';
}

{
    my @dates = App::Elastex::Command->compile_indices(
        {
            prefix   => 'logstash-',
            from     => '2014-04-27',
            to       => '2014-04-28',
            period   => 'daily',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(logstash-2014.04.27* logstash-2014.04.28*)],
      'multiple daily indices';
}

{
    my @dates = App::Elastex::Command->compile_indices(
        {
            prefix   => 'logstash-',
            from     => '2014-04-27 00:00:00',
            to       => '2014-04-27 00:00:00',
            period   => 'hourly',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(logstash-2014.04.27.00)], 'single hourly index';
}

{
    my @dates = App::Elastex::Command->compile_indices(
        {
            prefix   => 'logstash-',
            from     => '2014-04-27 00:00:00',
            to       => '2014-04-27 01:00:00',
            period   => 'hourly',
            timezone => 'UTC',
        }
    );

    is_deeply \@dates, [qw(logstash-2014.04.27.00 logstash-2014.04.27.01)],
      'multiple hourly indices';
}
