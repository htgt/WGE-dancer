use utf8;
package WGE::Model::Schema::Result::CrisprPairRegion;

=head1 NAME

WGE::Model::Schema::Result::CrisprPairRegion

=head1 DESCRIPTION

Custom view that selects all pairs and crisprs in a given region

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );
__PACKAGE__->table( 'gene_crispr_pairs' );

__PACKAGE__->result_source_instance->is_virtual(1);
# __PACKAGE__->result_source_instance->view_definition( <<'EOT' );
# WITH gene as ( select * from genes where id=? )
# SELECT 
#     g.id         gene_id,
#     cp.id        pair_id,
#     cp.spacer    spacer,
#     lc.id        left_crispr_id,
#     lc.seq       left_crispr_seq,
#     lc.chr_start left_crispr_start,
#     lc.chr_end   left_crispr_end,
#     rc.id        right_crispr_id,
#     rc.seq       right_crispr_seq,
#     rc.chr_start right_crispr_start,
#     rc.chr_end   right_crispr_end
# FROM gene g 
# JOIN crisprs lc 
# ON lc.chr_name = g.chr_name 
# AND lc.chr_start >= g.chr_start 
# AND lc.chr_end <= g.chr_end 
# JOIN crispr_pairs cp ON lc.id = cp.left_crispr_id
# JOIN crisprs rc ON cp.right_crispr_id = rc.id
# EOT

#first values that must be bound are chromosome name, then start and end co-ordinates.
#the query joins to pairs on left crispr id, then back to crisprs on the right crispr id,
#giving all pairs and l/r crisprs as distinct entries 
__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
SELECT
    cp.id        pair_id,
    cp.spacer    spacer,
    lc.id        left_crispr_id,
    lc.seq       left_crispr_seq,
    lc.chr_start left_crispr_start,
    lc.chr_end   left_crispr_end,
    rc.id        right_crispr_id,
    rc.seq       right_crispr_seq,
    rc.chr_start right_crispr_start,
    rc.chr_end   right_crispr_end
FROM crisprs lc
JOIN crispr_pairs cp ON lc.id=cp.left_crispr_id
JOIN crisprs rc ON cp.right_crispr_id=rc.id
WHERE lc.chr_name = ? AND lc.chr_end >= ? AND lc.chr_start <= ?
EOT

#could maybe auto generate the columns and insert into the above heredoc
__PACKAGE__->add_columns(
    qw(  
        pair_id
        spacer 
        left_crispr_id 
        left_crispr_seq
        left_crispr_start
        left_crispr_end
        right_crispr_id
        right_crispr_seq
        right_crispr_start
        right_crispr_end
    )
);

__PACKAGE__->set_primary_key( "pair_id" );

#you shouldn't need these but you've got the option
__PACKAGE__->belongs_to(
    "pair",
    "WGE::Model::Schema::Result::CrisprPair",
    { id => "pair_id" },
);

__PACKAGE__->belongs_to(
    "left_crispr",
    "WGE::Model::Schema::Result::Crispr",
    { id => "left_crispr_id" },
);

__PACKAGE__->belongs_to(
    "right_crispr",
    "WGE::Model::Schema::Result::Crispr",
    { id => "right_crispr_id" },
);


__PACKAGE__->meta->make_immutable;

1;