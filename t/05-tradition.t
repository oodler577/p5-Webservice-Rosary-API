use v5.10;
use strict;
use warnings;

use Test::More;
use Webservice::Rosary::Tradition qw/opening_intention pope_name/;

is pope_name(), 'Pope Leo XIV', 'current Pope is centralized';
is opening_intention('our__father_1'),
  'For the intentions and well-being of Pope Leo XIV.',
  'opening Our Father has the papal intention';
is opening_intention('hail__mary_1'), 'For an increase in Faith.',
  'first introductory Hail Mary is for Faith';
is opening_intention('hail__mary_2'), 'For an increase in Hope.',
  'second introductory Hail Mary is for Hope';
is opening_intention('hail__mary_3'), 'For an increase in Charity.',
  'third introductory Hail Mary is for Charity';
is opening_intention('glory_be_1'), q{}, 'other prayers have no opening intention';
is opening_intention(undef), q{}, 'undefined prayer has no opening intention';

done_testing;
