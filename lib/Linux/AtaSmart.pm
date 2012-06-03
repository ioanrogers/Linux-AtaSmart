package Linux::AtaSmart;

# ABSTRACT: XS wrapper around libatasmart

use v5.14;
use Moo;
use Carp;
use XSLoader;

XSLoader::load;

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
