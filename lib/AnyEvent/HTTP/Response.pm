# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Response;
# ABSTRACT: HTTP Response object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';

=class_method new

Accepts an argument list like the callback provided to
L<AnyEvent::HTTP/http_request>
(see L</parse_args>):

  AnyEvent::HTTP::Response->new($body, \%headers);

Alternatively accepts an instance of
L<HTTP::Response>
(see L</from_http_message>):

  AnyEvent::HTTP::Response->new(
    HTTP::Response->new( $code, $reason, $headers, $body )
  );

Also accepts a single hashref of named attributes
(see L</ATTRIBUTES>):

  AnyEvent::HTTP::Response->new({
    body    => $body,
    headers => \%headers,
    pseudo_headers => \%pseudo,
  });

=method args

Returns a list of arguments like those passed to the callback in
L<AnyEvent::HTTP/http_request>.

=cut

sub args {
  my ($self) = @_;
  return (
    $self->body,
    {
      %{ $self->headers },
      %{ $self->pseudo_headers },
    },
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

This will separate the "pseudo" headers
from the regular http headers
as described by
L<AnyEvent::HTTP/http_request>
(http headers are lower-cased
and pseudo headers start with an upper case letter).

=cut

sub parse_args {
  my $self = shift;
  $self->_error(
    q[expects two arguments: ($content_body, \%headers)]
  )
    unless @_ == 2;

  my $args  = {
    body    =>      $_[0],
  };

  my %headers = %{ $_[1] };
  my %pseudo;
  {
    my @pseudo = grep { /^[A-Z]/ } keys %headers;
    # remove the ae-http pseudo-headers (init-capped)
    @pseudo{ @pseudo } = delete @headers{ @pseudo };
  }
  @$args{qw(headers pseudo_headers)} = (\%headers, \%pseudo);

  return $args;
}

=class_method from_http_message

Called by the constructor
when L</new> is passed an instance of L<HTTP::Response>.

=cut

sub from_http_message {
  my ($self, $res) = @_;
  my $args = {
    body => $res->${\ ($res->can('decoded_content') || 'content') },
    pseudo_headers => {
      Status => $res->code,
      Reason => $res->message,
    },
    headers => $self->_hash_http_headers($res->headers),
  };
  if( my $proto = $res->protocol ){
    # regexp taken straight from AnyEvent::HTTP 2.13
    $args->{pseudo_headers}{HTTPVersion} = ($proto =~ /^HTTP\/0*([0-9\.]+)/)[0];
  }

  return $args;
}

=attr body

Response content body

=attr content

Alias for L</body>

=attr headers

HTTP Response headers

=attr pseudo_headers

A hashref of extra fields
that L<AnyEvent::HTTP/http_request> returns with the http headers
(the ones that start with an upper-case letter... Status, Reason, etc).

=cut

sub pseudo_headers { $_[0]->{pseudo_headers} ||= {} }

=method to_http_message

Returns an instance of L<HTTP::Response>
to provide additional functionality.

=cut

sub to_http_message {
  my ($self) = @_;
  require HTTP::Response;

  my $res = HTTP::Response->new(
    @{ $self->pseudo_headers }{qw(Status Reason)},
    [ %{ $self->headers } ],
    $self->body
  );
  if( my $v = $self->pseudo_headers->{HTTPVersion} ){
    $res->protocol("HTTP/$v")
  }
  return $res;
}

1;

=for test_synopsis
my ($uri);

=head1 SYNOPSIS

  # parses argument list passed to AnyEvent::HTTP::http_request callback
  AnyEvent::HTTP::http_request(
    GET => $uri,
    sub {
      my $res = AnyEvent::HTTP::Response->new(@_);

      # inspect attributes
      print $res->header('Content-Type');
      print $res->body;

      # upgrade to HTTP::Response
      my $http_res = $res->to_http_message;
      if( !$http_res->is_success ){
        print $http_res->status_line;
      }
    }
  );

=head1 DESCRIPTION

This object represents an HTTP response from L<AnyEvent::HTTP>.

This is a companion class to L<AnyEvent::HTTP::Request>.

It parses the arguments passed to the final callback in
L<AnyEvent::HTTP/http_request>
(or produces the arguments that should be passed to that,
depending on how you'd like to use it).
and wraps them in an object.

It can also be converted L<from|/from_http_message> or L<to|/to_http_message>
the more featureful
L<HTTP::Response>.

=head1 SEE ALSO

=for :list
* L<AnyEvent::HTTP>
* L<AnyEvent::HTTP::Message> (base class)
* L<HTTP::Response> More featureful object
* L<HTTP::Message::PSGI> Create an L<HTTP::Response> from a L<PSGI> arrayref

=cut
