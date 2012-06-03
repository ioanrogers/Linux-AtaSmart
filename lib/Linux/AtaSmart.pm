package Linux::AtaSmart;

# ABSTRACT: XS wrapper around libatasmart

use v5.14;
use Moo;
use File::Spec;
use Carp;
use Data::Printer;

my $typemap;

BEGIN {
    # find our typemap
    my $path = File::Spec->rel2abs(__FILE__);
    $path = (File::Spec->splitpath( $path ))[1];
    $typemap = File::Spec->catfile($path, 'AtaSmart', 'typemap');
}

use Inline (
    C            => DATA => LIBS => '-latasmart',
    AUTO_INCLUDE => '#include "atasmart.h"',
    TYPEMAPS     => $typemap,
);

has device      => (is => 'ro', required => 1,);
has _disk       => (is => 'rw', builder  => 1);
has _smart_data => (is => 'rw', default  => 0);

sub _build__disk {
    my $self = shift;
    my $disk = _c_disk_open($self->device);
    if (!$disk) {
        confess "Failed to open disk: $!";
    }
    $self->_disk($disk);
}

sub smart_is_available {
    my $self  = shift;
    my $avail = _c_smart_is_available($self->_disk);
    if ($avail == -1) {
        confess "Failed to query whether SMART is available: $!";
    }
    return $avail;
}

sub get_size {
    my $self  = shift;
    my $bytes = _c_get_size($self->_disk);
    if ($bytes == -1) {
        confess "Failed to retrieve disk size: $!";
    }
    return $bytes;
}

sub check_sleep_mode {
    my $self  = shift;
    my $awake = _c_check_sleep_mode($self->_disk);
    if ($awake == -1) {
        confess "Failed to check disk power status: $!";
    }
    return $awake;
}

sub dump {
    my $self = shift;
    _c_disk_dump($self->_disk);
}

sub smart_status {
    my $self = shift;
    my $good = _c_smart_status($self->_disk);
    if ($good == -1) {
        confess "Failed to query SMART status: $!";
    }
    return $good;
}

sub get_temperature {
    my $self = shift;

    if (!$self->_smart_data) {
        $self->_read_data;
    }

    my $mkelvin = _c_get_temperature($self->_disk);
    if ($mkelvin == -1) {
        confess "Failed to retrieve temperature: $!";
    }

    # millikelvin to celsius
    my $celsius = ($mkelvin - 273150) / 1000;
    return $celsius;
}

sub get_bad {
    my $self = shift;

    if (!$self->_smart_data) {
        $self->_read_data;
    }

    my $bad_sectors = _c_get_bad($self->_disk);
    if ($bad_sectors == -1) {
        confess "Failed to retrieve bad sector count: $!";
    }
    return $bad_sectors;
}

sub get_overall {
    my $self = shift;

    my $overall = _c_get_overall($self->_disk);
    if ($overall == -1) {
        confess "Failed to retrieve overall SMART status: $!";
    }
    return $overall;
}

sub get_power_cycle {
    my $self = shift;

    my $cycles = _c_get_power_cycle($self->_disk);
    if ($cycles == -1) {
        confess "Failed to retrieve number of power cycles: $!";
    }
    return $cycles;
}

sub get_power_on {
    my $self = shift;

    my $ms = _c_get_power_on($self->_disk);
    if ($ms == -1) {
        confess "Failed to retrieve powered-on time: $!";
    }
    require Time::Seconds;
    return Time::Seconds->new( $ms / 1000 ) ;
}

sub self_test {
    my ($self, $test_type) = @_;

    my $ret = _c_self_test($self->_disk, $test_type);
    if ($ret == -1) {
        confess "Failed to start $test_type self_test: $!";
    }
    return 1;
}

sub _read_data {
    my $self = shift;

    if (_c_read_data($self->_disk) < 0) {
        confess "Failed to read SMART data: $!";
    }

    if (_c_parse_data($self->_disk) < 0) {
        confess "Failed to parse SMART data: $!";
    }

    $self->_smart_data(1);

}

1;

__DATA__
 
__C__

SkDisk *_c_disk_open(const char *device) {
	SkDisk *disk;
	if ( sk_disk_open(device, &disk) == -1 ) {
		return 0;
	}
	
	return disk;
}

int _c_read_data(SkDisk *disk) {
	
	if (sk_disk_smart_read_data(disk) < 0) {
        return -1;
    }

    return 0;
}

int _c_parse_data(SkDisk *disk) {
	const SkSmartParsedData *parsed_data;
	if (sk_disk_smart_parse(disk, &parsed_data) < 0) {
        return -1;
    }

    return 0;
}

int _c_smart_is_available(SkDisk *disk) {
	SkBool available;
	if (sk_disk_smart_is_available(disk, &available) < 0) {
        return -1;
    }

    return available ? 1 : 0;
}

uint64_t _c_get_size(SkDisk *disk) {
	uint64_t bytes;	
	if (sk_disk_get_size(disk, &bytes) == 0) {
		return bytes;
	} else {
		return -1;
	}
}

int _c_check_sleep_mode(SkDisk *disk) {
	SkBool awake;
	if (sk_disk_check_sleep_mode(disk, &awake) < 0) {
        return -1;
    }

    return awake ? 1 : 0;
}

void _c_disk_dump(SkDisk *disk) {
	sk_disk_dump(disk);
}

int _c_smart_status(SkDisk *disk) {
	SkBool good;
	if (sk_disk_smart_status(disk, &good) < 0) {
        return -1;
    }

    return good ? 1 : 0;
}

uint64_t _c_get_temperature(SkDisk *disk) {
	uint64_t mkelvin;
	
	if (sk_disk_smart_get_temperature(disk, &mkelvin) == 0) {
		return mkelvin;
	} else {
		return (uint64_t) -1;
	}
}

uint64_t _c_get_bad(SkDisk *disk) {
	uint64_t sectors;
	
	if (sk_disk_smart_get_bad(disk, &sectors) == 0) {
		return sectors;
	} else {
		return (uint64_t) -1;
	}
}

SkSmartOverall _c_get_overall(SkDisk *disk) {
    SkSmartOverall *overall;
    if (sk_disk_smart_get_overall(disk, &overall) < 0) {
		return -1;
	}
	return overall;
}

uint64_t _c_get_power_cycle(SkDisk *disk) {
    uint64_t count;
    if (sk_disk_smart_get_power_cycle(disk, &count) < 0) {
		return (uint64_t) -1;
	}
	return count;
}

uint64_t _c_get_power_on(SkDisk *disk) {
    uint64_t ms;
    if (sk_disk_smart_get_power_on(disk, &ms) < 0) {
		return (uint64_t) -1;
	}
	return ms;
}

int _c_self_test(SkDisk *disk, SkSmartSelfTest test) {
	return sk_disk_smart_self_test(disk, test);
}

/*
const char* sk_smart_overall_to_string(SkSmartOverall overall);
int sk_disk_identify_is_available(SkDisk *d, SkBool *available);
int sk_disk_identify_parse(SkDisk *d, const SkIdentifyParsedData **data);
typedef void (*SkSmartAttributeParseCallback)(SkDisk *d, const SkSmartAttributeParsedData *a, void* userdata);
int sk_disk_get_blob(SkDisk *d, const void **blob, size_t *size);
int sk_disk_set_blob(SkDisk *d, const void *blob, size_t size);
int sk_disk_smart_parse_attributes(SkDisk *d, SkSmartAttributeParseCallback cb, void* userdata);
void sk_disk_free(SkDisk *d);
*/
