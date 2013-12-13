use utf8;
package WGE::Model::Schema::ResultSet::CrisprPairRegion;

use base 'DBIx::Class::ResultSet';

#given an object with chr_name/chr_start/chr_end find all pairs/crisprs within
sub search_by_loci {
    my ( $self, $obj, $options ) = @_;

    #options is a hashref to pass to dbix class

    die "You must provide an object" unless defined $obj;

    die "Object passed to search_by_loci must have chr_name, chr_start and chr_end methods."
        unless $obj->can('chr_name') && $obj->can('chr_start') && $obj->can('chr_end');

    #$obj should be an object with chr_name, chr_start and chr_end methods,
    #(for example a gene or exon object)

    #this will overwrite any rubbish the user puts in here.
    $options->{bind} = [ $obj->chr_name, $obj->chr_start, $obj->chr_end ];

    return $self->search(
        {},
        $options
    );
}

1;
