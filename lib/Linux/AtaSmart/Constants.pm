package Linux::AtaSmart::Constants;
{
  $Linux::AtaSmart::Constants::VERSION = '1.0.4';
}

# ABSTRACT: Constants for libatasmart

use v5.10.1;
use strict;
use warnings;
use base 'Exporter';

# from SkSmartOverall
use constant {
    OVERALL_GOOD                      => 0,
    OVERALL_BAD_ATTRIBUTE_IN_THE_PAST => 1,
    OVERALL_BAD_SECTOR                => 2,
    OVERALL_BAD_ATTRIBUTE_NOW         => 3,
    OVERALL_BAD_SECTOR_MANY           => 4,
    OVERALL_BAD_STATUS                => 5,
};

# from SkSmartSelfTest
use constant {
    TEST_SHORT      => 1,
    TEST_EXTENDED   => 2,
    TEST_CONVEYANCE => 3,
    TEST_ABORT      => 127,
};

our %EXPORT_TAGS = (
    status => [
        qw/OVERALL_GOOD OVERALL_BAD_ATTRIBUTE_IN_THE_PAST OVERALL_BAD_SECTOR
          OVERALL_BAD_ATTRIBUTE_NOW OVERALL_BAD_SECTOR_MANY OVERALL_BAD_STATUS/
    ],
    tests => [qw/TEST_SHORT TEST_EXTENDED TEST_CONVEYANCE TEST_ABORT/],
);
my %seen;
push @{$EXPORT_TAGS{all}}, grep { !$seen{$_}++ } @{$EXPORT_TAGS{$_}}
  foreach keys %EXPORT_TAGS;

Exporter::export_ok_tags(qw/all status tests/);

1;

__END__

=pod

=encoding utf-8

=for :stopwords Ioan Rogers github

=head1 NAME

Linux::AtaSmart::Constants - Constants for libatasmart

=head1 VERSION

version 1.0.4

=head1 EXPORTS

=over

=item :status

Constants that correspond to the values returned by C<get_overall>

=item :tests

Constants for C<self_test>

=item :all

All of the above

=back

Check the source for the actual constant names.

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Ioan Rogers.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=cut
