package App::Elastex;

# ABSTRACT: export data from Elasticsearch

use strict;
use warnings;

# VERSION

use App::Cmd::Setup -app;

use Config::Any;
use Data::Dumper;

sub config {
    my $app = shift;
    my $config ||=
      Config::Any->load_files( { files => [qw(config.yml)], use_ext => 1 } );

    $app->{config} = $config->[0]->{'config.yml'};
}

1;
