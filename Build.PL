use lib 'inc';
use Devel::AssertOS qw[Linux];

use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use My::Builder;

my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::PkgConfig" => 0,
    "Module::Build" => "0.3601",
    "Try::Tiny" => 0
  },
  "dist_abstract" => "XS wrapper around libatasmart",
  "dist_author" => [
    "Ioan Rogers <ioanr\@cpan.org>"
  ],
  "dist_name" => "Linux-AtaSmart",
  "dist_version" => "1.0.4",
  "license" => "lgpl",
  "module_name" => "Linux::AtaSmart",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exporter" => 0,
    "Moo" => 0,
    "Time::Seconds" => 0,
    "XSLoader" => 0,
    "base" => 0,
    "constant" => 0,
    "perl" => "v5.10.1",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = My::Builder->new(%module_build_args);

$build->create_build_script;
