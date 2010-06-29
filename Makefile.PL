#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::AuthorRequires 0.02;
use Module::Install::ReadmeFromPod 0.06;
use Module::Install::Repository 0.06;
use Module::Install::ExtraTests 0.006;

name          'DBIx-Class-LoadClasses';
all_from      'lib/DBIx/Class/LoadClasses.pm';
readme_from   'lib/DBIx/Class/LoadClasses.pm' => 'clean';
auto_set_repository;

requires 'DBIx::Class'                => '0.08123';

test_requires 'Test::Most'            => '0.21';
test_requires 'Test::More'            => '0.92';
test_requires 'Test::Deep'            => '0.103';
test_requires 'FindBin'               => 0;
test_requires 'Path::Class'           => '0.16';
test_requires 'Class::MOP'            => '1.02';
test_requires 'Data::Dumper'          => 0;

author_requires 'Test::Pod'           => '1.22';
author_requires 'Test::Pod::Coverage' => '1.08';
author_requires 'Pod::Coverage'       => '0.18';
author_requires 'Test::Perl::Critic'  => '1.01';

extra_tests;

auto_install;

WriteAll;
