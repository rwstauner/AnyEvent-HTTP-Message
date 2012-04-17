# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Request;
# ABSTRACT: HTTP Request object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';
use Carp ();

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  $self->{method} = uc $self->{method};

  # allow these to be constructor arguments
  # but store them in params to keep things simple
  foreach my $key ( qw( body headers ) ){
    $self->{params}->{$key} = delete $self->{$key}
      if exists $self->{$key};
  }

  return $self;
}

sub parse_args {
  my $self = shift;

  Crap::croak( join ' ',
    (ref($self) || $self),
    q[expects an odd number of arguments:],
    q[($method, $uri, (key => value, ...)*, \&callback)]
  )
    unless @_ & 1;

  my $args = {
    method => shift,
    uri    => shift,
    cb     => pop,
    params => { @_ },
  };
  return $args;
}

sub args {
  my ($self) = @_;
  return (
    $self->method => $self->uri,
    %{ $self->params },
    $self->cb,
  );
}

sub method  { $_[0]->{method} }
sub uri     { $_[0]->{uri}    }
sub cb      { $_[0]->{cb}     }
sub params  { $_[0]->{params} ||= {} }

sub headers { $_[0]->params->{headers} ||= {} }
sub body    { $_[0]->params->{body} }

1;

=for test_synopsis
my ($body, %params, %headers, $uri);

=head1 SYNOPSIS

  # named arguments (via hashref):
  AnyEvent::HTTP::Request->new({
    method  => 'POST',
    uri     => 'http://example.com',
    cb      => sub { ... },
    params  => \%params,
    headers => \%headers,
    body    => $body,
  });

  # or argument list for AnyEvent::HTTP::http_request
  AnyEvent::HTTP::Request->new(GET => $uri, %params, sub { ... });

  # TODO: usage

=head1 DESCRIPTION

B<Note>:
This object represents a B<request> not a B<user agent>.

=cut
