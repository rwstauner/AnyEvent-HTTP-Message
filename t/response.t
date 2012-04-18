use strict;
use warnings;
use Test::More 0.88;

my $mod = 'AnyEvent::HTTP::Response';
eval "require $mod" or die $@;

# not much to test here, just order of args
{
  my $body = "black\nparade";
  my %headers = (
    Pseudo => 'Header',
    'x-interjection' => '3 cheers!'
  );

  test_new_response($body, { %headers }, [$body, { %headers }]);
}

# args via hashref
{
  my $body = 'the end';
  my %headers = (
    res_is => 'less useful than req'
  );

  test_new_response($body, { %headers }, [{
    headers => { %headers },
    body => $body,
  }]);
}

done_testing;

sub test_new_response {
  my ($body, $headers, $new_args) = @_;
  my %headers = %$headers;

  my $res = new_ok($mod, $new_args);

  is $res->body, $body, 'body in/out';
  is $res->content, $body, 'content alias';
  is_deeply $res->headers, { %headers }, 'headers in/out';

  is $res->header( uc $_ ), $headers->{$_}, 'single header'
    # skip pseudo-headers
    for grep { /^[a-z]/ } keys %$headers;

  is_deeply [ $res->args ], [ $body, { %headers } ], 'arg list';
}
