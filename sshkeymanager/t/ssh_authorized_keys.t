#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/lib";
use Data::Dumper;

my $rsa_key =
"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsxypaPmJdW0ID3R/9HnXM7KF5v0xG/pXnXUfta6Ds/SfRJW2/FNtQU7aJ7qhJ3EoAj2F5RwKDupv5bpgqHhyDwmZBHo9MGcFra4V0FJaGr6Vu4N8NI043LFoh8NGrA6Q2inrCALDpvXJTqHfOiMddGnNe6AiJ73ABXcJr2QSiFwvL6pXutyhfh8aVpYtqd3J1yZsQ605N2SE4ZGKiz0o4PutWOi4DXXn1pXSrhTZOSMryuS5kg6YzEIu4VUZDqgTOXP/225UxLdVB5nKC0AsKHCga7DXOnX/hnDC1NlfdQ4RuDcuQvaLq7CQ0kl6e8XP+kY4oIFvJzdtPWuJ/a5ot user\@alpha\n";

my $dsa_key =
"ssh-dss AAAAB3NzaC1kc3MAAACBAPdM13yO+E5+min1Hj8B7jU7ZqbtBm0A+HIEDkgwfZw8/lUzLKysGgmgGzhu6GjbABc24K7DYqcSn0NAywNF9hdppO/+7snTrLcJJsT1Jxc7GBUEyJt88Zv3+n42iSiIYjBWavD3vBqlP4X5zL5k0M5LM8CZV+HuEAccyaPeclINAAAAFQCqOOAFvLrwalw6ZcdK6V8Bz6mrYQAAAIAt/+Ijb5aeZivyGv/cWzXx95Q7sKzUcmAejUDHf4rmgRUG9sSfzJezV7+j9o01L6iSjS9bYrvgyrihLfz8jn/YD8pHqzL5rVdt52B76+Px+RY9ABOT8+8yKrMPIKRqhF9c/fdwCEPEUiTDlKpSeoSvovV6vXvEJ3nTmZc8FYymDAAAAIEA8PctvEhR3TQ19zuQmNFSfHWZw76hviaww6k8+/H0ew5fCAIuxDhB5Tn4WA+seHEe+y+Gc5+mv9D2+mwb1TI9WprFT/8gjDvJMrtZRcfF1RPolaj8ieZjVo+arRITc82zUBVC+PBTiDhRoCkKB2RRRfE3vk5X1vtg35aee20FWWI= user\@beta\n";

use_ok('SSHAuthorizedKeys');

my $authkeys_file = Cpanel::SSHAuthorizedKeys::authkeys_file();
ok( $authkeys_file, 'path to authorized_keys' );

# testing api2 dispatcher
{
    my $API = {
        listkeys => {
            func   => 'api2_listkeys',
            engine => 'hasharray',
        },
        importkey => {
            func   => 'api2_importkey',
            engine => 'hasharray',
        },
        delkey => {
            func   => 'api2_delkey',
            engine => 'hasharray',
        },
    };

    foreach my $method ( keys %$API ) {
        my $result = Cpanel::SSHAuthorizedKeys::api2($method);
        is_deeply( $result, $API->{$method}, "dispatcher: $method" );
    }
}

# api2_importkey
{
    open my $fh, '>', $authkeys_file;
    truncate $fh, 0;
    close $fh;

    # We need to test this regex: s/^\s+|\s+$|\n//g
    # so let's add some garbage to keys
    my $garbage_key = " \n   \n  $rsa_key   \n\n";

    Cpanel::SSHAuthorizedKeys::api2_importkey( 'key', $garbage_key );
    Cpanel::SSHAuthorizedKeys::api2_importkey( 'key', $dsa_key );

    open $fh, '<', $authkeys_file;
    my $got = join '', <$fh>;
    close $fh;

    my $expected = $rsa_key . $dsa_key;
    ok( $got eq $expected, 'importkey' );
}

# api2_listkeys
{
    my @expected;
    foreach my $key ( $rsa_key, $dsa_key ) {
        my @parts = split /\s/, $key;
        push @expected, { type => $parts[0], key => $parts[1], user => $parts[2] };
    }
    my @got = Cpanel::SSHAuthorizedKeys::api2_listkeys();
    is_deeply( \@got, \@expected, 'listkeys' );
}

# api2_delkey
{
    Cpanel::SSHAuthorizedKeys::api2_delkey( 'user', 'user@alpha' );

    open my $fh, '<', $authkeys_file;
    my $got = join '', <$fh>;
    close $fh;

    ok( $got eq $dsa_key, 'delkey' );
}

done_testing;
