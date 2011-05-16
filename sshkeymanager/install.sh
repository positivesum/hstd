#!/bin/bash

# HSTD SSH Key Manager
# Copyright (C) 2010-2011 HSTD.org
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

if [ `whoami` != 'root' ]; then
    echo "This script must be run as root."; exit 0
fi

CPANEL=/usr/local/cpanel

cp -r ./sshkeymanager $CPANEL/base/frontend/x3
cp ./lib/* $CPANEL/Cpanel
cp ./sshkeymanager.cpanelplugin $CPANEL/bin
$CPANEL/bin/register_cpanelplugin $CPANEL/bin/sshkeymanager.cpanelplugin
