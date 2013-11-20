#!/usr/bin/env perl

use strict;
use warnings;

use feature qw( say );
use YAML::Any qw( LoadFile );

die "Usage: load_genes.pl <environment> <filenames>" unless @ARGV >= 2;
my $env = shift @ARGV;

use Dancer ':script';
setting environment => $env;
Dancer::Config::load();

use Dancer::Plugin::DBIC qw( schema );

use Try::Tiny;

#load each yaml file into the db
for my $filename ( @ARGV ) {
    my $genes_yaml = LoadFile( $filename ) || die "Couldn't open $filename: $!";

    $schema->resultset('Gene')->load_from_hash( $genes_yaml );
}

1;
