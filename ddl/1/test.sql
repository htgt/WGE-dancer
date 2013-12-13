-- schema
CREATE TABLE crisprs
    ( id integer, arr integer[] )
;
    
INSERT INTO crisprs
    (id, arr)
VALUES
    (1, '{1, 2, 3}'),
    (2, '{3, 4, 5}'),
    (3, '{6, 7}')
;

CREATE TABLE crispr_off_targets
    (id integer, chr_name integer, chr_start integer)
;
    
INSERT INTO crispr_off_targets
    (id, chr_name, chr_start)
VALUES
    (1, 2, 8547656),
    (2, 4, 3547656),
    (3, 5, 1547656),
    (4, 6, 56),
    (5, 8, 5656),
    (6, 9, 854),
    (7, 10, 54732)
;

-- test query
select crispr.id, crispr.ot_id, ot.chr_start
from ( 
  select id, unnest(arr) as ot_id from crisprs
) crispr
inner join crispr_off_targets ot on crispr.ot_id=ot.id;