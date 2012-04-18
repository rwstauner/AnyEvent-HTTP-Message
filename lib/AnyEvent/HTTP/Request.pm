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
    unless @_ & 1; ## no critic BitwiseOperators

  my $args = {
    method => shift,
    uri    => shift,
    cb     => pop,
    params => { @_ },
  };
  return $args;
}

=method args

Returns a list of arguments that can passed to
L<AnyEvent::HTTP/http_request>.

=cut

sub args {
  my ($self) = @_;
  return (
    $self->method => $self->uri,
    %{ $self->params },
    $self->cb,
  );
}

=for :stopwords uri cb params

=attr method

Request method (GET, POST, etc)
(first argument to L<AnyEvent::HTTP/http_request>).

=attr uri

Request uri (string)
(second argument to L<AnyEvent::HTTP/http_request>).

=attr cb

Callback subroutine reference
(last argument to L<AnyEvent::HTTP/http_request>).

=attr params

A hashref of the function parameters
(optional middle (key => value) arguments to L<AnyEvent::HTTP/http_request>).

B<Note> that these are connection params like
C<persistent> and C<timeout>,
not query params like in C<CGI>.

=cut

sub method  { $_[0]->{method} }
sub uri     { $_[0]->{uri}    }
sub cb      { $_[0]->{cb}     }
sub params  { $_[0]->{params} ||= {} }

=attr headers

A hashref of the HTTP request headers
(the C<headers> key of L</params>).

=attr body

Request content body (if any)
(the C<body> key of L</params>).

=attr content

Alias for L</body>

=cut

sub headers { $_[0]->params->{headers} ||= {} }
sub body    { $_[0]->params->{body} }

1;

=for test_synopsis
my ($body, %params, %headers, $uri);

=head1 SYNOPSIS

  # parse argument list for AnyEvent::HTTP::http_request
  AnyEvent::HTTP::Request->new(GET => $uri, %params, sub { ... });

  # or use a hashref of named arguments
  AnyEvent::HTTP::Request->new({
    method  => 'POST',
    uri     => 'http://example.com',
    cb      => sub { ... },
    params  => \%params,
    headers => \%headers,
    body    => $body,
  });

=head1 DESCRIPTION

This class creates a lightweight object
to represent an HTTP request as used by L<AnyEvent::HTTP>.

It was created to provide simple, clear test code
for parsing the parameters passed to L<AnyEvent::HTTP/http_request>.

Instead of code that looks something like this:

  is $args[0],       'POST',              'request method';
  is $args[1],       'http://some/where', 'request uri';
  is ref($args[-1]), 'CODE',              'http_request callback';
  is_deeply { @args[ 2 .. $#args - 1 ] }->{headers},
    \%expected_headers, 'request headers';

You can write clearer, simpler code like this:

  my $req = AnyEvent::HTTP::Request->new(@args);

  is $req->method,  'POST',              'request method';
  is $req->uri,     'http://some/where', 'request uri';
  is ref($req->cb), 'CODE',              'http_request callback';
  is_deeply $req->headers, \%expected_headers, 'request headers';

It's a little less weird, and easier to maintain (and do again).

This class also allows you to build an object by passing a hashref
of named parameters in case you'd prefer that.
You can then use the L</args> method to pass the values
to L<AnyEvent::HTTP/http_request>:

  AnyEvent::HTTP::http_request( $req->args );

=cut
