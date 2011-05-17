package Cpanel::SSHKeyManager;

use strict;
use warnings;
use Cpanel::SSH;

sub api2 {
    my $func = shift;
    my $API  = {
        fetchkey => {
            func   => 'api2_fetchkey',
            engine => 'hasharray',
        },
    };
    return ( \%{ $API->{$func} } );
}


sub api2_fetchkey {
    my @RSD = Cpanel::SSH::api2_fetchkey(@_);
    return unless $RSD[0]{key};
    return @RSD;
}

1;

__END__

=head1 NAME

Cpanel::SSHKeyManager - additional hooks for sshkeymanager

=head1 DESCRIPTION

This module used by sshkeymanager plugin.

=head1 METHODS

=head2 api2

This function specifies which API2 calls are mapped to which functions.
It is also responsible for returning a hash that contains information
on how the module works.

See cpanel dev docs: Writing cPanel Modules/Creating API2 Calls

=head2 api2_fetchkey

Small workaround for original SSH::fetchkey. Needed to support || operator.

=head1 AUTHOR

Vadim Dashkevich <dashkevich@uacoders.com>

Produced by Taras Mankovski <taras@positivesum.ca>

=head1 COPYRIGHT

HSTD SSH Key Manager. Copyright (C) 2010-2011 HSTD.org

=head1 LICENCE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
