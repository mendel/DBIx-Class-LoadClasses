#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use TestUtils qw(create_schema);

{
  my @tests = (
    {
      load_classes          => [qw/ CD Artist /],
      expected_sources      => [qw/ CD Artist /],
    },
    {
      load_classes          => [qw/ Artist @media /],
      expected_exception    =>
        qr/Attempt to load an unknown result source group '\@media'/,
    },
    {
      result_source_groups  => {
        media => [qw/ CD @media /],
      },
      load_classes          => [qw/ Artist @media /],
      expected_exception    =>
        qr/Recursively defined result source group '\@media'/,
    },
    {
      result_source_groups  => {
        media => [qw/ CD @stuff /],
        stuff => [qw/ @media /],
      },
      load_classes          => [qw/ Artist @media /],
      expected_exception    =>
        qr/Recursively defined result source group '\@media'/,
    },
    {
      result_source_groups  => {
        media => [qw/ CD Track /],
      },
      load_classes          => [qw/ Artist @media /],
      expected_sources      => [qw/ Artist CD Track /],
    },
    {
      result_source_groups  => {
        media   => [qw/ CD Track /],
        people  => [qw/ Artist Publisher /],
      },
      load_classes          => [qw/ @media @people /],
      expected_sources      => [qw/ CD Track Artist Publisher /],
    },
    {
      result_source_groups  => {
        media             => [qw/ CD Track /],
        media_and_artist  => [qw/ @media Artist /],
      },
      load_classes          => [qw/ @media_and_artist /],
      expected_sources      => [qw/ CD Track Artist /],
    },
    {
      result_source_groups  => {
        media             => [qw/ CD Track /],
        media_and_artist  => [qw/ @media Artist /],
        all_of_them       => [qw/ @media_and_artist Publisher /],
      },
      load_classes          => [qw/ @all_of_them /],
      expected_sources      => [qw/ CD Track Artist Publisher /],
    },
  );

  foreach my $test (@tests) {
    my $schema_name = create_schema(
      result_source_groups => $test->{result_source_groups},
    );

    my $description = Data::Dumper->new([ {
        map { ( $_ => $test->{$_} ) } qw/ result_source_groups load_classes /
      } ])->Terse(1)->Indent(0)->Dump;

    if (!$test->{expected_exception}) {
      lives_ok {
        $schema_name->load_classes(@{ $test->{load_classes} });
      } "__PACKAGE__->load_classes(...) does not die ($description)";

      cmp_deeply(
        [ $schema_name->sources ],
        bag( @{ $test->{expected_sources} || [] } ),
        "the right result source classes are loaded ($description)"
      );
    }
    else {
      throws_ok {
        $schema_name->load_classes(@{ $test->{load_classes} });
      } $test->{expected_exception},
        "__PACKAGE__->load_classes(...) throws the right exception "
          . "($description)";
    }
  }
}

done_testing;
