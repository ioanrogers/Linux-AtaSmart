use lib 'inc';
use Devel::AssertOS qw[Linux];

use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use My::Builder;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
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
  "dist_version" => "1.0.5",
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
  "script_files" => [],
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = My::Builder->new(%module_build_args);

$build->create_build_script;
