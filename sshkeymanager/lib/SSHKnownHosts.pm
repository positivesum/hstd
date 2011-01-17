package Cpanel::SSHKnownHosts;

use strict;
use warnings;

sub api2 {
    my $func = shift;
    my $API  = {
        is_known => {
            func   => 'api2_is_known',
            engine => 'hasharray',
        },
        add_host => {
            func   => 'api2_add_host',
            engine => 'hasharray',
        }
    };
    return ( \%{ $API->{$func} } );
}

sub api2_is_known {
    my %OPTS = @_;
    my ($output) = grep { !/^#/ } `ssh-keygen -H -F $OPTS{'host'}`;
    my $is_known = ( ($output) ? 1 : 0 );
    return { is_known => $is_known };
}

sub api2_add_host {
    my %OPTS = @_;
    my ($key) = grep { !/^#/ } `ssh-keyscan -t $OPTS{'type'} $OPTS{'host'}`;
    open my $fh, ">>$Cpanel::homedir/.ssh/known_hosts";
    print $fh $key;
    close $fh;
}

1;
