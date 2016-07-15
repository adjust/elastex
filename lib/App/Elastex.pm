package App::Elastex;

# ABSTRACT: export data from Elasticsearch

use strict;
use warnings;

our $VERSION = '1.0.0_03';

use App::Cmd::Setup -app;

use Config::Any;
use Cwd;
use File::HomeDir;
use File::Spec;

sub global_opt_spec {
    return ( [ "config|C=s", "configuration file to use" ], );
}

sub config {
    my $app = shift;

    return $app->{config} if defined $app->{config};

    my $config = Config::Any->load_files(
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
    elsif ( defined $ENV{ELASTEXRC} ) {
        push @config_files, $ENV{ELASTEXRC};
    }
    else {
        push @config_files, File::Spec->join( cwd(), 'config.yml' );
        push @config_files,
          File::Spec->join( File::HomeDir->my_home, '.elastexrc' );
        push @config_files,
          File::Spec->join( File::Spec->rootdir, 'etc', 'elastexrc' );
    }

    return @config_files;
}

1;
