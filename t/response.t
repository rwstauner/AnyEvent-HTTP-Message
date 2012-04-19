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

  my $res = new_ok($mod, [$body, { %headers }]);

  is $res->body, $body, 'body in/out';
  is $res->content, $body, 'content alias';
  is_deeply $res->headers, { 'x-interjection' => '3 cheers!' }, 'headers in/out';
  is_deeply $res->pseudo_headers, { Pseudo => 'Header' }, 'pseudo headers';

  is $res->header( 'X_Interjection' ), '3 cheers!', 'single header';

  is_deeply [ $res->args ], [ $body, { %headers } ], 'arg list';
}

# args via hashref
{
  my $body = 'the end';
  my %headers = (
    res_is => 'less useful than req'
  );

  my $res = new_ok($mod, [{
    headers => { %headers },
    body => $body,
    pseudo_headers => { Silly => 'wabbit' },
  }]);

  my %norm = ('res-is' => $headers{res_is});

  is $res->body, $body, 'body in/out';
  is $res->content, $body, 'content alias';
  is_deeply $res->headers, { %norm }, 'headers in/out';
  is_deeply $res->pseudo_headers, { Silly => 'wabbit' }, 'pseudo headers';

  is $res->header( $_ ), 'less useful than req', 'single header'
    for qw( res_is res-is RES_IS RES-IS );

  is_deeply [ $res->args ], [ $body, { %norm, Silly => 'wabbit' } ], 'arg list';
}

done_testing;
