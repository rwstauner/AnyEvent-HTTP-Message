# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Response;
# ABSTRACT: HTTP Response object for AnyEvent::HTTP

use parent 'AnyEvent::HTTP::Message';

=class_method new

See L</SYNOPSIS> for usage example.

Accepts a list of arguments
(like those that would be passed
to the callback in
L<AnyEvent::HTTP/http_request>)
which will be passed through L</parse_args>.

Alternatively a single hashref can be passed
with anything listed in L</ATTRIBUTES> as the keys.

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  if( my $h = $self->{headers} ){
    $self->{headers} = $self->_normalize_headers($h);
  }

  return $self;
}

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
      HTTPVersion => ($res->protocol =~ /HTTP\/([0-9.]+)/)[0]
    },
  };

  my $aeh = $args->{headers} = {};
  $res->headers->scan(sub {
    my ($k, $v) = @_;
    my $l = lc $k;
    $aeh->{$k} = exists($aeh->{$l}) ? $aeh->{$l} . ',' . $v : $v;
  });

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
my ($body, %headers, %pseudo);

=head1 SYNOPSIS

  # argument list like the callback for AnyEvent::HTTP::http_request
  AnyEvent::HTTP::Response->new($body, \%headers);

  # named arguments (via hashref):
  AnyEvent::HTTP::Response->new({
    body    => $body,
    headers => \%headers,
    pseudo_headers => \%pseudo,
  });

  # from LWP's HTTP::Response
  use HTTP::Response;
  AnyEvent::HTTP::Response->new(
    HTTP::Response->new( $code, $reason, [header => 'value', ], $body )
  );

  # psgi
  use HTTP::Message::PSGI;
  AnyEvent::HTTP::Response->new(
    HTTP::Response->from_psgi(
      [$code, [header => 'value', ], [$body]]
    )
  );

=head1 DESCRIPTION

This object represents an HTTP response from L<AnyEvent::HTTP>.

This is a companion class to L<AnyEvent::HTTP::Request>.

=head1 SEE ALSO

=for :list
* L<AnyEvent::HTTP::Message> (base class)
* L<HTTP::Response> More featureful object
* L<HTTP::Message::PSGI> Create an L<HTTP::Response> from a L<PSGI> arrayref

=cut
