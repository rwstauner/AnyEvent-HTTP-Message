# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Response;
# ABSTRACT: HTTP Response object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';
use Carp ();

=method args

Returns a list of arguments like those passed to the callback in
L<AnyEvent::HTTP/http_request>.

=cut

sub args {
  my ($self) = @_;
  return (
    $self->body,
    $self->headers,
  );
}

sub parse_args {
  my $self = shift;
  Crap::croak(
    (ref($self) || $self) .
    q[ expects two arguments: ($content_body, \%headers)]
  )
    unless @_ == 2;

  my $args  = {
    body    =>      $_[0],
    headers => { %{ $_[1] } },
  };
  return $args;
}

=attr body

Response content body

=attr content

Alias for L</body>

=attr headers

HTTP Response headers

=cut


1;

=for test_synopsis
my ($body, %headers, $code);

=head1 SYNOPSIS

  # named arguments (via hashref):
  AnyEvent::HTTP::Request->new({ body => $body, headers => \%headers });

  # argument list like the callback for AnyEvent::HTTP::http_request
  AnyEvent::HTTP::Request->new($body, \%headers);

=head1 DESCRIPTION

This object represents an HTTP response from L<AnyEvent::HTTP>.

This is a companion class to L<AnyEvent::HTTP::Request>
though it's arguably less useful since the argument list is simpler.

=cut
