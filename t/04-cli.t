use v5.10;
use strict;
use warnings;

use Test::More;
use FindBin qw/$Bin/;

require "$Bin/../bin/avemaria";

sub split_cli {
  my @args = @_;
  my ($command, $argv, $implicit) = local::bin::avemaria::_split_command_line(@args);
  return ($command, [@$argv], $implicit);
}

{
  my ($command, $argv, $implicit) = split_cli();
  is $command, q{}, 'bare invocation has no explicit command';
  is_deeply $argv, [], 'bare invocation has no remaining options';
  ok $implicit, 'bare invocation implies today';
}

{
  my ($command, $argv, $implicit) = split_cli('--scroll');
  is $command, q{}, '--scroll is not mistaken for a subcommand';
  is_deeply $argv, ['--scroll'], '--scroll remains available to prayer option parsing';
  ok $implicit, '--scroll alone implies today';
}

{
  my ($command, $argv, $implicit) = split_cli('--speed=2', '--between=0');
  is $command, q{}, 'timing options do not become subcommands';
  is_deeply $argv, ['--speed=2', '--between=0'], 'timing options are preserved';
  ok $implicit, 'timing options alone imply today';
}

{
  my ($command, $argv, $implicit) = split_cli('Monday', '--scroll');
  is $command, 'Monday', 'explicit day remains the subcommand';
  is_deeply $argv, ['--scroll'], 'options after an explicit day are preserved';
  ok !$implicit, 'explicit day does not implicitly enable prayer';
}

for my $help (qw/-h --help/) {
  my ($command, $argv, $implicit) = split_cli($help);
  is $command, $help, "$help remains a help command";
  ok !$implicit, "$help does not imply prayer";
}

for my $about (qw/-a --about/) {
  my ($command, $argv, $implicit) = split_cli($about);
  is $command, $about, "$about remains an about command";
  ok !$implicit, "$about does not imply prayer";
}

done_testing;

