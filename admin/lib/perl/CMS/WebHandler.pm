package CMS::WebHandler;

use warnings;
use strict;

use Try::Tiny;
use Data::Dumper;

use PerlLib::Security::Security;
use PerlLib::Errors::Errors;

use CMS::Utils;

sub Home($;$)
{
    my ($mojo, $params) = @_;

    my $render_params = {
        current_user => '',
        logged_in => 0,
        err_msg => $$params{err_msg} // ''
    };

    my $current_user = $mojo->session('user');

    if($current_user && $$current_user{is_admin})
    {
        $$render_params{current_user} = $$current_user{username};
        $$render_params{logged_in} = 1;
    } 

    $mojo->render(template => 'home', %$render_params);
}

sub BlogPosts($)
{
    my ($mojo) = @_;
   
    my $current_user = $mojo->session('user');
    
    if($current_user  && $$current_user{is_admin})
    {
        my $dbh = CMS::Utils::CreateDBConnection();

        my $blog_posts = CMS::Utils::GetBlogPosts($dbh);
    
        my $render_params = {
            current_user => $$current_user{username},
            logged_in => 1,
            blog_posts => $blog_posts
        };

        $mojo->render(template => 'blog_posts', %$render_params);
    }
    else
    {
        $mojo->redirect_to('/home');       
    } 
}

sub CreateOrUpdateBlogPost($)
{
    my ($mojo) = @_;
   
    my $current_user = $mojo->session('user');   
    
    if($current_user  && $$current_user{is_admin})
    {
        my $dbh = CMS::Utils::CreateDBConnection();

        my $blog_post = {};
        if(defined $mojo->param('id'))
        {
            $blog_post = CMS::Utils::GetBlogPostByID($dbh, $mojo->param('id'));
        }
        
        my $render_params = {
            current_user => $$current_user{username},
            logged_in => 1,
            blog_post => $blog_post
        };
        
        $mojo->render(template => 'cu_blog_post', %$render_params);
    }
    else
    {
        $mojo->redirect_to('/home');       
    } 
}
sub CreateOrUpdateBlogPostAction($)
{
    my ($mojo) = @_;

    my $current_user = $mojo->session('user');

    if($current_user && $$current_user{is_admin})
    {

        my $dbh = CMS::Utils::CreateDBConnection();

        my $row;
        if($mojo->param('id'))
        {
            my $sth = $dbh->prepare(q{
                UPDATE blog_posts set title = ?, descr = ?, content = ?
                WHERE id = ?
                RETURNING *
            });
            $sth->execute($mojo->param('title'), $mojo->param('descr'), $mojo->param('content'), $mojo->param('id'));
            $row = $sth->fetchrow_hashref;
        }
        else
        {
            my $sth = $dbh->prepare(q{
                INSERT INTO blog_posts(title, descr, content, sys_user_id) 
                    VALUES(?,?,?,?)
                RETURNING *
            });
            $sth->execute($mojo->param('title'), $mojo->param('descr'), $mojo->param('content'), $$current_user{id});
            $row = $sth->fetchrow_hashref;
        }

        my $title_image = $mojo->req->upload('title-image');
        if($title_image->size)
        {
            $title_image->move_to('/usr/share/cms/site/pub/images/blog-posts/' . $$row{id} . '-title.jpg');   
        }
        
        my $main_image = $mojo->req->upload('main-image');
        if($main_image->size)
        {
            $main_image->move_to('/usr/share/cms/site/pub/images/blog-posts/' . $$row{id} . '.jpg');   
        }

        $mojo->redirect_to('/blog_posts');       
    }
    else
    {
        $mojo->redirect_to('/home');       
    }
}

sub SignInAction($)
{
    my ($mojo) = @_;

    my $username = $mojo->param('username');
    my $password = $mojo->param('password');

    try
    {
        my $dbh = CMS::Utils::CreateDBConnection(); 

        #Check login
        my $user = PerlLib::Security::Security::checkLogin($dbh, $username, $password);
        ASSERT($$user{is_admin}, 'Incorrect Username or Password');

        #Create server session with user details        
        $mojo->session({user => $user});

        #Redirect to home
        $mojo->redirect_to('/home');
    }
    catch
    {
        my ($err) = @_;

        #Return home page with err message
        Home($mojo, {err_msg => $$err{msg}});
    };
}

sub SignOutAction($)
{
    my ($mojo) = @_;
    
    #Expire session
    $mojo->session(expires => -1);

    #Redirrect to home
    $mojo->redirect_to('/home');
}


1;
