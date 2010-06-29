package TestUtils;

use strict;
use warnings;

use Class::MOP;
use Data::Dumper;
require DBIx::Class::Schema;
require DBIx::Class::Core;

use base qw/ Exporter /;

our @EXPORT_OK = qw/
  &create_schema
/;

my $schema_nr;  # would be a "state" var on a newer Perl..

=head2 create_schema

  $schema_name = create_schema();
  $schema_name
    = create_schema( result_source_groups => \%result_source_groups);

Creates a new schema (named like B<< TestSchema >>I<< <n> >> where I<n> is a
serial number) with the following result sources: Artist, CD, Track, Publisher,
Manufacturer.

The L<DBIx::Class::LoadClasses> component is loaded into the schema.

If C<%result_source_groups> is defined, calls C<<
__PACKAGE__->result_source_groups(%result_source_groups >>.

=cut

sub create_schema {
  my (%arg) = @_;

  my $schema_name = 'TestSchema' . ++$schema_nr;

  my $schema_meta = Class::MOP::Class->create($schema_name,
    superclasses => [ 'DBIx::Class::Schema' ],
  );

  $schema_meta->find_method_by_name('load_components')
    ->execute($schema_name, 'LoadClasses');

  if ($arg{result_source_groups}) {
    $schema_name->meta->find_method_by_name('result_source_groups')
      ->execute($schema_name, %{ $arg{result_source_groups} });
  }

  foreach my $moniker (qw/ Artist CD Track Publisher Manufacturer /) {
    my $result_source_name = "$schema_name\::$moniker";
    my $result_source_meta = Class::MOP::Class->create($result_source_name,
      superclasses => [ 'DBIx::Class::Core' ],
    );

    $result_source_meta->find_method_by_name('table')
      ->execute($result_source_name, lc $moniker);
  }

  return $schema_name;
}

1;
