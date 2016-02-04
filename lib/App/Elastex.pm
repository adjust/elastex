package App::Elastex;

# ABSTRACT: export data from Elasticsearch

use strict;
use warnings;

# VERSION

use App::Cmd::Setup -app;

use Config::Any;

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
    my $config ||= Config::Any->load_files(
        {
            files   => [ $app->get_config_files ],
            use_ext => 1,
            force_plugins =>
              [qw(Config::Any::General Config::Any::JSON Config::Any::YAML)]
        }
    );

    $app->{config} = $config->[0]->{'config.yml'};
}

sub get_config_files {
    my $self = shift;
    my @config_files;

    push @config_files, 'config.yml';

    return @config_files;
}

1;
