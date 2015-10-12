package Linux::AtaSmart;

# ABSTRACT: XS wrapper around libatasmart

use v5.10.1;
use Moo;
use Carp;
use XSLoader;
use namespace::clean;

XSLoader::load;

has _device => (is => 'ro', required => 1,);

has _smart_data => (is => 'rwp', predicate => 1);

sub BUILD {
    __disk_open($_[0]->_device);
    __smart_is_available();
    return;
}

sub BUILDARGS {
    my ($class, @args) = @_;

    unshift @args, '_device' if @args % 2 == 1;

    return {@args};
}

before [
    qw/get_temperature get_bad get_overall get_power_cycle get_power_on/] =>
  sub {
    my $self = shift;
    unless ($self->_has_smart_data) {
        __get_smart_data();
        $self->_set__smart_data(1);
    }
  };

sub get_power_on {
    my $self = shift;

    my $ms = __get_power_on();

    return if $ms == 0;

    require Time::Seconds;
    return Time::Seconds->new($ms / 1000);
}

1;

=for Pod::Coverage BUILDARGS DEMOLISH

=head1 SYNOPSIS

  use v5.10.1;
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
  say 'Temperature °C: ' . $atasmart->get_temperature // "n/a";
  say "Power Cycles: " . $atasmart->get_power_cycle // "n/a";
  say "Powered On: " . $atasmart->get_power_on->pretty // "n/a";

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

=method C<new(disk_device)>

Creates a new C<Linux::AtaSmart> object. Requires one argument, a string identifying
the disk to examine, e.g. F</dev/sda>, F</dev/disk/by-label/HOME>

Will C<croak> if there is any error, or the device does not support SMART.

=method C<get_size>

Returns the disk capacity in bytes.

=method C<check_sleep_mode>

Boolean, true if awake, false if sleeping. Reading SMART data will wake up the disk,
so check this first if you care.

=method C<dump>

Prints all the available SMART info for the disk to F<STDOUT>.

=method C<smart_status>

Boolean, true is GOOD, false is BAD.

=method C<get_temperature>

Returns current disk temperature in celsius, or C<undef> if not supported.

The C library actually uses millikelvins, complain if you'd prefer that.

=method C<get_bad>

Returns the number of bad sectors on the disk.

=method C<get_overall>

Returns an integer corresponding to the overall status of the drive.
See L<Linux::AtaSmart::Constants>.

=method C<get_power_cycle>

Returns number of times the disk has been power cycled.

=method C<get_power_on>

Returns the total time this disk has been powered-on as a L<Time::Seconds> object.
The C library actually uses milliseconds, complain if you'd prefer that.

=method C<self_test(TEST_TYPE)>

Starts a test of TEST_TYPE. See L<Linux::AtaSmart::Constants>.

=head1 ALTERNATIVES

You may already have L<udisks|http://www.freedesktop.org/wiki/Software/udisks>
installed, which you can query via L<Net::DBus>.

=head1 INSTALLATION

You will need your system's C<libatasmart> development package installed.
On Debian-like systems, this is C<libatasmart-dev>. On Fedora it is
C<libatasmart-devel>.

=head1 DIFFERENCES FROM THE C API

=over

=item

Removed the C<sk_disk_> and C<sk_disk_smart_> prefixes for brevity.

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

All errors will throw exceptions via C<croak>

=head1 SEE ALSO

=over

=item

L<libatasmart|http://0pointer.de/blog/projects/being-smart.html>

=item

L<Linux::AtaSmart::Constants>

=back
