# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package AnyEvent::HTTP::Message;
# ABSTRACT: Lightweight objects for AnyEvent::HTTP Request/Response

use Carp ();
use Scalar::Util ();

=class_method new

The constructor accepts either:

=for :list
* a single hashref of named arguments
* an instance of an appropriate subclass of L<HTTP::Message>
* or a specialized list of arguments that will be passed to L</parse_args> (which must be defined by the subclass).

=cut

sub new {
  my $class = shift;

  my $self;
  if( @_ == 1 ){
    my $arg = $_[0];
    if( ref($arg) eq 'HASH' ){
      # if passed a single hashref take a shallow copy
      $self = { %$arg };
    }
    elsif( Scalar::Util::blessed($arg) && $arg->isa('HTTP::Message') ){
      $self = $class->from_http_message($arg);
    }
    else {
      $class->_error(sprintf qq[Invalid argument: '%s'], ref($arg) || $arg);
    }
  }
  else {
      # otherwise it's the argument list for http_request()
    $self = $class->parse_args(@_);
  }

  # accept 'content' as an alias for 'body', but store as 'body'
  $self->{body} = delete $self->{content}
    if exists $self->{content};

  bless $self, $class;
}

sub _error {
  my $self = shift;
  @_ = join ' ', (ref($self) || $self), 'error:', @_;
  goto &Carp::croak;
}

=class_method parse_args

Called by the constructor
when L</new> is called with a list of arguments.

Must be customized by subclasses.

=cut

sub parse_args {
  $_[0]->_error('parse_args() is not defined');
}

=class_method from_http_message

Called by the constructor
when L</new> is called with a single argument that is
an instance of a L<HTTP::Message> subclass.

Must be customized by subclasses.

=cut

sub from_http_message {
  $_[0]->_error('from_http_message() is not defined');
}

# turn HTTP::Headers into a hashref
sub _hash_http_headers {
  my ($self, $headers) = @_;
  my $aeh = {};
  $headers->scan(sub {
    my ($k, $v) = @_;
    my $l = lc $k;
    $aeh->{$l} = exists($aeh->{$l}) ? $aeh->{$l} . ',' . $v : $v;
  });
  return $aeh;
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

sub _normalize_headers {
  my ($self, $headers) = @_;
  my $norm = {};
  while( my ($k, $v) = each %$headers ){
    my $n = $k;
    $n =~ tr/_/-/;
    $norm->{ lc $n } = $v;
  }
  return $norm;
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
