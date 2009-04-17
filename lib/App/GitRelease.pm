package App::GitRelease;
use Moose;

use Carp qw(cluck);
use App::Prove;
use URI;

with qw(MooseX::Getopt);

has [qw(disable_update disable_tests disable_push)] => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_disable_update { `git config release.disable_update` || 0 }
sub _build_disable_tests  { `git config release.disable_tests`  || 0 }
sub _build_disable_push   { `git config release.disable_push`   || 0 }

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
        print STDERR "Attempting push to $target\n";
        $self->_push_to_ssh_target( URI->new($target) );
    }
    else { cluck "Invalid distribution target $target"; }
}

sub push_to_production {
    $_[0]->push_to_target($_) for ( @{ $_[0]->release_list } );
}

sub run_update {
    warn 'updating local repo';
    system( 'git', 'pull' );
}

sub run {
    my ($self) = @_;
    $self->run_update         unless $self->disable_update;
    $self->run_tests          unless $self->disable_tests;
    $self->push_to_production unless $self->disable_push;
}

no Moose;
1;
