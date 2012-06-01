#!/usr/bin/env perl

use Modern::Perl '2012';
use Linux::AtaSmart;
use Try::Tiny;
use Number::Format qw/format_bytes/;

my $disk_dev = shift || die "You must supply a disk, e.g /dev/sda";

say "Open [$disk_dev]";

my $atasmart;

try {
    $atasmart = Linux::AtaSmart->new(device => $disk_dev);
} catch {
    say "BOOM: $_";
    exit;
};

if ($atasmart->smart_is_available) {
    say "SMART capable";
}

my $bytes = $atasmart->get_size;
say 'Size: ' . format_bytes($bytes);

say 'Awake: ' .  ($atasmart->check_sleep_mode ? 'YES'  : 'NO');
say 'Status: ' . ($atasmart->smart_status     ? 'GOOD' : 'BAD');

say "Bad Sectors: " . $atasmart->get_bad;

say "Temperature °C: " . $atasmart->get_temperature;

say "#### DUMP ####";
$atasmart->dump;
say "#### DUMP ####";

