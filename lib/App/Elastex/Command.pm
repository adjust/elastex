package App::Elastex::Command;

use strict;
use warnings;

# VERSION

use App::Cmd::Setup -command;

use Date::Parse;
use DateTime::Format::Strptime;
use DateTime::Set;

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
