package CMS::Utils;

use warnings;
use strict;

use DBI;

sub CreateDBConnection()
{
    my $dbh = DBI->connect("DBI:Pg:dbname=cms;host=localhost;port=5432", "cmssite", "123", {RaiseError => 1, AutoCommit => 1});
    $dbh->{pg_enable_utf8} = 1;

    return $dbh; 
}

sub GetBlogPosts($;$)
{
    my ($dbh, $count) = @_;

    $count //= 20;

    my $sth = $dbh->prepare(q{
        SELECT * 
        FROM blog_posts_vw
        ORDER BY inserted_at desc
        LIMIT ?
    });

    $sth->execute($count);

    my @results;

    while(my $row = $sth->fetchrow_hashref)
    {
        push @results, $row;
    }

    return \@results;
}

sub GetBlogPostByID($$)
{
    my ($dbh, $id) = @_;

    my $sth = $dbh->prepare(q{
        SELECT *
        FROM blog_posts_vw
        WHERE id = ?
    });

    $sth->execute($id);

    my $row = $sth->fetchrow_hashref;

    return $row;
}  

sub GetCommentsByPostID($$)
{
    my ($dbh, $id) = @_;

    my $sth = $dbh->prepare(q{
        SELECT C.*,
            SU.first_name AS sys_user_id__first_name,
            SU.last_name AS sys_user_id__last_name
        FROM comments C
            JOIN sys_users SU ON C.sys_user_id = SU.id
        WHERE blog_post_id = ?
        ORDER BY C.inserted_at
    });
    $sth->execute($id);

    my @result;
    while(my $row = $sth->fetchrow_hashref)
    {
        push @result, $row;
    }

    return \@result;
} 

sub GetPostVotesCountByPostID($$$$)
{
    my ($dbh, $blog_id, $guide_id, $type) = @_;

    my $sth = $dbh->prepare(q{
        SELECT count(*) AS "count"
        FROM votes
        WHERE ((blog_post_id = ? and guide_post_id is null ) or (blog_post_id is null and guide_post_id = ? ))
          AND type_id = ?
    });
    $sth->execute($blog_id, $guide_id, $type);
    
    my $row = $sth->fetchrow_hashref;

    return $$row{count};
} 
1;
