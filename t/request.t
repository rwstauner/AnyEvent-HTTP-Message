use strict;
use warnings;
use Test::More 0.88;

my $mod = 'AnyEvent::HTTP::Request';
eval "require $mod" or die $@;

# basic request
{
  my $cb = sub { 'ugly' };
  my $req = new_ok($mod, [
    post => 'scheme://host/path',
    persistent => 1,
    body => 'rub a dub',
    headers => {
      'user-agent' => 'Any-Thing/0.1',
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

  my $exp_params = {
    persistent => 1,
    headers => $exp_headers,
    body => 'rub a dub',
  };

  is_deeply $req->params, $exp_params, 'params include headers';

  is_deeply $req->cb, $cb, 'callback';

  my @args = $req->args;
  is_deeply
    [ @args[0,1,8] ],
    [ POST => 'scheme://host/path', $cb ],
    'outer args correct';

  is_deeply { @args[2 .. 7] }, $exp_params, 'params in the middle of args';

  is $req->cb->(), 'ugly', 'ugly duckling';
}

# empty params
{
  my $cb = sub { 'fbbq' };
  my $req = new_ok($mod, [FOO => '//bar/baz', $cb]);

  is $req->method, 'FOO', 'request method';
  is $req->uri, '//bar/baz', 'request uri';
  is $req->cb, $cb, 'callback';

  is $req->body, undef, 'no content';
  is $req->content, undef, 'content alias';

  is_deeply $req->params, {}, 'empty params';
  is_deeply $req->headers, {}, 'empty headers';

  $req->headers->{qux} = 42;
  is_deeply
    $req->params,
    {
      headers => {
        qux => 42,
      },
    },
    'params contains headers';

  is $req->cb->(), 'fbbq', 'callback works';
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
}

done_testing;
