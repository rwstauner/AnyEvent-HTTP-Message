# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Response;
# ABSTRACT: HTTP Response object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';
use Carp ();

=class_method new

See L</SYNOPSIS> for usage example.

Accepts a list of arguments
(like those that would be passed
to the callback in
L<AnyEvent::HTTP/http_request>)
which will be passed through L</parse_args>.

Alternatively a single hashref can be passed
with anything listed in L</ATTRIBUTES> as the keys.

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

=class_method parse_args

Called by the constructor
to parse the argument list
passed to the callback in
L<AnyEvent::HTTP/http_request>
and return a hashref which will be the basis for the object.

The list should look like
C<< ($body, \%headers) >>.

This is less useful than it's counterpart
(L<AnyEvent::HTTP::Request/parse_args>)
but is provided for consistency/completeness.

=cut

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

=head1 TODO

=for :list
* Provide conversion to/from more featureful L<HTTP::Response>

=head1 SEE ALSO

=for :list
* L<AnyEvent::HTTP::Message> (base class)

=cut
