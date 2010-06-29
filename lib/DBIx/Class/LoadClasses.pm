package DBIx::Class::LoadClasses;

use strict;
use warnings;

use 5.008001;

use base qw/DBIx::Class/;

=head1 NAME

DBIx::Class::LoadClasses - Load result source classes from the schema import, possibly in groups

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  package MyApp::Schema;

  use strict;
  use warnings;

  use base qw/ DBIx::Class::Schema /;

  __PACKAGE__->load_components(qw/ LoadClasses /);

  __PACKAGE__->define_result_source_groups(
    media  => [qw/ CD Track /],
    people => [qw/ Artist Publisher /],
  );

  1;

  # somewhere else:
  use MyApp::Schema qw/ CD Track Artist /;  # loads CD, Track, Artist

  # or:
  use MyApp::Schema qw/ @media Artist /;  # loads CD, Track, Artist

  # or:
  use MyApp::Schema qw/ @people CD /;  # loads Artist, Publisher, CD

  # or:
  use MyApp::Schema qw/ @media @people /;  # loads CD, Track, Artist, Publisher


=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

The purpose of this module is two-fold:

First, it lets you load the result source classes (see
L<DBIx::Class::Schema/load_classes>) from the C<use> statement that loads your
schema class. If you already loaded them from user code then it results in more
concise code.

Second, it lets you define groups of the most frequently used combinations of
your result sources. If you already loaded only those classes that you actually
used in your code then this way you can manage your lists of classes more
easily.

Those two taken together seem to be a good approach if you have an extensive
schema with lots of classes and you have a number of scripts that each use only
a small but different subset of them. (You only load those classes in each
script that the script actually uses, that way you save startup time and memory
- I<pay for what you use>.)

=head1 EXPORTS

None. The import list is abused to load result source classes (see L</import>).

=head1 METHODS

=cut

__PACKAGE__->mk_classdata(_result_source_groups => {});

=head2 import

After removing the name-value pair options (where the name starts with a dash)
calls L</load_classes> on the remaining list elements. If this remaining list
is empty then C</load_classes> is called with C<@default> instead.

Currently there are no name-value pair options defined so they only trigger a
warning.

Examples:

  # loads the ones in the 'default' bundle:
  use MyApp::Schema;

  # loads only the CD and Track result sources:
  use MyApp::Schema qw/ CD Track /;

  # loads Artist, Publisher and the ones in the '@media' bundle:
  use MyApp::Schema qw/ Artist @media Publisher /;

=cut

sub import {
  my ($class, @imports) = (shift, @_);

  my $caller = caller;

  my @sources;
  for (my $i = 0; $i < @imports; $i++) {
    if ($imports[$i] !~ /^-/) {
      push @sources, $imports[$i];
    }
    else {
      my ($option_name, $option_value) = @imports[$i, $i + 1];
      $i++; # skip the option value
      warn "Ignored import option to $class: $option_name => $option_value";
    }
  }

  if (!@sources) {
    @sources = qw/ @default /;
  }

  $class->load_classes(@sources);
}


=head2 define_result_source_groups

  $schema_class->define_result_source_groups(group_name => \@source_names, ...);

Registers zero or more result source groups.

C<group_name> can be referred to from L</load_classes> (or the C<use>
statement, see L</import>) as C<@group_name>.

C<@source_names> is a list whose elements are result source names (in the
format that L</load_classes> understands) or names of similar groups prefixed
with C<@> signs (in that case the new group will also contain all the source
names that the referred group contains). The depth of recursion is not limited,
loops are detected and are fatal errors.

The order of the group definitions is irrelevant (even if they refer to each
other).

The result source group named C<default> is special: if the import list for the
schema class is empty (after removal of name-value pair options) then
C</load_classes> is called with C<@default> instead.

Examples:

  __PACKAGE__->define_result_source_groups(
    user_stuff    => [qw/ User Address Account /],
    book_stuff    => [qw/ Book Volume Author /],
    library_stuff => [qw/ @user_stuff @book_stuff Borrowing /],
  );

=cut

sub define_result_source_groups {
  my ($class, %groups) = (shift, @_);

  while (my ($group_name, $sources) = each %groups) {
    $class->_result_source_groups->{$group_name} = [ @$sources ]; # cloning it
  }
}


=head2 load_classes

  $schema_class->load_classes(@sources);

Overridden from L<DBIx::Class::Schema/load_classes>. Resolves the result source
groups (names of groups defined in L</define_result_source_groups> prefixed
with C<@> signs) in C<@sources> before calling the original method.

=cut

sub load_classes {
  my ($class, @sources) = (shift, @_);

  $class->next::method( $class->_resolve_result_source_groups(@sources, {}) );
}


=head2 _resolve_result_source_groups

  @resolved_sources
    = $class->_resolve_result_source_groups(@sources, \%seen_sources);

Performs the resolving of the result source groups. C<%seen_sources> is to
catch infinite recursion.

=cut

sub _resolve_result_source_groups {
  my ($class, $seen_sources, @sources) = (shift, pop, @_);

  my @resolved_sources;
  foreach my $source (@sources) {
    if (!ref $source && substr($source, 0, 1) eq '@') {
      $class->throw_exception(
        "Recursively defined result source group '$source'")
        if $seen_sources->{$source}++;
      my $group_members = $class->_result_source_groups->{ substr($source, 1) }
        or $class->throw_exception(
          "Attempt to load an unknown result source group '$source'");
      push @resolved_sources,
        $class->_resolve_result_source_groups(@{ $group_members },
          $seen_sources);
    }
    else {
      push @resolved_sources, $source;
    }
  }

  return @resolved_sources;
}

=head1 SEE ALSO

L<DBIx::Class>.

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Tripwolf Gmbh. (http://www.tripwolf.com) for the time kindly provided
for writing this module.

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-loadclasses at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LoadClasses>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LoadClasses

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LoadClasses>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LoadClasses>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LoadClasses>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LoadClasses/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Norbert Buchmuller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIx::Class::LoadClasses
