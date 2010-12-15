#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);

if ( $< != 0 ) {
    print "This script must be run as root.";
    exit;
}

my $CPANEL = "/usr/local/cpanel";

`cp -r $Bin/sshkeymanager $CPANEL/base/frontend/x3`;
`cp $Bin/sshkeymanager.cpanelplugin $CPANEL/bin`;
`cp $Bin/lib/* $CPANEL/Cpanel`;
`$CPANEL/bin/register_cpanelplugin $CPANEL/bin/sshkeymanager.cpanelplugin`;
