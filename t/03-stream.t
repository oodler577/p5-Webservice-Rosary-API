use strict;
use warnings;
use Test::More;

use Webservice::Rosary::Stream;

my $output = '';
my $slept = 0;
my $plain = Webservice::Rosary::Stream->new(
  delay    => 0.01,
  controls => 0,
  write_cb => sub { $output .= shift },
  sleep_cb => sub { $slept += shift },
);
$plain->stream('abc');
is($output, 'abc', 'stream writes every character in order');
cmp_ok(abs($slept - 0.03), '<', 0.000001, 'stream applies configured per-character delay');
ok(!$plain->interactive, 'controls-disabled stream is noninteractive');

my $keys = Webservice::Rosary::Stream->new(
  delay    => 0,
  controls => 1,
  read_key => sub { return undef },
  sleep_cb => sub { },
  write_cb => sub { },
);
is($keys->handle_key('+'), 'faster', '+ is recognized as faster');
cmp_ok($keys->speed, '>', 1, 'faster key increases speed');
is($keys->handle_key('-'), 'slower', '- is recognized as slower');
cmp_ok(abs($keys->speed - 1), '<', 0.000001, 'slower key reverses one speed step');
$keys->handle_key('+');
$keys->handle_key('+');
$keys->handle_key('0');
cmp_ok(abs($keys->speed - 1), '<', 0.000001, '0 resets the initial speed');
is($keys->handle_key('p'), 'paused', 'p pauses');
ok($keys->paused, 'paused state is visible');
is($keys->handle_key(' '), 'resumed', 'space resumes');
ok(!$keys->paused, 'resume clears paused state');
is($keys->handle_key('x'), '', 'unrelated keys are ignored');

my @pause_keys = ('p', undef, 'p');
$output = '';
$slept = 0;
my $pausable = Webservice::Rosary::Stream->new(
  delay    => 0,
  controls => 1,
  read_key => sub { return shift @pause_keys },
  write_cb => sub { $output .= shift },
  sleep_cb => sub { $slept += shift },
);
$pausable->stream('A');
is($output, 'A', 'paused stream resumes at the same character');
ok(!$pausable->paused, 'stream is resumed after second pause key');
cmp_ok($slept, '>=', 0.10, 'paused stream waits without advancing text');

my @speed_keys = ('+', undef, undef, undef, undef, undef);
$output = '';
$slept = 0;
my $speedy = Webservice::Rosary::Stream->new(
  delay    => 0.10,
  controls => 1,
  read_key => sub { return shift @speed_keys },
  write_cb => sub { $output .= shift },
  sleep_cb => sub { $slept += shift },
);
$speedy->stream('A');
is($output, 'A', 'real-time speed change does not alter output');
cmp_ok(abs($slept - 0.08), '<', 0.000001, 'real-time + key changes the current character pacing');

my $bad = eval { Webservice::Rosary::Stream->new(delay => -1, controls => 0); 1 };
ok(!$bad, 'negative delay is rejected');
like($@, qr/delay must be zero or greater/, 'negative delay error is descriptive');

$bad = eval { Webservice::Rosary::Stream->new(speed => 0, controls => 0); 1 };
ok(!$bad, 'zero speed is rejected');
like($@, qr/speed must be greater than zero/, 'zero speed error is descriptive');

done_testing;

