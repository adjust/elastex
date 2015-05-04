package App::Elastex;

# ABSTRACT: export data from Elasticsearch

use strict;
use warnings;

# VERSION

use App::Cmd::Setup -app;

use Config::Any;
use Data::Dumper;

sub global_opt_spec {
    my $self = shift;
    return (
        [
            "host|H=s",
            "the Elasticsearch host to connect to",
            { required => 1, default => $self->config->{host} }
        ],
        [
            "port|P=i",
            "the Elasticsearch port to connect to (default:9200)",
            { default => 9200 }
        ],
        [
            "prefix=s",
            "index name prefix, don't forget the trailing `-`",
            { required => 1, default => $self->config->{prefix} }
        ],
    );
}

sub config {
    my $app = shift;
    my $config ||=
      Config::Any->load_files( { files => [qw(config.yml)], use_ext => 1 } );

    $app->{config} = $config->[0]->{'config.yml'};
}

1;
