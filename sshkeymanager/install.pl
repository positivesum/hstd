#!/usr/bin/env perl

# HSTD SSH Key Manager
# Copyright (C) 2010 HSTD.org
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

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
