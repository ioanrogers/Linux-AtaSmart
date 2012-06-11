package Linux::AtaSmart;

# ABSTRACT: XS wrapper around libatasmart

use v5.14;
use Moo;
use Carp;
use XSLoader;

XSLoader::load;

has _device      => (is => 'ro', required => 1,);
has _disk       => (is => 'rw', builder  => 1);
has _smart_data => (is => 'rw', default  => 0);

sub BUILDARGS {
    my ($class, @args) = @_;

    unshift @args, '_device' if @args % 2 == 1;

    return {@args};
}

sub DEMOLISH {
    _c_disk_free(shift->_disk);
}

sub _build__disk {
    my $self = shift;
    my $disk = _c_disk_open($self->_device);
    if (!$disk) {
        confess "Failed to open disk: $!";
    }

    return $disk;
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

    if (!$self->_smart_data) {
        $self->_read_data;
    }

    my $overall = _c_get_overall($self->_disk);
    if ($overall == -1) {
        confess "Failed to retrieve overall SMART status: $!";
    }
    return $overall;
}

sub get_power_cycle {
    my $self = shift;

    if (!$self->_smart_data) {
        $self->_read_data;
    }

    my $cycles = _c_get_power_cycle($self->_disk);
    if ($cycles == -1) {
        confess "Failed to retrieve number of power cycles: $!";
    }
    return $cycles;
}

sub get_power_on {
    my $self = shift;

    if (!$self->_smart_data) {
        $self->_read_data;
    }

    my $ms = _c_get_power_on($self->_disk);
    if ($ms == -1) {
        confess "Failed to retrieve powered-on time: $!";
    }
    require Time::Seconds;
    return Time::Seconds->new($ms / 1000);
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

    $self->_smart_data = 1;

}

1;

=for Pod::Coverage BUILDARGS DEMOLISH

=head1 SYNOPSIS

  use v5.14;
  use Linux::AtaSmart;
  use Linux::AtaSmart::Constants qw/:all/;
  
  my $atasmart = Linux::AtaSmart->new('/dev/sda');

  if (!$atasmart->smart_is_available) {
      die "Drive not SMART capable";
  }

  say 'Disk size in bytes: ', $atasmart->get_size;
  say 'Awake: ' .  ($atasmart->check_sleep_mode ? 'YES'  : 'NO');
  say 'Status: ' . ($atasmart->smart_status     ? 'GOOD' : 'BAD');
  say 'Bad Sectors: ' . $atasmart->get_bad;
  say 'Temperature °C: ' . $atasmart->get_temperature;
  say "Power Cycles: " . $atasmart->get_power_cycle;
  say "Powered On: " . $atasmart->get_power_on->pretty;
  
  my $status = $atasmart->get_overall;
  if ($status != OVERALL_GOOD) {
      say "STATUS NOT GOOD!";
  }
  
  # all of the above and more
  $atasmart->dump;
  
  $atasmart->self_test(TEST_SHORT);

=head1 DESCRIPTION

This is an XS wrapper around the Linux-only library, L<libatasmart|http://0pointer.de/blog/projects/being-smart.html>.
To read SMART info from a drive you will need to run as root, or have CAP_RAW_IO
(which you will most likely have to set on your F<perl> binary).
B<HAVING GROUP WRITE PERMISSIONS IS NOT ENOUGH!>

=head1 ALTERNATIVES

You may already have L<udisks|http://www.freedesktop.org/wiki/Software/udisks>
installed, which you can query via L<Net::DBus>.

=head1 INSTALLATION

On Debian-like systems, make sure you have C<libatasmart-dev> installed.

=head1 DIFFERENCES FROM THE C API

=over 

=item

I have removed the C<sk_disk_> and C<sk_disk_smart_> prefixes for brevity.

=item

The C<SkDisk> item is handled inside this module, you don't need to pass it to every method.
You should create a new object to examine a different disk.

=item

Results are returned directly by the methods, you don't have to pass references to be filled.

=item

You don't have to manually call C<sk_disk_smart_read_data> or C<sk_disk_smart_parse_data>.
This will be handled automatically by those methods that require it.

=back

=head1 ERRORS

All errors will throw exceptions via C<confess>

=head1 METHODS

=head2 C<new(disk_device)>

Creates a new C<Linux::AtaSmart> object. Requires one argument, a string, identifying
the disk to exmaine, e.g. F</dev/sda>, F</dev/disk/by-label/HOME> 

=head2 C<smart_is_available>

Boolean.

=head2 C<smart_status>

Boolean, true is GOOD, false is BAD.

=head2 C<check_sleep_mode>

Boolean, true if awake, false if sleeping. Reading SMART data will wake up the disk,
so check this first if you care.

=head2 C<dump>

Prints all the available SMART info for the disk to F<STDOUT>.

=head2 C<get_bad>

Returns the number of bad sectors on the disk.

=head2 C<get_overall>

Returns an integer corresponding to the overall status of the drive. See L<Linux::AtaSmart::Constants>.

=head2 C<get_power_cycle>

Returns number of times the disk has been power cycled.

=head2 C<get_power_on>

Returns the total time this disk has been powered-on as a L<Time::Seconds> object.
The C library actually uses milliseconds, complain if you'd prefer that.

=head2 C<get_size>

Returns the disk capacity in bytes.

=head2 C<get_temperature>

Returns current disk temperature in celsius. 
The C library actually uses millikelvins, complain if you'd prefer that.

=head2 C<self_test(TEST_TYPE)>

Starts a test of TEST_TYPE. See L<Linux::AtaSmart::Constants>.

=head1 SEE ALSO

=over 

=item 

L<libatasmart|http://0pointer.de/blog/projects/being-smart.html>

=item

L<Linux::AtaSmart::Constants>

=back
