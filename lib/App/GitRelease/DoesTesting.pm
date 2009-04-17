package App::GitRelease::DoesTesting;
use Moose::Role;
use App::Prove;

has 'disable_tests' => (
    isa        => 'Bool',
    is         => 'ro',
    lazy_build => 1,
);
sub _build_disable_tests { `git config release.disable_tests` || 0 }

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

no Moose::Role;
1;
__END__
