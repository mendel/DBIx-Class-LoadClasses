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
      import                => [qw/ CD Artist /],
      expected_sources      => [qw/ CD Artist /],
    },
    {
      import                => [qw/ Artist @media /],
      expected_exception    =>
        qr/Attempt to load an unknown result source group '\@media'/,
    },
    {
      result_source_groups  => {
        media => [qw/ CD @media /],
      },
      import                => [qw/ Artist @media /],
      expected_exception    =>
        qr/Recursively defined result source group '\@media'/,
    },
    {
      result_source_groups  => {
        media => [qw/ CD Track /],
      },
      import                => [qw/ Artist @media /],
      expected_sources      => [qw/ Artist CD Track /],
    },
    {
      import                => [qw/ /],
      expected_exception    =>
        qr/Attempt to load an unknown result source group '\@default'/,
    },
    {
      result_source_groups  => {
        default => [qw/ CD Artist /],
      },
      import                => [qw/ /],
      expected_sources      => [qw/ CD Artist /],
    },
  );

  foreach my $test (@tests) {
    my $schema_name = create_schema(
      result_source_groups => $test->{result_source_groups},
    );

    my $description = Data::Dumper->new([ {
        map { ( $_ => $test->{$_} ) } qw/ result_source_groups import /
      } ])->Terse(1)->Indent(0)->Dump;

    if (!$test->{expected_exception}) {
      lives_ok {
        $schema_name->import(@{ $test->{import} });
      } "__PACKAGE__->import(...) does not die ($description)";

      cmp_deeply(
        [ $schema_name->sources ],
        bag( @{ $test->{expected_sources} || [] } ),
        "the right result source classes are loaded ($description)"
      );
    }
    else {
      throws_ok {
        $schema_name->import(@{ $test->{import} });
      } $test->{expected_exception},
        "__PACKAGE__->import(...) throws the right exception "
          . "($description)";
    }
  }
}

done_testing;
