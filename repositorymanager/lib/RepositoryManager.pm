package Cpanel::RepositoryManager;

use strict;
use warnings;
use File::Path;

=head1 NAME

Cpanel::RepositoryManager - manage git/hg repositories

=head1 DESCRIPTION

Manage git/hg repositories, clone remote repo, checkout, view log etc.

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
        repo_list => {
            func   => 'api2_repo_list',
            engine => 'hasharray',
        },
        recent_log => {
            func   => 'api2_recent_log',
            engine => 'hasharray',
        },
        init => {
            func   => 'api2_init',
            engine => 'hasharray',
        },
        clone_remote => {
            func   => 'api2_clone_remote',
            engine => 'hasharray',
        },
        clone_local => {
            func   => 'api2_clone_local',
            engine => 'hasharray',
        },
        taglist => {
            func   => 'api2_taglist',
            engine => 'hasharray'
        },
        branchlist => {
            func   => 'api2_branchlist',
            engine => 'hasharray',
        },
        getstate => {
            func   => 'api2_getstate',
            engine => 'hasharray',
        },
        checkout => {
            func   => 'api2_checkout',
            engine => 'hasharray',
        },
        checkout_list => {
            func   => 'api2_checkout_list',
            engine => 'hasharray',
        }
    };
    return ( \%{ $API->{$func} } );
}

=head2 api2_repo_list

List existing repositories

Returns:

    <data>
        <repo_name>Repository name</repo_name>
        <repo_type>Repository type</repo_type>
    </data>

=cut

sub api2_repo_list {
    return repo_list();
}

=head2 repo_list

Return hasharr { name, type } for all existing repositories.

=cut

sub repo_list {
    opendir my $dh, repo_path();
    my @repos = grep { !/^\./ } readdir $dh;
    closedir $dh;
    return if not @repos;

    my @repo_list;
    foreach my $repo_name (@repos) {
        my $repo_type;
        my $repo_path = repo_path($repo_name);
        $repo_type = 'git' if -d $repo_path . "/.git";    # ugly. change this
        $repo_type = 'hg'  if -d $repo_path . "/.hg";
        push @repo_list, { repo_name => $repo_name, repo_type => $repo_type };
    }
    return @repo_list;
}

=head2 api2_recent_log

Return last 20 log entries for all repos sorted by commit timestamp

Returns:

    <data>
        <repo_name>Repository name</repo_name>
        <abb_hash>Abbreviated commit hash</abb_hash>
        <timestamp>Commit timestamp</timestamp>
        <subject>Commit subject</subject>
    </data>

=cut

sub api2_recent_log {
    my @RSD;
    foreach my $repo ( repo_list() ) {
        push @RSD, git_log( $repo->{repo_name} ) if $repo->{repo_type} eq 'git';
        push @RSD, hg_log( $repo->{repo_name} )  if $repo->{repo_type} eq 'hg';
    }
    @RSD = sort { $b->{timestamp} <=> $a->{timestamp} } @RSD;
    return @RSD[ 0 .. 19 ];    # limit output to 20 records in total
}

=head2 git_log

Get Git log and prepare desired output

=cut

sub git_log {
    my $repo_name = shift;
    my $repo_path = repo_path($repo_name);
    return if not -d "$repo_path/.git/logs";
    return map {
        /^'?(\S{7}) (\d{10}) (.*)'?$/;
        {
            repo_name => $repo_name,
            abb_hash  => $1,
            timestamp => $2,
            subject   => $3,
        };
    } `git --git-dir=$repo_path/.git log -n 20 --pretty=format:'%h %ct %s'`;
}

=head2 hg_log

Get Hg log

=cut

sub hg_log {
    my $repo_name = shift;
    my $repo_path = repo_path($repo_name);
    return map {
        /^(\S{12}) (\d{10}) \d+ (.*)$/;
        {
            repo_name => $repo_name,
            abb_hash  => $1,
            timestamp => $2,
            subject   => $3,
        }
    } `hg log -l 20 --template '{node|short} {date|hgdate} {desc}\n' --cwd $repo_path`;
}

=head2 api2_init

Init empty repository

Parameters:

    repo_type (string) - repository type (git/hg)
    repo_name (string) - repository name

Returns:

    <data>
        <output>Command output</output>
    </data>

=cut

sub api2_init {
    my %OPTS      = @_;
    my $repo_path = repo_path( $OPTS{'repo_name'} );
    my $output;
    if ( $OPTS{'repo_type'} eq 'git' ) {
        $output = `git init $repo_path 2>&1`;
    }
    elsif ( $OPTS{'repo_type'} eq 'hg' ) {
        $output = `hg init $repo_path 2>&1`;

        # hg does not output anything if init successful
        $output = "Initialized empty Hg repository in $repo_path" if not $output;
    }
    return { output => $output };
}

=head2 api2_clone_remote

Clone remote repository

For some reason only first line of output captured. Check this later.

Example output:

    Cloning into fsck...
    remote: Counting objects: 134, done.
    remote: Compressing objects: 100% (117/117), done.
    remote: Total 134 (delta 51), reused 0 (delta 0)
    Receiving objects: 100% (134/134), 14.38 KiB, done.
    Resolving deltas: 100% (51/51), done.


Params:

    repo_url (string) - repository url
    repo_type (string) - repository type

Returns:

    <data>
        <output>Command output</output>
    </data>

=cut

sub api2_clone_remote {
    my %OPTS = @_;
    my $output;
    my @parts = split /\//, $OPTS{'repo_url'};
    if ( $OPTS{'repo_type'} eq 'git' ) {
        $parts[-1] =~ s/\.git$//;
        my $repo_path = repo_path( $parts[-1] );
        $output = `git clone $OPTS{'repo_url'} $repo_path 2>&1`;
    }
    elsif ( $OPTS{'repo_type'} eq 'hg' ) {
        my $repo_path = repo_path( $parts[-1] );
        $output = `hg clone $OPTS{'repo_url'} $repo_path 2>&1`;
    }
    return { output => $output };
}

=head2 repo_path

Return full path to repository

=cut

sub repo_path {
    return $Cpanel::homedir . "/repos/" . shift;
}

=head2 repo_type

Return repository type

=cut

sub repo_type {
    my $repo_path = repo_path(shift);
    return "git" if -d $repo_path . "/.git" or is_gitbare($repo_path);
    return "hg"  if -d $repo_path . "/.hg";
}

=head2 is_gitbare

Check if repo is git bare

=cut

sub is_gitbare {
    my $repo_path = shift;
    open my $fh, "<$repo_path/config" or return;
    my $res = grep { /bare = true/ } <$fh>;
    close $fh;
    return $res;
}

=head2 api2_clone_local

Clone local repository into ~/sites/cloned_repo

Params:

    repo_name (string) - repository name
    clone_dir (string) - cloned repository path

Returns:

    <data>
        <output>Command output</output>
    </data>

=cut

sub api2_clone_local {
    my %OPTS      = @_;
    my $repo_path = repo_path( $OPTS{'repo_name'} );
    my $clone_dir = repo_path( $OPTS{'clone_dir'} );
    my $repo_type = repo_type( $OPTS{'repo_name'} );
    my $output;
    $output = `git clone $repo_path $clone_dir 2>&1` if $repo_type eq 'git';
    $output = `hg clone $repo_path $clone_dir 2>&1`  if $repo_type eq 'hg';
    return { output => $output };
}

=head2 api2_taglist

List available tags

Parameters:

    repo_name (string) - repository name

Returns:

    <data>
        <tag>Tag</tag>
    </data>

=cut

sub api2_taglist {
    my %OPTS      = @_;
    my $repo_path = repo_path( $OPTS{'repo_name'} );
    my $repo_type = repo_type( $OPTS{'repo_name'} );
    return map { chomp; { tag => $_ } } `git --git-dir=$repo_path/.git tag` if $repo_type eq 'git';
    return map { chomp; s/ .*//; { tag => $_ } } `hg --cwd $repo_path tags` if $repo_type eq 'hg';
}

=head2 api2_branchlist

List repository branches

Parameters:

    repo_name (string) - repository name

Returns:

    <data>
        <branch>Branch</branch>
    </data>

=cut

sub api2_branchlist {
    my %OPTS      = @_;
    my $repo_path = repo_path( $OPTS{'repo_name'} );
    my $repo_type = repo_type( $OPTS{'repo_name'} );
    return map { chomp; s/^..//; { branch => $_ } } `git --git-dir=$repo_path/.git branch` if $repo_type eq 'git';
    return map { chomp; s/ .*//; { branch => $_ } } `hg --cwd $repo_path branches`         if $repo_type eq 'hg';
}

=head2 api2_checkout

Checkout repository to specific tag,branch or revision

Parameters:

    repo_name (string) - repository name
    want (string) - what to checkout (tag/branch/commit)

Returns:

    <data>
        <output>Command output</output>
    </data>

=cut

sub api2_checkout {
    my %OPTS      = @_;
    my $repo_type = repo_type( $OPTS{'repo_name'} );
    my $repo_path = repo_path( $OPTS{'repo_name'} );

    open my $fh, ">$repo_path/.checkout";
    $OPTS{'want'} = substr $OPTS{'want'}, 0, 7 if $OPTS{'checkout_type'} eq 'commit';
    print $fh "[checkout]\ntype=$OPTS{'checkout_type'}\nname=$OPTS{'want'}";
    close $fh;

    my $output;
    $output = `git --work-tree=$repo_path --git-dir=$repo_path/.git checkout $OPTS{'want'} 2>&1` if $repo_type eq 'git';
    $output = `hg --cwd $repo_path checkout $OPTS{'want'} 2>&1` if $repo_type eq 'hg';
    return { output => $output };
}

=head2 api2_checkout_list

List checkouted repositories

Returns:

    <data>
        <cloned_from>Repo origin</cloned_from>
        <repo_name>Cloned repository name</repo_name>
        <checkout_name>Tag,branch or commit</checkout_name>
    </data>

=cut

sub api2_checkout_list {
    my %OPTS = @_;
    my @RSD;

    # read ~/sites
    opendir my $dh, repo_path("../sites");
    my @repos = grep { !/^\./ } readdir $dh;
    closedir $dh;
    return if not @repos;

    foreach my $repo_name (@repos) {

        # use Config::Any for this
        my $repo_path = repo_path("../sites/$repo_name");
        open my $fh, "<$repo_path/.checkout";
        my ($checkout_name) = grep { /name=/ } <$fh>;
        map { s/.*=// } ($checkout_name);
        close $fh;

        my $repo_type = repo_type("../sites/$repo_name");

        # [git] will not work if parent repository was moved/deleted. add some magic later
        `git --git-dir=$repo_path/.git remote show origin 2>&1` =~ /Fetch URL: .*\b\/(.*)/ if $repo_type eq 'git';
        `hg --cwd $repo_path paths 2>&1`                        =~ /= .*\b\/(.*)/          if $repo_type eq 'hg';
        push @RSD, { cloned_from => $1, repo_name => $repo_name, checkout_name => $checkout_name };

    }
    return @RSD;
}

=head1 AUTHOR

Vadim Dashkevich <dashkevich@uacoders.com>

Produced by Taras Mankovski <taras@positivesum.ca>

=head1 COPYRIGHT

HSTD Repository Manager. Copyright (C) 2010 HSTD.org

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

1;
