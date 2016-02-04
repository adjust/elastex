package App::Elastex;

# ABSTRACT: export data from Elasticsearch

use strict;
use warnings;

# VERSION

use App::Cmd::Setup -app;

use Config::Any;

sub global_opt_spec {
    return ( [ "config|C=s", "configuration file to use" ], );
}

sub config {
    my $app = shift;
    my $config ||= Config::Any->load_files(
        {
            files   => [ $app->get_config_files ],
            use_ext => 0,
            force_plugins =>
              [qw(Config::Any::General Config::Any::JSON Config::Any::YAML)]
        }
    );

    $app->{config} = ( values %{ $config->[0] } )[0];
}

sub get_config_files {
    my $self = shift;
    my @config_files;

    if ( defined $self->global_options->{config} ) {
        push @config_files, $self->global_options->{config};
    }
    else {
        push @config_files, 'config.yml';
    }

    return @config_files;
}

1;
