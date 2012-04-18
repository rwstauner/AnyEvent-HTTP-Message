use strict;
use warnings;
use Test::More 0.88;

my $mod = 'AnyEvent::HTTP::Message';
eval "require $mod" or die $@;

my $tmod = $mod . '::Test';
eval <<PKG;
{
  package #
    $tmod;
  our \@ISA = '$mod';
  sub body { uc shift->{body} }
  sub parse_args {
    shift;
    return { body => shift, headers => { \@_ } };
  }
}
PKG

foreach my $args (
  ['silly', 'fake-header' => 'fake-value'],
  [{
    body => 'silly',
    headers => { 'fake-header' => 'fake-value' },
  }],
){
  my $msg = new_ok($tmod, [@$args]);

  is $msg->body,    'SILLY', 'body';
  is $msg->content, 'SILLY', 'content alias';

  is $msg->header('fake_header'), 'fake-value', 'single header';
}

{
  is eval { $mod->new({foo => 'bar'}); 1 }, 1, 'message created with hashref';

  is eval { $mod->new( foo => 'bar' ); 1 }, undef, 'failed to create message without hashref';
  like $@, qr/not defined a parse_args/, 'error describes missing method';
}

done_testing;
