package Webservice::Rosary::Stream;

use v5.10;
use strict;
use warnings;

use Time::HiRes qw/sleep/;

our $VERSION = "0.1.6";

sub new {
  my $class = shift;
  my %opts = @_;

  my $self = bless {
    delay       => defined $opts{delay} ? 0 + $opts{delay} : 0.04,
    speed       => defined $opts{speed} ? 0 + $opts{speed} : 1,
    base_speed  => defined $opts{speed} ? 0 + $opts{speed} : 1,
    min_speed   => defined $opts{min_speed} ? 0 + $opts{min_speed} : 0.25,
    max_speed   => defined $opts{max_speed} ? 0 + $opts{max_speed} : 8,
    speed_step  => defined $opts{speed_step} ? 0 + $opts{speed_step} : 1.25,
    controls    => exists $opts{controls} ? $opts{controls} : 1,
    paused      => 0,
    read_key    => $opts{read_key},
    sleep_cb    => $opts{sleep_cb} || sub { sleep $_[0] },
    write_cb    => $opts{write_cb} || sub { print STDOUT $_[0] },
    terminal_active => 0,
    owns_reader     => 0,
  }, $class;

  die "stream delay must be zero or greater\n" if $self->{delay} < 0;
  die "stream speed must be greater than zero\n" if $self->{speed} <= 0;
  die "minimum stream speed must be greater than zero\n" if $self->{min_speed} <= 0;
  die "maximum stream speed must be at least minimum stream speed\n"
    if $self->{max_speed} < $self->{min_speed};
  die "stream speed step must be greater than one\n" if $self->{speed_step} <= 1;

  if ($self->{read_key}) {
    $self->{terminal_active} = $self->{controls} ? 1 : 0;
  }
  else {
    $self->_enable_terminal_controls;
  }

  return $self;
}

sub delay       { return $_[0]->{delay}; }
sub speed       { return $_[0]->{speed}; }
sub paused      { return $_[0]->{paused}; }
sub interactive { return $_[0]->{controls} && $_[0]->{terminal_active}; }

sub controls_help {
  return q{SPACE/p pause/resume, +/- speed, 0 reset};
}

sub _enable_terminal_controls {
  my $self = shift;
  return 0 if not $self->{controls};
  return 0 if $self->{read_key};
  return 0 if not -t STDIN or not -t STDOUT;

  my $ok = eval {
    require Term::ReadKey;
    Term::ReadKey::ReadMode(q{cbreak});
    1;
  };
  return 0 if not $ok;

  $self->{read_key} = sub { return Term::ReadKey::ReadKey(-1); };
  $self->{terminal_active} = 1;
  $self->{owns_reader} = 1;
  return 1;
}

sub restore_terminal {
  my $self = shift;
  if ($self->{owns_reader} and $self->{terminal_active}) {
    eval { Term::ReadKey::ReadMode(q{restore}); 1 };
    $self->{terminal_active} = 0;
    $self->{read_key} = undef;
    $self->{owns_reader} = 0;
  }
  return;
}

sub resume_terminal {
  my $self = shift;
  return $self->_enable_terminal_controls;
}

sub handle_key {
  my ($self, $key) = @_;
  return q{} if not defined $key;

  if ($key eq q{ } or lc($key) eq q{p}) {
    $self->{paused} = not $self->{paused};
    return $self->{paused} ? q{paused} : q{resumed};
  }
  if ($key eq q{+} or $key eq q{=}) {
    $self->{speed} *= $self->{speed_step};
    $self->{speed} = $self->{max_speed} if $self->{speed} > $self->{max_speed};
    return q{faster};
  }
  if ($key eq q{-} or $key eq q{_}) {
    $self->{speed} /= $self->{speed_step};
    $self->{speed} = $self->{min_speed} if $self->{speed} < $self->{min_speed};
    return q{slower};
  }
  if ($key eq q{0}) {
    $self->{speed} = $self->{base_speed};
    return q{reset};
  }

  return q{};
}

sub _poll_control {
  my $self = shift;
  return q{} if not $self->interactive;
  my $key = $self->{read_key}->();
  return $self->handle_key($key);
}

sub _wait_while_paused {
  my $self = shift;
  while ($self->{paused}) {
    $self->{sleep_cb}->(0.05);
    $self->_poll_control;
  }
  return;
}

sub _sleep_with_controls {
  my ($self, $seconds) = @_;
  return if not defined $seconds or $seconds <= 0;

  my $remaining = $seconds;
  while ($remaining > 0) {
    $self->_poll_control;
    $self->_wait_while_paused;

    my $slice = $remaining > 0.025 ? 0.025 : $remaining;
    $self->{sleep_cb}->($slice);
    $remaining -= $slice;
  }
  return;
}

sub stream {
  my ($self, $text) = @_;
  return if not defined $text;

  foreach my $char (split //, $text) {
    $self->_poll_control;
    $self->_wait_while_paused;
    $self->{write_cb}->($char);
    my $delay = $self->{delay} / $self->{speed};
    $self->_sleep_with_controls($delay);
  }
  return;
}

sub wait {
  my ($self, $seconds) = @_;
  return $self->_sleep_with_controls($seconds);
}

sub DESTROY {
  my $self = shift;
  $self->restore_terminal;
  return;
}

1;

__END__

=head1 NAME

Webservice::Rosary::Stream - terminal text streaming controls for avemaria

=head1 SYNOPSIS

  use Webservice::Rosary::Stream;

  my $stream = Webservice::Rosary::Stream->new(
    delay    => 0.04,
    speed    => 1,
    controls => 1,
  );

  $stream->stream("Hail Mary ...");

=head1 DESCRIPTION

This small helper provides the character-at-a-time presentation used by the
C<avemaria> client.  When STDIN and STDOUT are terminals it enables nonblocking
keyboard controls through L<Term::ReadKey>. Redirected output remains
noninteractive.

The controls are intentionally small: C<SPACE> or C<p> pauses and resumes,
C<+> speeds up, C<-> slows down, and C<0> restores the initial speed.

=head1 METHODS

=head2 new

Accepts C<delay>, C<speed>, C<controls>, C<min_speed>, C<max_speed>, and
C<speed_step>. The delay is the base number of seconds between characters.
C<speed> is a multiplier and defaults to C<1>. The default minimum and maximum
speeds are C<0.25> and C<8>, and each C<+> or C<-> adjustment changes the speed
by a factor of C<1.25>. These limits and the adjustment factor may be overridden
with C<min_speed>, C<max_speed>, and C<speed_step>.

For tests, C<read_key>, C<sleep_cb>, and C<write_cb> callbacks may be supplied,
which allows the timing and keyboard behavior to be exercised without a real
terminal.

=head2 stream

Streams the supplied text and processes real-time controls between characters
and during character delays.

=head2 wait

Waits for a specified number of seconds while continuing to process
interactive controls. Pause and resume affect the wait immediately; speed keys
are consumed but do not change the duration of this fixed wait.

=head2 handle_key

Processes one control key. C<SPACE> and C<p> toggle pause, C<+> and C<=>
increase speed, C<-> and C<_> decrease speed, and C<0> restores the initial
speed. Primarily useful for testing or alternate terminal front ends.

=head2 restore_terminal / resume_terminal

Restores normal terminal input before a blocking prompt and enables interactive
controls again afterward.

=head1 LICENSE AND COPYRIGHT

Same as Perl.

=cut

