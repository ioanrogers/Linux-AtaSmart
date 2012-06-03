package Linux::AtaSmart::Constants;

# ABSTRACT: Constants for libatasmart

use v5.14;
use strict;
use warnings;
use base 'Exporter';

# from SkSmartOverall
use constant {
	OVERALL_GOOD => 0,
    OVERALL_BAD_ATTRIBUTE_IN_THE_PAST => 1,
    OVERALL_BAD_SECTOR => 2,
    OVERALL_BAD_ATTRIBUTE_NOW => 3,
    OVERALL_BAD_SECTOR_MANY => 4,
    OVERALL_BAD_STATUS => 5,
};

# from SkSmartSelfTest
use constant {
	TEST_SHORT => 1,
    TEST_EXTENDED => 2,
    TEST_CONVEYANCE => 3,
    TEST_ABORT => 127,
}; 

our %EXPORT_TAGS = (
	status => [	qw/OVERALL_GOOD OVERALL_BAD_ATTRIBUTE_IN_THE_PAST OVERALL_BAD_SECTOR
				OVERALL_BAD_ATTRIBUTE_NOW OVERALL_BAD_SECTOR_MANY OVERALL_BAD_STATUS/],
	tests => [ qw/TEST_SHORT TEST_EXTENDED TEST_CONVEYANCE TEST_ABORT/],
);
my %seen;
push @{$EXPORT_TAGS{all}},
grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;

Exporter::export_ok_tags(qw/all status tests/);

1;
