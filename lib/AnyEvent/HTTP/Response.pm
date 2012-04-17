# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Response;
# ABSTRACT: HTTP Response object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';
use Carp ();

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

sub body    { $_[0]->{body}    }
sub headers { $_[0]->{headers} }

1;

=head1 SYNOPSIS

  # named arguments (via hashref):
  AnyEvent::HTTP::Request->new({ body => $body, headers => \%headers });

  # argument list like the callback for AnyEvent::HTTP::http_request
  AnyEvent::HTTP::Request->new($body, \%headers);

=head1 DESCRIPTION

This object represents an HTTP response from L<AnyEvent::HTTP>.

=cut
