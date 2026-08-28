package Webservice::Rosary::Tradition;

use v5.10;
use strict;
use warnings;

use Exporter qw/import/;

our @EXPORT_OK = qw/opening_intention pope_name/;

sub pope_name {
  return q{Pope Leo XIV};
}

sub opening_intention {
  my $prayer = shift;
  return q{} if not defined $prayer;

  $prayer = lc $prayer;

  return sprintf q{For the intentions and well-being of %s.}, pope_name()
    if $prayer eq q{our__father_1};
  return q{For an increase in Faith.}   if $prayer eq q{hail__mary_1};
  return q{For an increase in Hope.}    if $prayer eq q{hail__mary_2};
  return q{For an increase in Charity.} if $prayer eq q{hail__mary_3};

  return q{};
}

1;

__END__

=head1 NAME

Webservice::Rosary::Tradition - local devotional metadata for the Rosary client

=head1 SYNOPSIS

  use Webservice::Rosary::Tradition qw/opening_intention pope_name/;

  say pope_name();
  say opening_intention('our__father_1');
  say opening_intention('hail__mary_1');

=head1 DESCRIPTION

The upstream Rosary API supplies the prayer text and detailed information for
individual Mysteries, including their titles and fruits. Some traditional
presentation metadata used by the C<avemaria> commandline client is not part of
the upstream API response.

This module keeps that local devotional metadata separate from
L<Webservice::Rosary::API> so the API wrapper continues to represent the remote
service accurately.

At present the introductory Our Father is identified as being offered for the
intentions and well-being of Pope Leo XIV, and the first three Hail Marys are
offered for an increase in Faith, Hope, and Charity.

=head1 FUNCTIONS

=head2 pope_name

Returns the name used by the client when presenting the introductory papal
intention. Keeping the name here makes a future update a single, explicit
change.

=head2 opening_intention

  my $text = opening_intention('hail__mary_2');

Returns the local intention associated with an introductory prayer key, or an
empty string when the prayer has no local introductory intention.

The currently recognized keys are C<our__father_1>, C<hail__mary_1>,
C<hail__mary_2>, and C<hail__mary_3>.

=head1 LICENSE AND COPYRIGHT

Same as Perl.

=cut

