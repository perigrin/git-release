package App::GitRelease;
use Moose;

use Carp qw(cluck);
use App::Prove;
use URI;

with qw(MooseX::Getopt);

has [qw(update_repo enable_tests)] => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_update_repo {
    my $val = `git config release.update_repo`;
    return $val if defined $val;
    return 1;
}

sub _build_enable_tests {
    my $val = `git config release.enable_tests`;
    return $val if defined $val;
    return 1;
}

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

sub _build_prove {
    my $self = shift;
    my $p = App::Prove->new();
    $p->process_args( @{ $self->extra_argv } );
}

sub _get_ssh {
    my ( $self, $uri ) = @_;
    my $ssh = Net::SSH::Expect->new(
        host    => $uri->host,
        user    => $uri->user,
        raw_pty => 1
    );

    $ssh->run_ssh() or confess "SSH process couldn't start: $!";
    ( $ssh->read_all(2) =~ />\s*\z/ ) or confess "no remote prompt";
    return $ssh;
}

sub _push_to_ssh_target {
    my ( $self, $uri ) = @_;
    my $ssh = $self->_get_ssh($uri);
    $ssh->exec("cd ${\$uri->path}");
    $ssh->exec('git pull');
    $ssh->close();
}

sub push_to_target {
    my ( $self, $target ) = @_;
    if ( $target =~ m|^ssh://| ) {    # we're dealing with local filesystem
        $self->_push_to_ssh_target( URI->new($target) );
    }
    else { cluck "Invalid distribution target $target"; }
}

sub push_to_production {
    $_[0]->push_to_target($_) for ( @{ $_[0]->release_list } );
}

sub run {
    my ($self) = @_;
    $self->update    if $self->update_repo;
    $self->run_tests if $self->enable_tests;
    $self->push_to_production;
}

no Moose;
1;
