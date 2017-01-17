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

    my $featured_guides = [
        {id => 1, title => 'Cruising concepts'},
        {id => 2, title => 'Freestyle concepts'},
        {id => 3, title => 'Freeride concepts'},
        {id => 4, title => 'Downhill concepts'}
    ];

    
    my $dbh = CMS::Utils::CreateDBConnection();

    my $latest_blog_posts = CMS::Utils::GetBlogPosts($dbh, 2);

    my $render_params = {
        current_user => 'Sign IN',
        current_user_action => 'signin',
        featured_guides => $featured_guides,
        latest_blog_posts => $latest_blog_posts
    };

    my $current_user = $mojo->session('user');

    if($current_user)
    {
        $$render_params{current_user} = $$current_user{first_name};
        $$render_params{current_user_action} = 'profile';         
    } 

    $mojo->render(template => 'home', %$render_params);
}

sub SignIn($;$)
{
    my ($mojo, $params) = @_;
    
    my $render_params = {
        username => $mojo->param('username') || '',
        current_user => 'Sign IN',
        current_user_action => 'signin',
        is_fail_login => $$params{is_fail_login} // 0,
        fail_login_msg => $$params{fail_login_msg} // '',
        sign_in_display => $$params{sign_in_display} // 'block',

        is_fail_register => $$params{is_fail_register} // 0,
        fail_register_msg => $$params{fail_register_msg} // '',
        register_display => $$params{register_display} // 'none',

        email => $mojo->param('email') || '',
        first_name => $mojo->param('first_name') || '',
        last_name => $mojo->param('last_name') || ''
    };

    $mojo->render(template => 'signin', %$render_params);
}

sub Profile($)
{
    my ($mojo) = @_;

    my $render_params = {};

    my $current_user = $mojo->session('user');
    if($current_user)
    {
        $$render_params{current_user} = $$current_user{first_name};
        $$render_params{current_user_action} = 'profile';
    }
    else
    {
        #If session is already expired, redirect to home
        $mojo->redirect_to('/');
    }

    $mojo->render(template => 'profile', %$render_params);
}

sub Blog($)
{
    my ($mojo) = @_;
   
    my $dbh = CMS::Utils::CreateDBConnection();

    my $blog_posts = CMS::Utils::GetBlogPosts($dbh);

    my $random_posts = [];
    
    #Max 2 random postst
    my $random_posts_count = 2;
    if(scalar @$blog_posts < $random_posts_count)
    {
        $random_posts_count = scalar @$blog_posts;
    }

    #Get random poststs without dublicating
    my %random_ids;
    for(my $i = 0; $i < $random_posts_count; $i++)
    {
        my $rand;
        while(1)
        {
            $rand = int rand(scalar @$blog_posts);
            if( ! exists $random_ids{$rand})
            {
                push @$random_posts, $$blog_posts[$rand];
                $random_ids{$rand} = 1;
                last;
            }
        }
    }

    my $featured_post = $$blog_posts[1];

    my $render_params = {
        current_user => 'Sign IN',
        current_user_action => 'signin',
        blog_posts => $blog_posts,
        random_posts => $random_posts,
        featured_post => $featured_post
    };

    my $current_user = $mojo->session('user');

    if($current_user)
    {
        $$render_params{current_user} = $$current_user{first_name};
        $$render_params{current_user_action} = 'profile';
    }

    $mojo->render(template => 'blog', %$render_params);
}

sub Post($)
{
    my ($mojo) = @_;
   
    my $dbh = CMS::Utils::CreateDBConnection();

    my $blog_post = CMS::Utils::GetBlogPostByID($dbh, $mojo->param('id'));
    my $post_comments = CMS::Utils::GetCommentsByPostID($dbh, $$blog_post{id});
    my $upvotes_count = CMS::Utils::GetPostVotesCountByPostID($dbh, $$blog_post{id}, undef,  10); 
    my $downvotes_count = CMS::Utils::GetPostVotesCountByPostID($dbh, $$blog_post{id}, undef, 20);


    my $blog_posts = CMS::Utils::GetBlogPosts($dbh); 
    my $random_posts = [];
    
    #Max 2 random postst
    my $random_posts_count = 2;
    if(scalar @$blog_posts < $random_posts_count)
    {
        $random_posts_count = scalar @$blog_posts;
    }

    #Get random poststs without dublicating
    my %random_ids;
    for(my $i = 0; $i < $random_posts_count; $i++)
    {
        my $rand;
        while(1)
        {
            $rand = int rand(scalar @$blog_posts);
            if( ! exists $random_ids{$rand})
            {
                push @$random_posts, $$blog_posts[$rand];
                $random_ids{$rand} = 1;
                last;
            }
        }
    }
    
    my $featured_post = $$blog_posts[0];
 
    my $render_params = {
        current_user => 'Sign IN',
        current_user_action => 'signin',
        post => $blog_post,
        post_comments => $post_comments,
        upvotes_count => $upvotes_count // 0,
        downvotes_count => $downvotes_count // 0,    
        random_posts => $random_posts,
        featured_post => $featured_post
    };

    my $current_user = $mojo->session('user');

    if($current_user)
    {
        $$render_params{current_user} = $$current_user{first_name};
        $$render_params{current_user_action} = 'profile';
    }

    $mojo->render(template => 'post', %$render_params);
}

sub Guides($)
{
    my ($mojo) = @_;
     
    my $render_params = {
        current_user => 'Sign IN',
        current_user_action => 'signin',
    };

    my $current_user = $mojo->session('user');

    if($current_user)
    {
        $$render_params{current_user} = $$current_user{first_name};
        $$render_params{current_user_action} = 'profile';         
    } 

    $mojo->render(template => 'guides', %$render_params);
}

sub Contact($;$)
{
    my ($mojo, $params) = @_;
    
    my $render_params = {
        current_user => 'Sign IN',
        current_user_action => 'signin',
        current_user_name => '',
        current_user_email => '',
        success => $$params{success} // 0
    };

    my $current_user = $mojo->session('user');

    if($current_user)
    {
        $$render_params{current_user} = $$current_user{first_name};
        $$render_params{current_user_action} = 'profile';         
        $$render_params{current_user_name} = $$current_user{first_name} . " " . $$current_user{last_name};
        $$render_params{current_user_email} = $$current_user{email};
    } 

    $mojo->render(template => 'contact', %$render_params);
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

        #Create server session with user details        
        $mojo->session({user => $user});

        #Redirect to home
        $mojo->redirect_to('/');
    }
    catch
    {
        my ($err) = @_;

        #Return signIn page with err message
        SignIn($mojo, {
                is_fail_login => 1, 
                fail_login_msg => $$err{msg},
                sign_in_display => 'block',

                is_fail_register => 0, 
                fail_register_msg => '',
                register_display => 'none'
            }
        );
    };
}

sub SignOutAction($)
{
    my ($mojo) = @_;
    
    #Expire session
    $mojo->session(expires => -1);

    #Redirrect to home
    $mojo->redirect_to('/');
}

sub RegisterAction($)
{
    my ($mojo) = @_;

    try
    {
        ASSERT_USER(defined $mojo->param('username') && $mojo->param('username') ne '', 'Username is required');
        ASSERT_USER(defined $mojo->param('password') && $mojo->param('password') ne '', 'Password is required');
        ASSERT_USER(defined $mojo->param('confirm_password') && $mojo->param('confirm_password') ne '', 'Confirm password is required');
        ASSERT_USER(defined $mojo->param('email') && $mojo->param('email') ne '', 'Email is required');
        ASSERT_USER(defined $mojo->param('first_name') && $mojo->param('first_name') ne '', 'First is required');
        ASSERT_USER(defined $mojo->param('last_name') && $mojo->param('last_name') ne '', 'Last name is required');

        ASSERT_USER($mojo->param('password') eq  $mojo->param('confirm_password'), 'Password confirmation missmatch');

        my $dbh = CMS::Utils::CreateDBConnection(); 

        #Check login
        my $user = PerlLib::Security::Security::createUser($dbh, {
                username => $mojo->param('username'),
                password => $mojo->param('password'),
                email => $mojo->param('email'),
                first_name => $mojo->param('first_name'),
                last_name => $mojo->param('last_name')
            }
        );

        #Create server session with user details        
        $mojo->session({user => $user});

        #Redirect to home
        $mojo->redirect_to('/');
    }
    catch
    {
        my ($err) = @_;

        #Return signIn page with err message
        SignIn($mojo, {
                is_fail_login => 0, 
                fail_login_msg => '',
                sign_in_display => 'none',

                is_fail_register => 1, 
                fail_register_msg => $$err{msg},
                register_display => 'block'
            }
        );
    };
}

sub AddCommentAction($)
{
    my ($mojo) = @_;

    my $dbh = CMS::Utils::CreateDBConnection();

    my $current_user = $mojo->session('user');

    my $sth = $dbh->prepare(q{
        INSERT INTO comments(content, blog_post_id, guide_post_id, sys_user_id)
        VALUES(?, ?, ?, ?)
    });

    $sth->execute($mojo->param('content'), $mojo->param('blog_post_id'), $mojo->param('guide_post_id'), $$current_user{id} );

    $mojo->redirect_to('/post?id=' . $mojo->param('blog_post_id') // $mojo->param('guide_post_id'));
}

sub VoteAction($)
{
    my ($mojo) = @_;

    my $dbh = CMS::Utils::CreateDBConnection();

    my $current_user = $mojo->session('user');
    my $sth = $dbh->prepare(q{
        INSERT INTO votes(type_id, blog_post_id, guide_post_id, sys_user_id)
        VALUES(?, ?, ?, ?)
    });

    $sth->execute($mojo->param('type'), $mojo->param('blog_post_id'), $mojo->param('guide_post_id'), $$current_user{id} );

    $mojo->redirect_to('/post?id=' . $mojo->param('blog_post_id') // $mojo->param('guide_post_id'));
}

sub ContactAction($)
{
    my ($mojo) = @_;

    my $dbh = CMS::Utils::CreateDBConnection();

    my $sth = $dbh->prepare(q{
        INSERT INTO contact_entries(client_name, client_email, subject, content)
        VALUES(?, ?, ?, ?)
    });

    $sth->execute($mojo->param('client_name'), $mojo->param('client_email'), $mojo->param('subject'), $mojo->param('content') );

    Contact($mojo, {success => 1});
}

1;
