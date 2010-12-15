package Cpanel::SSHKeyManager;

use strict;
use warnings;
use Cpanel::SSH;

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

=cut

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

=head2 api2_fetchkey

Small workaround for original SSH::api2_fetchkey. Needed to support || operator.

=cut

sub api2_fetchkey {
    my @RSD = Cpanel::SSH::api2_fetchkey(@_);
    return if not defined $RSD[0]{key};
    return @RSD;
}

=head1 AUTHOR

Vadim Dashkevich <dashkevich@uacoders.com>, Positive Sum 2010

=head1 LICENCE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
