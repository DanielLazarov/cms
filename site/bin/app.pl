#!/usr/bin/env perl
use strict;

use lib q{/usr/share/cms/site/lib/perl};
use lib q{/usr/share/cms/libs};

use Mojolicious::Lite;

use CMS::WebHandler;

my $app = app;
push @{$app->renderer->paths}, '/usr/share/cms/site/templates/';


my $static = $app->static();
push @{$static->paths}, '/usr/share/cms/site/pub/';



get('/' => \&CMS::WebHandler::Home);
get('/home' => \&CMS::WebHandler::Home);
get('/blog' => \&CMS::WebHandler::Blog);
get('/guides' => \&CMS::WebHandler::Guides);
get('/contact' => \&CMS::WebHandler::Contact);
#get('/about' => \&CMS::WebHandler::About);
get('/signin' => \&CMS::WebHandler::SignIn);
get('/profile' => \&CMS::WebHandler::Profile);
get('/post' => \&CMS::WebHandler::Post);


post('/signin' => \&CMS::WebHandler::SignInAction);
post('/signout' => \&CMS::WebHandler::SignOutAction);
post('/register' => \&CMS::WebHandler::RegisterAction);
post('/add_comment' => \&CMS::WebHandler::AddCommentAction);
post('/vote' => \&CMS::WebHandler::VoteAction);
post('/contact' => \&CMS::WebHandler::ContactAction);


$app->start('daemon', '-l', 'http://*:8083');

__DATA__
@@ not_found.html.ep
<!DOCTYPE html>
<html>
  <head><title>Page not found</title></head>
  <body>Page not found <%= $status %></body>
</html>
