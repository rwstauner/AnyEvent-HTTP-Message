# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Request;
# ABSTRACT: HTTP Request object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';

=class_method new

Accepts the same argument list as
L<AnyEvent::HTTP/http_request>
(see L</parse_args>):

  AnyEvent::HTTP::Request->new(
    $method => $uri,
    body    => $body,
    headers => \%headers,
    %params,
    sub { ... }
  );

Alternatively accepts an instance of
L<HTTP::Request>
with an optional hashref of extra attributes
(see L</from_http_message>):

  AnyEvent::HTTP::Request->new(
    HTTP::Request->new( $method, $uri, $headers, $body ),
    {
      cb => sub { ... },
      params => \%params,
    }
  );

Also accepts a single hashref of named attributes
(see L</ATTRIBUTES>):

  AnyEvent::HTTP::Request->new({
    method  => 'POST',
    uri     => 'http://example.com',
    cb      => sub { ... },
    params  => \%params,
    headers => \%headers,
    body    => $body,
  });

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  $self->{method} = uc $self->{method};

  return $self;
}

=class_method parse_args

Called by the constructor
to parse the argument list
for
L<AnyEvent::HTTP/http_request>
and return a hashref which will be the basis for the object.

The list should look like
C<< ($method, $uri, %optional, \&callback) >>
where the C<%optional> hash may include C<body>, C<headers>,
and any of the other options accepted by
L<AnyEvent::HTTP/http_request>
(which will become L</params>).

=cut

sub parse_args {
  my $self = shift;

  $self->_error(
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

  # remove these from params
  $args->{$_} = delete $args->{params}{$_}
    for qw( body headers );

  return $args;
}

=class_method from_http_message

Called by the constructor
when L</new> is passed an instance of L<HTTP::Request>.

Since only C<method>, C<uri>, C<headers>, and C<body>
can be determined from L<HTTP::Request>,
a hashref can be passed as a second parameter
containing C<cb> and C<params>.

=cut

sub from_http_message {
  my ($self, $req, $extra) = @_;
  my $args = {
    method  => $req->method,
    uri     => $req->uri,
    headers => $self->_hash_http_headers($req->headers),
    body    => $req->content,
    (ref($extra) eq 'HASH' ? %$extra : ()),
  };
  return $args;
}

=method args

Returns a list of arguments that can be passed to
L<AnyEvent::HTTP/http_request>
(beware the sub's prototype, though).

=cut

sub args {
  my ($self) = @_;
  return (
    $self->method => $self->uri,
    body    => $self->body,
    headers => $self->headers,
    %{ $self->params },
    $self->cb,
  );
}

=for :stopwords uri cb params

=attr method

Request method (GET, POST, etc)
(first argument to L<AnyEvent::HTTP/http_request>)

=attr uri

Request uri (string)
(second argument to L<AnyEvent::HTTP/http_request>)

=attr body

Request content body

=attr content

Alias for L</body>

=attr headers

A hashref of the HTTP request headers

=attr params

A hashref of the function parameters
(optional middle (key => value) arguments to L<AnyEvent::HTTP/http_request>)

B<Note> that these are connection params like
C<persistent> and C<timeout>,
not query params like in C<CGI>.

B<Note> that C<body> and C<headers> will not be included.
This hashref is essentially I<user-agent> parameters.

=attr cb

Callback subroutine reference
(last argument to L<AnyEvent::HTTP/http_request>)

B<Note>: For consistency with the other attributes
(and to avoid confusion with other modules)
this is a read-only accessor and will C<croak> if passed any arguments.

If you intend to execute the callback (to simulate a response)
you can derefernce the return value:

  $req->cb->($body, $headers);

=cut

sub method  { $_[0]->{method} }
sub uri     { $_[0]->{uri}    }
sub cb      {
  my $self = shift;
  $self->_error(
    q[cb() is a read-only accessor (for consistency and to avoid confusion).],
    q[To execute the callback dereference it: $req->cb->($body, \%headers)]
  )
    if @_;
  return $self->{cb};
}
sub params  { $_[0]->{params} ||= {} }

=method send

Actually submit the request by passing L</args>
to L<AnyEvent::HTTP/http_request>

=cut

sub send {
  my ($self) = @_;
  require AnyEvent::HTTP;
  # circumvent the sub's prototype
  &AnyEvent::HTTP::http_request( $self->args );
}

=method to_http_message

Returns an instance of L<HTTP::Request>
to provide additional functionality.

B<Note> that L</cb> and L</params>
will not be represented in the L<HTTP::Request> object
(since they are for the user-agent and not the request).

=cut

sub to_http_message {
  my ($self) = @_;
  require HTTP::Request;

  my $res = HTTP::Request->new(
    $self->method,
    $self->uri,
    [ %{ $self->headers } ],
    $self->body
  );
  return $res;
}

1;

=for test_synopsis
my ($uri, $body, %headers, %params);

=head1 SYNOPSIS

  # parses the same argument list as AnyEvent::HTTP::http_request
  my $req = AnyEvent::HTTP::Request->new(
    POST => $uri,
    body => $body,
    headers => \%headers,
    %params,
    sub { ... }
  );

  # provides introspection
  print $req->header('user-agent');
  print $req->uri;

  # can be upgraded to an HTTP::Request object
  my $http_req = $req->to_http_message;

  # or submitted via AnyEvent::HTTP::http_request
  $req->send();

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
You can then call L</send> to actually make the request
(via L<AnyEvent::HTTP/http_request>),
or L</args> to get the list of arguments the object would pass.

It can also be converted L<from|/from_http_message> or L<to|/to_http_message>
the more featureful
L<HTTP::Request>.

=head1 SEE ALSO

=for :list
* L<AnyEvent::HTTP>
* L<AnyEvent::HTTP::Message> (base class)
* L<HTTP::Request> - More featureful object

=cut
