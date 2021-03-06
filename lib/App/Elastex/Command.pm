package App::Elastex::Command;

use strict;
use warnings;

use App::Cmd::Setup -command;

use Date::Parse;
use DateTime::Format::Strptime;
use DateTime::Set;

sub opt_spec {
    my ( $self, $app ) = @_;

    $app->config;

    return (
        [
            "host|H=s",
            "the Elasticsearch host to connect to (default: localhost)",
            { required => 1, default => $app->{config}->{host} // 'localhost' }
        ],
        [
            "port|P=i",
            "the Elasticsearch port to connect to (default: 9200)",
            { default => $app->{config}->{port} // 9200 }
        ],
        [
            "prefix=s",
"index name prefix, don't forget the trailing `-` (default: logstash-)",
            {
                required => 1,
                default  => $app->{config}->{prefix} // 'logstash-'
            }
        ],
        [
            "timezone|t=s",
            "timezone to use for `from` and `to` fields (default: UTC)",
            { default => $app->{config}->{timezone} // 'UTC' }
        ],
        [ "from=s", "start of the timerange", { required => 1 } ],
        [
            "to=s",
            "end of the timerange (default: now)",
            { default => DateTime->now }
        ],
        [
            "period=s",
            "period to dump at each iteration (default: daily)",
            { default => $app->{config}->{period} // 'daily' }
        ],
        [
            "progress|p",
            "show progress bar (default: 0)",
            { default => $app->{config}->{progress} // '0' }
        ],
    );
}

sub compile_indices {
    my ( $self, $opt ) = @_;
    my @dates = $self->compile_dates($opt);
    return map { $opt->{prefix} . $_ } @dates;
}

sub compile_dates {
    my ( $self, $opt ) = @_;
    my $start =
      DateTime->from_epoch(
        epoch => str2time( $opt->{from}, $opt->{timezone} ) );
    my $end =
      DateTime->from_epoch( epoch => str2time( $opt->{to}, $opt->{timezone} ) );

    my $dates = DateTime::Set->from_recurrence(
        start      => $start->truncate( to => 'hour' ),
        end        => $end->truncate( to   => 'hour' ),
        recurrence => sub {
            $opt->{period} eq 'hourly'
              ? return $_[0]->truncate( to => 'hour' )->add( hours => 1 )
              : return $_[0]->truncate( to => 'day' )->add( days => 1 );
        },
    );

    my $iterator = $dates->iterator;
    my $formatter =
      $opt->{period} eq 'hourly'
      ? DateTime::Format::Strptime->new( pattern => '%Y.%m.%d.%H' )
      : DateTime::Format::Strptime->new( pattern => '%Y.%m.%d*' );
    my @dates;

    while ( my $date = $iterator->next ) {
        $date->set_formatter($formatter);
        push @dates, $date;
    }

    return map { "$_" } @dates;
}

1;
