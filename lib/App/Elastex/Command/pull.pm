package App::Elastex::Command::pull;

# ABSTRACT: pull data from Elasticsearch

use strict;
use warnings;
use 5.010;
use autodie;
use Fcntl;

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
        [
            "limit|l=i",
            "specify upper limit of total hits for data pull",
            { required => 1 }
        ],
    );
}

sub query {
    my ( $elastic, $indices, $query, $opt, $output, $dry_run ) = @_;
    my $indices_pulled  = 0;
    my $total_hit_count = 0;

    my $index_progress = Term::ProgressBar->new(
        {
            name   => 'indices' . ($dry_run ? ' (count)' : ''),
            count  => scalar @{$indices},
            silent => !$opt->{progress},
        }
    );

    say $output "query: `$query`\tindices: `" . join( ' ', @{$indices} ) . "`"
      if !$dry_run && $opt->{header};

    for my $index (@{$indices}) {
        my $scroll = $elastic->scroll_helper(
            index       => $index,
            q           => $query,
            search_type => 'scan',
        );

        $indices_pulled  += 1;
        $total_hit_count += $scroll->total;
        $index_progress->update($indices_pulled);

        unless ($dry_run) {
            my $index_count = scalar @{$indices};
            my $json        = JSON::MaybeXS->new();

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
    }

    return $total_hit_count;
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

    # Log the query to ~/.elastex_history.
    sysopen( my $log, glob('~/.elastex_history'), O_WRONLY|O_APPEND|O_CREAT, 0600 ) or die "Failed to open ~/.elastex_history for writing: $!";

    my $elastic =
      Search::Elasticsearch->new( nodes => join( ':', $opt->host, $opt->port ),
      );

    my $output;
    if ( $opt->{output} eq '-' ) {
        open( $output, '>&:encoding(UTF-8)', \*STDOUT );
    }
    else {
        open( $output, ">:encoding(UTF-8)", $opt->{output} );
    }

    # Step 1: Count total number of hits for the specified query.
    my $total_hit_count = query($elastic, \@indices, $query, $opt, $output, 'dry run');

    if ( $total_hit_count > 0 ) {
        # Step 2: Fire up the actual query upon successful limit validation.
        if ( $total_hit_count > $opt->{limit} ) {
            say STDERR "Total hit count for query $total_hit_count exceeds limit $opt->{limit}!";
            say STDERR 'Retry with higher limit, warning: if this kills the cluster, goats will haunt you!';
            exit 1;
        }

        # Log the query to the history file.
        say $log "[${\time}] host:'$opt->{host}:$opt->{port}' prefix:'$opt->{prefix}' period='$opt->{period}' from:'$opt->{from}' to:'$opt->{to}' tz='$opt->{timezone}' batchsize=$opt->{batchsize} hits=$total_hit_count $query";
        close $log;

        # Fire!
        query($elastic, \@indices, $query, $opt, $output);
    } else {
        say STDERR 'No results found.';
    }
}

1;
