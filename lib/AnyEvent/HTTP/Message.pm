# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Message;
# ABSTRACT: Base class for AnyEvent::HTTP Request/Response

sub new {
  my $class = shift;
  my $self = @_ == 1 && ref($_[0]) eq 'HASH'
      # if passed a single hashref take a shallow copy
    ? { %{ $_[0] } }
      # otherwise it's the argument list for http_request()
    : $class->parse_args(@_);
  bless $self, $class;
}

1;

=head1 SYNOPSIS

  # don't use this directly

=head1 DESCRIPTION

This is a base class for:

=for :list
* L<AnyEvent::HTTP::Request>
* L<AnyEvent::HTTP::Response>

=cut
