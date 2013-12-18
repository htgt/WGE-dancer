-- all times are with just chr19 i.e. 8,103,150 rows
CREATE TABLE species (
    id                SERIAL PRIMARY KEY,
    name              TEXT NOT NULL
);

INSERT INTO species (name) VALUES ('Human'), ('Mouse');

CREATE TABLE crisprs (
    id                 SERIAL PRIMARY KEY,
    chr_name           TEXT NOT NULL,
    chr_start          INTEGER NOT NULL,
    seq                TEXT NOT NULL,
    pam_right          BOOLEAN NOT NULL,
    species_id         INTEGER NOT NULL,
    off_targets        INTEGER[],
    off_target_summary TEXT
);

-- \copy crisprs(chr_name, chr_start, seq, pam_right, species_id) from '/var/tmp/chr19_crisprs.csv' with delimiter ','
-- 92 seconds

ALTER TABLE crisprs ADD CONSTRAINT crispr_species_fk FOREIGN KEY (species_id) REFERENCES species (id);
-- 2611.799 ms
ALTER TABLE crisprs ADD CONSTRAINT crispr_unique_loci UNIQUE ( chr_start, chr_name, pam_right, species_id );
-- 13380.068 ms
CREATE INDEX idx_crispr_loci ON crisprs (chr_name, chr_start, species_id);
-- 218722.289 ms (3.6 minutes)

--add back foreign key on species_id,
--add unique constraint back in,
--recreate index

