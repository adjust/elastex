package App::Elastex::Command::pull;

# ABSTRACT: pull data from Elasticsearch

use strict;
use warnings;
use 5.010;
use autodie;

# VERSION

use App::Elastex -command;

use Date::Parse;
use DateTime::Format::Strptime;
use DateTime::Set;
use JSON::MaybeXS;
use Search::Elasticsearch;
use Term::ProgressBar;

sub usage_desc { "elastex pull [options] query" }

sub opt_spec {
    my ( $self, $app ) = @_;
    return (
        [
            "host|H=s",
            "the Elasticsearch host to connect to",
            { required => 1, default => $app->config->{host} }
        ],
        [
            "port|P=i",
            "the Elasticsearch port to connect to (default:9200)",
            { default => 9200 }
        ],
        [ "progress|p", "show progress bar" ],
        [ "output|o=s", "output file", { default => "results" } ],
        [
            "batchsize=i",
            "batchsize of retrieval (default: 1000)",
            { default => 1000 }
        ],
        [ "countonly", "only count the hits, but do not retrieve anything", ],
        [
            "timezone|t=s",
            "timezone to use for `from` and `to` fields (default: UTC)",
            { default => 'UTC' }
        ],
        [ "from=s", "start of the timerange", { required => 1 } ],
        [
            "to=s",
            "end of the timerange (default: now)",
            { default => DateTime->now }
        ],
        [
            "period=s",
            "period to dump at each iteration (hourly or [daily])",
            { default => 'daily' }
        ],
        [
            "prefix=s",
            "index name prefix, don't forget the trailing `-`",
            { required => 1, default => $app->config->{prefix} }
        ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $query       = join ' ', @$args;
    my @indices     = compile_indices($opt);
    my $index_count = scalar @indices;
    my $json        = JSON::MaybeXS->new();
    my $total_hit_count;

    my $elastic = Search::Elasticsearch->new(
        nodes  => "$opt->{host}:$opt->{port}",
        client => 'Direct',
    );

    my $index_progress = Term::ProgressBar->new(
        {
            name   => 'indices',
            count  => scalar @indices,
            silent => !$opt->{progress},
        }
    );

    my $indices_pulled = 0;
    open( my $output, ">", $opt->{output} ) if !$opt->{countonly};

    for my $index (@indices) {
        my $scroll = $elastic->scroll_helper(
            index       => $index,
            q           => $query,
            search_type => 'scan',
        );
        $indices_pulled  += 1;
        $total_hit_count += $scroll->total;
        $index_progress->update($indices_pulled);
        print STDERR "\n" if !$opt->{countonly};

        next if $opt->{countonly};

        say $output "query: `$query`\tindices: `" . join( ' ', @indices ) . "`";

        my $docs_done     = 0;
        my $docs_progress = Term::ProgressBar->new(
            {
                name   => 'documents',
                count  => $scroll->total,
                silent => !$opt->{progress}
                  || $opt->{countonly}
                  || $scroll->total == 0,
            }
        );
        $docs_progress->minor(0);
        $docs_progress->update($docs_done);

        while ( my @docs = $scroll->next( $opt->{batchsize} ) ) {
            foreach (@docs) {
                $docs_done += 1;
                say $output $json->encode( $_->{_source} );
            }
            $docs_progress->update($docs_done);
        }

        if ( $indices_pulled < $index_count ) {
            $docs_progress->update(0);
            print STDERR "\e[A";
        }
    }

    say "TOTAL HITS: $total_hit_count" if $opt->{countonly};
}

sub compile_indices {
    my $opt   = shift;
    my @dates = compile_dates($opt);

    return map { $opt->{prefix} . $_ } @dates;
}

sub compile_dates {
    my $opt = shift;
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

    return @dates;
}

1;
