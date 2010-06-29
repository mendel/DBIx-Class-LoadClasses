#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most;

BEGIN {
  require_ok( 'DBIx::Class::LoadClasses' );
}

diag( "Testing DBIx::Class::LoadClasses $DBIx::Class::LoadClasses::VERSION, Perl $], $^X" );

done_testing;
