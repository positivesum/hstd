#!/usr/bin/env perl

use strict;
use warnings;

if ( $< != 0 ) {
    print "This script must be run as root.";
    exit;
}

my $CPANEL = "/usr/local/cpanel";

`cp -r sshkeymanager $CPANEL/base/frontend/x3`;
`cp sshkeymanager.cpanelplugin $CPANEL/bin`;
`$CPANEL/bin/register_cpanelplugin $CPANEL/bin/sshkeymanager.cpanelplugin`;
