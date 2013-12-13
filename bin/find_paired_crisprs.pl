#!/usr/bin/env perl

use strict;
use warnings;

use feature qw( say );
use YAML::Any qw( DumpFile );
use Getopt::Long;
use Pod::Usage;
use Path::Class;
use Try::Tiny;
use Bio::Perl qw( revcom );
use Data::Dumper;

my ( $environment, $species, @gene_ids, $fq_file, $crispr_file, $pair_file );
GetOptions(
    "help"               => sub { pod2usage( 1 ) },
    "man"                => sub { pod2usage( 2 ) },
    "environment=s"      => \$environment,
    "species=s"          => sub { my ( $name, $val ) = @_; $species = ucfirst( lc $val ); },
    "gene-ids=s{,}"      => \@gene_ids,
#    "exon-ids=s{,}"      => \@exon_ids,
    "fq-file=s"          => sub { my ( $name, $val ) = @_; $fq_file = file( $val ); },
    "crispr-yaml-file=s" => \$crispr_file,
    "pair-yaml-file=s"   => \$pair_file,
) or pod2usage( 2 );

die pod2usage( 2 ) unless $species and $environment and @gene_ids and $fq_file and $pair_file and $crispr_file;

use Dancer ':script';
#setting envdir => '/nfs/users/nfs_a/ah19/work/dancer_envs';
setting environment => $environment;
Dancer::Config::load();

use Dancer::Plugin::DBIC qw( schema );

say "Species is " . $species;

my @genes = schema->resultset('Gene')->search(
    {
        species_id      => $species,
        ensembl_gene_id => { -IN => \@gene_ids }
    }
);

die "Couldn't find any genes for " . join( ", ", @gene_ids ) unless @genes;

my $fq_fh = $fq_file->openw || die "Can't open $fq_file";
my ( %crispr_data, %pair_data );

for my $gene ( @genes ) {
    say "Processing " . $gene->ensembl_gene_id;
    my @pairs = $gene->pairs_fast;
    for my $pair ( @pairs ) {
        if ( defined $fq_fh ) {
            say $fq_fh get_fq_line( $gene->ensembl_gene_id, $pair, "left" );
            say $fq_fh get_fq_line( $gene->ensembl_gene_id, $pair, "right" );
        }

        $crispr_data{$gene->ensembl_gene_id}->{$pair->left_crispr_id} = {};
        $crispr_data{$gene->ensembl_gene_id}->{$pair->right_crispr_id} = {};

        push @{ $pair_data{$gene->ensembl_gene_id} },  
            {
                pair_id      => $pair->pair_id,
                left_crispr  => $pair->left_crispr_id,
                right_crispr => $pair->right_crispr_id,
            };
    }

    say "Found: " . scalar( @pairs ) . " pairs for " . $gene->ensembl_gene_id;
}

DumpFile( $crispr_file, \%crispr_data );
DumpFile( $pair_file, \%pair_data );

sub get_fq_line {
    my ( $gene_id, $pair, $direction ) = @_;

    my ( $header, $seq );
    if ( $direction eq "left" ) {
        $header = ">" . $gene_id . "_" . $pair->left_crispr_id . "A";
        $seq = revcom( $pair->left_crispr_seq )->seq;
    }
    elsif ( $direction eq "right" ) {
        $header = ">" . $gene_id . "_" . $pair->right_crispr_id . "B";
        $seq = $pair->right_crispr_seq;
    }
    else {
        die "invalid direction: $direction";
    }

    return $header . "\n" . $seq;
}

1;

__END__

=head1 NAME

find_paired_crisprs.pl - find paired crisprs for specific genes

=head1 SYNOPSIS

find_paired_crisprs.pl [options]

    --species            mouse or human
    --gene-ids           a list of ensembl gene ids
    --fq-file            where to output the crispr fq data
    --crispr-yaml-file   where to output the crispr yaml data
    --pair-yaml-file     wgere to output the pair yaml data
    --help               show this dialog

Example usage:

find_paired_crisprs.pl --species mouse --gene-ids ENSMUSG00000018666 --fq-file ~/work/crisprs/hprt_crisprs.fq --crispr-yaml-file ~/work/crisprs/hprt_crisprs.yaml

=head1 DESCRIPTION

Find all possible crispr sites within exon sequences, and any possible pairs within them. 
The crispr-yaml file is created with the intention of being given to wge to load into the db
The fq file is intended to be handed to bwa.

=head AUTHOR

Alex Hodgkins

=cut
