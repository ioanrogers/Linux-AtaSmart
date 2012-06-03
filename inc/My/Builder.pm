package My::Builder;

use v5.14;
use strict;
use warnings;
use base 'Module::Build';
use lib "inc";

use Data::Printer;

sub new {
    my ($class, %args) = @_;
    
    $args{extra_linker_flags} = '-latasmart';
    #my $self = bless {@_}, $class;
    
    my $builder = Module::Build->new(%args);
    p $builder;
    return $builder;
}

1;
