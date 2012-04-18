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
}

done_testing;
