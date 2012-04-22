use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use AEHTTP_Tests;

my $mod = 'AnyEvent::HTTP::Request';
eval "require $mod" or die $@;

use AnyEvent::HTTP;
no warnings 'redefine';
local *AnyEvent::HTTP::http_request = sub ($$@) {
  return $mod->new(@_);
};
use warnings;

# parse_args error
foreach my $args ( [], [1,2], [1,2,3,4] ){
  is eval { $mod->parse_args(@$args) }, undef, 'wrong number of args';
  like $@, qr/expects an odd number of arguments/, 'error message';
}

# basic request
{
  my $cb = sub { 'ugly' };
  my $req = new_ok($mod, [
    post => 'scheme://host/path',
    persistent => 1,
    timeout => 3,
    body => 'rub a dub',
    headers => {
      User_Agent   => 'Any-Thing/0.1',
      'x-duck'     => 'quack',
    },
    $cb,
  ]);

  is $req->method, 'POST', 'request method';
  is $req->uri, 'scheme://host/path', 'request uri';
  is $req->body, 'rub a dub', 'request content';
  is $req->content, 'rub a dub', 'content alias';

  my $exp_headers = {
    'user-agent' => 'Any-Thing/0.1',
    'x-duck'     => 'quack',
  };

  is_deeply $req->headers, $exp_headers, 'request headers';
  is $req->header('User-Agent'), 'Any-Thing/0.1', 'single header';

  my $exp_params = {
    persistent => 1,
    timeout => 3,
  };

  is_deeply $req->params, $exp_params, 'params include headers';

  is $req->cb, $cb, 'callback';

  my @args = $req->args;
  is_deeply
    [ @args[0, 1, 10] ],
    [ POST => 'scheme://host/path', $cb ],
    'outer args correct';

  is_deeply
    { @args[2 .. 9] },
    {
      headers => $exp_headers,
      body    => 'rub a dub',
      %$exp_params,
    },
    'params in the middle of args';

  is $req->cb->(), 'ugly', 'ugly duckling';
  test_send($req);

  test_http_message $req, sub {
    my $msg = shift;
    is $msg->method, 'POST', 'method';
    is $msg->uri, 'scheme://host/path', 'uri';
    is $msg->header('user_agent'), 'Any-Thing/0.1', 'ua header';
    is $msg->content, 'rub a dub', 'body/content';
  };
}

# empty params
{
  my $cb = sub { 'fbbq' };
  my $req = new_ok($mod, [FOO => '//bar/baz', $cb]);

  is $req->method, 'FOO', 'request method';
  is $req->uri, '//bar/baz', 'request uri';
  is $req->cb, $cb, 'callback';

  is $req->body, '', 'no content';
  is $req->content, '', 'content alias';

  is_deeply $req->params, {}, 'empty params';
  is_deeply $req->headers, {}, 'empty headers';

  $req->headers->{qux} = 42;
  is_deeply $req->params, {}, 'params still empty (headers not included)';
  is_deeply $req->headers, {qux => 42}, 'headers no longer empty';

  is $req->cb->(), 'fbbq', 'callback works';
  test_send($req);

  test_http_message $req, sub {
    my $msg = shift;
    is $msg->method, 'FOO', 'method';
    is $msg->uri, '//bar/baz', 'uri';
    is $msg->header('QUX'), '42', 'single header';
    is $msg->content, '', 'body/content (empty string)';
  };
}

# construct via hashref
{
  my $cb = sub { 'yee haw' };
  my $req = new_ok($mod, [{
    method  => 'yawn',
    uri     => 'horse://sense',
    content => 'by cowboy',
    headers => {
      wa     => 'hoo',
      'x-wa' => 'x-hoo',
    },
    params  => {
      any_old   => 'setting',
      and_a_new => 'setting',
    },
    cb => $cb,
  }]);

  is $req->body, 'by cowboy', 'content init_arg converted to body';
  is $req->header('X-WA'), 'x-hoo', 'single header';

  # this is why i'm writing this module
  my @args = $req->args;
  my $end = $#args;
  is_deeply
    [ @args[0, 1, $end] ],
    [YAWN => 'horse://sense', $cb],
    'first and last args built from hashref';

  is_deeply
    { @args[ 2 .. $end - 1 ] },
    {
      any_old   => 'setting',
      and_a_new => 'setting',
      body      => 'by cowboy',
      headers   => {
        wa     => 'hoo',
        'x-wa' => 'x-hoo',
      },
    },
    'middle params built from hashref';

  is $args[-1]->(), 'yee haw', 'correct callback results';

  test_send($req);

  test_http_message $req, sub {
    my $msg = shift;
    is $msg->method, 'YAWN', 'method';
    is $msg->uri, 'horse://sense', 'uri';
    is $msg->header('Wa'), 'hoo', 'single header';
    is $msg->header('X-Wa'), 'x-hoo', 'single header';
    is $msg->content, 'by cowboy', 'body/content';
  };
}

test_http_message sub {
  my $msg = new_ok('HTTP::Request', [
    GET => 'blue://buildings',
    [
      x_rain     => 'king',
      user_agent => 'perfect',
      User_Agent => 'round here',
    ],
    'anna begins',
  ]);

  my $suffix = 'from HTTP::Request';
  my $req = new_ok($mod, [$msg]);
  is $req->method, 'GET', "method $suffix";
  is $req->uri, 'blue://buildings', "uri $suffix";
  is $req->body, 'anna begins', "body $suffix";
  is_deeply
    $req->headers,
    {
      'x-rain'     => 'king',
      'user-agent' => 'perfect,round here',
    },
    "converted headers $suffix";
};

done_testing;

# AE http_request overridden above
sub test_send {
  my $req = shift;
  my $sent = $req->send();
  is_deeply $sent, $req, 'object should have the same attributes';
  ok $sent != $req, 'but be separate objects';
}
