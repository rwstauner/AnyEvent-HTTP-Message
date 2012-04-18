# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Message;
# ABSTRACT: Lightweight objects for AnyEvent::HTTP Request/Response

sub new {
  my $class = shift;

  my $self = @_ == 1 && ref($_[0]) eq 'HASH'
      # if passed a single hashref take a shallow copy
    ? { %{ $_[0] } }
      # otherwise it's the argument list for http_request()
    : $class->parse_args(@_);

  # accept 'content' as an alias for 'body', but store as 'body'
  $self->{body} = delete $self->{content}
    if exists $self->{content};

  bless $self, $class;
}

=attr body

Message content body

=attr content

Alias for L</body>

=attr headers

Message headers (hashref)

=cut

# stubs for read-only accessors
sub body    { $_[0]->{body}           }
sub headers { $_[0]->{headers} ||= {} }

# alias
sub content { $_[0]->body }

=method header

  my $ua  = $message->header('User-Agent');
  # same as $message->header->{'user-agent'};

Takes the specified key,
converts C<_> to C<-> and lower-cases it,
then returns the value of that message header.

=cut

sub header {
  my ($self, $h) = @_;
  $h =~ tr/_/-/;
  return $self->headers->{ lc $h };
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
