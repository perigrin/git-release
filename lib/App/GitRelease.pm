package App::GitRelease;
use Moose;
our $VERSION = '0.01';

use Carp qw(cluck);
use App::Prove;
use Net::SSH::Expect;

with qw(MooseX::Getopt);

has [qw(bootstrap disable_update disable_tests disable_push)] => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);
sub _build_bootstrap      {0}
sub _build_disable_update { `git config release.disable_update` || 0 }
sub _build_disable_tests  { `git config release.disable_tests` || 0 }
sub _build_disable_push   { `git config release.disable_push` || 0 }

has release_list => (
    isa        => 'ArrayRef',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_release_list { [ split /\n/, `git config --get-all release.url` ] }

has prove => (
    isa        => 'App::Prove',
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        run_tests => 'run',
    }
);

before 'run_tests' => sub { print STDERR "Running tests\n\n" };

sub _build_prove {
    my $self = shift;
    my $p    = App::Prove->new();
    $p->process_args( @{ $self->extra_argv } );
    return $p;
}

sub _get_ssh {
    my ( $self, $uri ) = @_;

    my $ssh = Net::SSH::Expect->new(
        host    => $uri->{host},
        user    => $uri->{user},
        raw_pty => 1
    );

    $ssh->run_ssh();
    print $ssh->read_all(2);
    $ssh->exec("stty raw -echo");
    return $ssh;
}

sub _push_to_ssh_target {
    my ( $self, $uri ) = @_;
    my $ssh = $self->_get_ssh($uri);
    print STDERR $ssh->exec("cd $uri->{path}");
    $ssh->send('git pull');
    while ( defined( my $line = $ssh->read_line() ) ) {
        print $line . "\n";
    }

    $ssh->close();
}

sub push_to_target {
    my ( $self, $target ) = @_;
    if ( $target =~ m|^ssh://([^@]+)@([^/]+)/(.*)$| ) {
        my $uri = { user => $1, host => $2, path => $3, };
        print STDERR "Attempting push to $target\n";
        $self->_push_to_ssh_target($uri);
    }
    else { cluck "Invalid target: $target"; }
}

sub push_to_production {
    $_[0]->push_to_target($_) for @{ $_[0]->release_list };
    print STDERR "Production updated\n";
}

has remote_origin_url => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_remote_origin_url {
    chomp( my $url = `git config remote.origin.url` );
    confess 'No remote.origin.url you will need to supply one' unless $url;
    return $url;
}

sub _bootstrap_ssh_target {
    my ( $self, $uri ) = @_;
    my $ssh = $self->_get_ssh($uri);
    $ssh->send("git clone ${\$self->remote_origin_url} $uri->{path}");
    while ( my $chunk = $ssh->peek(2) )
    {    # grabs chunks of output each 1 second
        print $ssh->eat($chunk);
    }

    $ssh->close();
}

sub boostrap_target {
    my ( $self, $target ) = @_;
    if ( $target =~ m|^ssh://([^@]+)@([^/]+)/(.*)$| ) {
        my $uri = { user => $1, host => $2, path => $3, };
        print STDERR "Attempting push to $target\n";
        $self->_bootstrap_ssh_target($uri);
    }
    else { cluck "Invalid target: $target"; }

}

sub bootstrap_production {
    $_[0]->boostrap_target($_) for @{ $_[0]->release_list };
    print STDERR "Production ready\n";
}

sub run_update {
    warn 'updating local repo';
    system( 'git', 'pull' );
}

sub run {
    my ($self) = @_;
    $self->run_update unless $self->disable_update;
    $self->run_tests  unless $self->disable_tests;
    if ( $self->bootstrap ) {
        $self->bootstrap_production;
    }
    else {
        $self->push_to_production unless $self->disable_push;
    }
}

no Moose;
1;
__END__

=head1 NAME

App::GitRelease - manage releasing a git repository to a cluster servers

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use lib qw(lib);
    use App::GitRelease;

    App::GitRelease->new_with_options()->run;

=head1 DESCRIPTION

The App::GitRelease class implements ...

=head1 SUBROUTINES / METHODS

=head2 push_to_target (method)

Parameters:
    target

Insert description of method here...

=head2 push_to_production (method)

Parameters:
    none

Arguments:
    none

Insert description of method here...

=head2 run_update

Parameters:
    none

Insert description of subroutine here...

=head2 run (method)

Parameters:
    none

Main method, run this to run the main application.

=head1 DEPENDENCIES

Moose

App::Prove

Net::SSH::Expect

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
