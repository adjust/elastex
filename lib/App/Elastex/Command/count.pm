package App::Elastex::Command::count;

# ABSTRACT: count Elasticsearch query hits

use strict;
use warnings;
use 5.010;

# VERSION

use App::Elastex -command;

use Search::Elasticsearch;
use Term::ProgressBar;

sub usage_desc { "elastex count [options] query" }

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $query = join ' ', @$args;

    my @indices = $self->SUPER::compile_indices(
        {
            prefix   => $self->app->global_options->prefix,
            from     => $opt->from,
            to       => $opt->to,
            timezone => $opt->timezone,
            period   => $opt->period,
        }
    );

    my $index_count = scalar @indices;
    my $total_hit_count;

    my $elastic = Search::Elasticsearch->new(
        nodes => join( ':',
            $self->app->global_options->host,
            $self->app->global_options->port ),
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

    for my $index (@indices) {
        my $scroll = $elastic->scroll_helper(
            index       => $index,
            q           => $query,
            search_type => 'scan',
        );

        $indices_pulled  += 1;
        $total_hit_count += $scroll->total;
        $index_progress->update($indices_pulled);

    }

    say "TOTAL HITS: $total_hit_count";
}

1;
