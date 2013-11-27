package WGE;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw( schema );
use Dancer::Plugin::Ajax;

use Data::Dumper;
use feature qw( say );

our $VERSION = '0.1';

set layout => 'main';

prefix undef;

#explicitly set the layout to main for non ajax methods in case
#it was unset somewhere
hook before => sub {
    unless ( request->is_ajax ) {
        setting layout => 'main';
    }
};

#we have to explicitly set the layout to main because
#we often detach mid ajax method, which leaves the layout set to undef
get '/' => sub {
    template 'index', {}, { layout => 'main' };
};

get '/numbers' => sub {
    template 'numbers', { 
        num_genes   => schema->resultset('Gene')->count, 
        num_exons   => schema->resultset('Exon')->count,
        num_crisprs => schema->resultset('Crispr')->count,
        num_pairs   => schema->resultset('CrisprPair')->count,
    };
};

get '/about' => sub {
    template 'about', {}, { layout => 'main' };
};

get '/contact' => sub {
    template 'contact', {}, { layout => 'main' };
};

#everything below here is api
prefix '/api';

ajax '/gene_search' => sub {
    check_params_exist( scalar( params ), [ 'name', 'species' ] );

    debug 'Searching for marker symbol ' . params->{name} . ' for ' . params->{species};

    my @genes = schema->resultset('Gene')->search( 
        {
            #'marker_symbol' => { ilike => '%'.param("name").'%' },
            'UPPER(marker_symbol)' => { like => '%'.uc( param("name") ).'%' },
            'species_id'           => param("species"),
        }
    );

    #return a list of hashrefs with the matching gene data
    return [ sort map { $_->marker_symbol } @genes ];
};

ajax '/exon_search' => sub {
    check_params_exist( scalar( params ), [ 'marker_symbol', 'species' ] );

    debug 'Finding exons for gene ' . params->{marker_symbol};

    my $gene = schema->resultset('Gene')->find(
        { marker_symbol => params->{marker_symbol}, species_id => params->{species} },
        { prefetch => 'exons', order_by => { -asc => 'ensembl_exon_id' } }
    );

    send_error( "No exons found", 400 ) unless $gene;

    my @exons = map { 
            {
                exon_id => $_->ensembl_exon_id, 
                rank    => $_->rank,
                len     => $_->chr_end - $_->chr_start,
            } 
        } sort { $a->rank <=> $b->rank } $gene->exons;

    #return a list of hashrefs with the matching exon ids and ranks
    return { transcript => $gene->canonical_transcript, exons => \@exons };
};

ajax '/crispr_search' => sub {
    check_params_exist( scalar( params ), [ 'exon_id[]' ] );

    return _get_exon_attribute( "crisprs", params->{ 'exon_id[]' } );
};

ajax '/pair_search' => sub {
    check_params_exist( scalar( params ), [ 'exon_id[]' ] );

    return _get_exon_attribute( "pairs", params->{ 'exon_id[]' } );
};

#
# should these go into a util module? (yes)
#

#used to retrieve pairs or crisprs from an arrayref of exons
sub _get_exon_attribute {
    my ( $attr, $exon_ids ) = @_;

    send_error( 'No exons given to _get_exon_attribute' ) 
        unless defined $exon_ids;

    #allow an arrayref or a single array
    my @exon_ids = ( ref $exon_ids eq 'ARRAY' ) ? @{ $exon_ids } : ( $exon_ids );

    #make sure attr is pairs or crisprs
    unless ( $attr eq 'pairs' || $attr eq 'crisprs' ) {
        send_error 'attribute must be pairs or crisprs';
        return;
    }

    my %data;
    for my $exon_id ( @exon_ids ) {
        #make sure the exon exists
        my $exon = schema->resultset('Exon')->find( { ensembl_exon_id => $exon_id } );
        send_error( "Invalid exon id", 400 ) unless $exon;

        debug 'Finding ' . $attr . ' for: ' . join( ", ", @exon_ids );

        #store each exons data as an arrayref of hashrefs
        $data{$exon_id} = [ map { $_->as_hash } $exon->$attr ];
    }

    return \%data;
}

#should use FormValidator::Simple or something later
#takes a hashref and an arrayref of required options,
#e.g. check_params_exist( { test => 1 } => [ 'test' ] );
#you must wrap params in scalar otherwise it comes as a hash
sub check_params_exist {
    my ( $params, $options ) = @_;

    for my $option ( @{ $options } ) {
        send_error( "Error: " . ucfirst(lc $option) . " is required", 400 ) unless defined $params->{$option};
    }
}

prefix undef;


true;
