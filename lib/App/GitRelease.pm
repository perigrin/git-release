package App::GitRelease;
use Moose;
our $VERSION = '0.01';

with qw(
    MooseX::Getopt
    App::GitRelease::DoesTesting
    App::GitRelease::DoesLocalUpdate
    App::GitRelease::DoesBootstrap
    App::GitRelease::DoesProductionUpdate
);

has release_list => (
    isa        => 'ArrayRef',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_release_list { [ split /\n/, `git config --get-all release.url` ] }

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
