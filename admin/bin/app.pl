#!/usr/bin/env perl
use strict;

use lib q{/usr/share/cms/admin/lib/perl};
use lib q{/usr/share/cms/libs};

use Mojolicious::Lite;

use CMS::WebHandler;

my $app = app;
push @{$app->renderer->paths}, '/usr/share/cms/admin/templates/';


my $static = $app->static();
push @{$static->paths}, '/usr/share/cms/admin/pub/';



get('/' => \&CMS::WebHandler::Home);
get('/home' => \&CMS::WebHandler::Home);
get('/blog_posts' => \&CMS::WebHandler::BlogPosts);
get('/cu_blog_post' => \&CMS::WebHandler::CreateOrUpdateBlogPost);

post('/signin' => \&CMS::WebHandler::SignInAction);
post('/signout' => \&CMS::WebHandler::SignOutAction);
post('/cu_blog_post' => \&CMS::WebHandler::CreateOrUpdateBlogPostAction);

$app->start('daemon', '-l', 'http://*:8084');

__DATA__
@@ not_found.html.ep
<!DOCTYPE html>
<html>
  <head><title>Page not found</title></head>
  <body>Page not found <%= $status %></body>
</html>
