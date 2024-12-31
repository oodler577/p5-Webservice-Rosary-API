package Webservice::Rosary::API;

use v5.10;
use strict;

use Util::H2O::More qw/baptise ddd HTTPTiny2h2o h2o/;
use HTTP::Tiny qw//;

our $VERSION = "0.1.2";

use constant {
  BASEURL  => "https://the-rosary-api.vercel.app/v1",
  DAILYURL => "https://dailyrosary.cf",
};

sub new {
  my $pkg = shift;
  my $params = { @_, ua => HTTP::Tiny->new };
  my $self = baptise $params, $pkg, qw//;
  return $self;
}

sub _make_call {
  my ($self, $when) = @_;
  my $URL = sprintf "%s/%s", BASEURL, $when;
  my $resp = HTTPTiny2h2o $self->ua->get($URL);
  return $resp->content;
}

#TODO - add "list", date/MMDDYY, and novena/MMDDYY
sub mp3Link {
  my ($self, $when) = @_;
  my @mp3 = qw/today yesterday tomorrow random/;
  # invalid
  return "" if (not grep { m/^$when$/i } @mp3);
  # valid
  return sprintf "%s/%s", DAILYURL, $self->_make_call($when)->get(0)->mp3Link;
}

sub day {
  my ($self, $when) = @_;
  my @days = qw/sunday monday tuesday wednesday thursday friday/;
  return "" if (not grep { m/^$when$/i } @days);
  return $self->_make_call($when)->get(0);
}

# Get detailed recitations
sub Decades {
  my ($self, $when) = @_;
  my @mysteries = qw/joyful glorious sorrowful luminous/;
  return "" if (not grep { m/^$when$/i } @mysteries);
  return $self->_make_call($when);
}

123

__END__

=head1 NAME

Webservice::Rosary::API - Perl API client for the Rosary API at L<https://therosaryapi.cf>.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 C<AveMaria> UTILITY

=head1 ENVIRONMENT

=head1 BUGS

=head1 LICENSE AND COPYRIGHT
