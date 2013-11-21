use strict;
use warnings;
use inc::Module::Install;

name 'WGE';
abstract 'Serves paired crispr information';
all_from 'lib/WGE.pm';

perl_version '5.10.1';

requires 'Moose';
requires 'Data::Dumper';
requires 'MooseX::NonMoose';
requires 'MooseX::MarkAsMethods';
requires 'Try::Tiny';
requires 'MooseX::ClassAttribute';
requires 'namespace::autoclean';
requires 'YAML';
requires 'Dancer' => 1.3119;
requires 'Dancer::Plugin::DBIC';
requires 'Dancer::Plugin::Ajax';
requires 'Path::Class';
requires 'FindBin';
#requires 'Bio::EnsEMBL::Registry';
#requires 'Bio::Perl';

test_requires 'Test::More';
test_requires 'Test::WWW::Mechanize::PSGI';
test_requires 'URI';

install_script glob('bin/*.pl');
auto_install;
WriteAll;

