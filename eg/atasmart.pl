#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Linux::AtaSmart;
use Linux::AtaSmart::Constants qw/:all/;
use Try::Tiny;
use Number::Format qw/format_bytes/;

my $disk_dev = shift || die "You must supply a disk, e.g /dev/sda";

say "Open [$disk_dev]";

my $atasmart;

try {
    $atasmart = Linux::AtaSmart->new(device => $disk_dev);
}
catch {
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

my $status = $atasmart->get_overall;

if ($status != OVERALL_GOOD) {
    say "STATUS NOT GOOD!";
}

say "Power Cycles: " . $atasmart->get_power_cycle;

say "Powered On: " . $atasmart->get_power_on->pretty;

#say "Start short test";
#$atasmart->self_test(TEST_SHORT);

#say "#### DUMP ####";
#$atasmart->dump;
#say "#### DUMP ####";
