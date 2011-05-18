package Cpanel::PwCache;

use strict;
use warnings;
use FindBin qw($Bin);

sub gethomedir {
    return "$Bin/data";
}

1;
