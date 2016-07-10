package App::Elastex::Command::pull;

# ABSTRACT: pull data from Elasticsearch

use strict;
use warnings;
use 5.010;
use autodie;

# VERSION

use App::Elastex -command;

use JSON::MaybeXS;
use Search::Elasticsearch;
use Term::ProgressBar;

sub usage_desc { "elastex pull [options] query" }

sub opt_spec {
    my ( $self, $app ) = @_;
    return (
        $self->SUPER::opt_spec($app),
        [
            "output|o=s",
            "output file (default: results)",
            { default => $app->{config}->{output} // "results" }
        ],
        [
            "batchsize=i",
            "batchsize of retrieval (default: 1000)",
            { default => $app->{config}->{batchsize} // 1000 }
        ],
        [
            "header!",
            "write query header to output (default: 1)",
            { default => $app->{config}->{header} // 1 }
        ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $query = join ' ', @$args;
    my @indices = $self->SUPER::compile_indices(
        {
            prefix   => $opt->prefix,
            from     => $opt->from,
            to       => $opt->to,
            timezone => $opt->timezone,
            period   => $opt->period,
        }
    );

    my $index_count = scalar @indices;
    my $json        = JSON::MaybeXS->new();

    my $elastic =
      Search::Elasticsearch->new( nodes => join( ':', $opt->host, $opt->port ),
      );

    my $index_progress = Term::ProgressBar->new(
        {
            name   => 'indices',
            count  => scalar @indices,
            silent => !$opt->{progress},
        }
    );

    my $indices_pulled  = 0;
    my $total_hit_count = 0;
    my $output;

    if ( $opt->{output} eq '-' ) {
        open( $output, '>&:encoding(UTF-8)', \*STDOUT );
    }
    else {
        open( $output, ">:encoding(UTF-8)", $opt->{output} );
    }

    say $output "query: `$query`\tindices: `" . join( ' ', @indices ) . "`"
      if $opt->{header};

    for my $index (@indices) {
        my $scroll = $elastic->scroll_helper(
            index       => $index,
            q           => $query,
            search_type => 'scan',
        );

        $indices_pulled  += 1;
        $total_hit_count += $scroll->total;
        $index_progress->update($indices_pulled);
        print STDERR "\n";

        my $docs_done     = 0;
        my $docs_progress = Term::ProgressBar->new(
            {
                name   => 'documents',
                count  => $scroll->total,
                silent => !$opt->{progress} || $scroll->total == 0,
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

    say STDERR 'No results found.' if $total_hit_count == 0;
}

1;
