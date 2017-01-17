package PerlLib::Security::Security;
use strict;

use DBI;
use Data::Dumper;
use Digest::SHA qw(sha256_hex);

use PerlLib::Security::Config;

use PerlLib::Errors::Errors;


sub createUser($$)
{
    my ($dbh, $params) = @_;

    ASSERT(defined $dbh, "Undefined app");
    
    ASSERT(defined $$PerlLib::Security::Config::CONSTS{MIN_PW_LENGTH}, "Undefined Config: MIN_PW_LENGTH");
    ASSERT(defined $$PerlLib::Security::Config::CONSTS{MAX_PW_LENGTH}, "Undefined Config: MAX_PW_LENGTH");
    ASSERT(defined $$PerlLib::Security::Config::CONSTS{PEPPER}, "Undefined Config: PEPPER");

    ASSERT_USER(defined $$params{username}, "Missing username");
    ASSERT_USER(defined $$params{password}, "Missing password");
    ASSERT_USER(defined $$params{email}, "Missing email");
    ASSERT_USER(defined $$params{first_name}, "Missing first_name");
    ASSERT_USER(defined $$params{last_name}, "Missing last_name");

    ASSERT_USER(length $$params{password} >= $$PerlLib::Security::Config::CONSTS{MIN_PW_LENGTH} 
                    && length $$params{password} <= $$PerlLib::Security::Config::CONSTS{MAX_PW_LENGTH}
                , "Password length should be betwean $$PerlLib::Security::Config::CONSTS{MIN_PW_LENGTH} and $$PerlLib::Security::Config::CONSTS{MAX_PW_LENGTH} characters");

    my $sth = $dbh->prepare(q{
        SELECT *
        FROM sys_users
        WHERE username = ?
           OR email = ?    
    });
    $sth->execute($$params{username}, $$params{email});
    ASSERT_USER($sth->rows == 0, "Username or Email already taken", "S04");

    my $salt = sha256_hex(rand . localtime . rand);
    my $password_sha = sha256_hex($salt . $$params{password} . $$PerlLib::Security::Config::CONSTS{PEPPER});
    
    $sth = $dbh->prepare(q{
        INSERT INTO sys_users(username, password, email, salt, first_name, last_name)
        VALUES(?, ?, ?, ?, ?, ?)
        RETURNING *
    });
    $sth->execute($$params{username}, $password_sha, $$params{email}, $salt, $$params{first_name}, $$params{last_name});
    ASSERT($sth->rows == 1);

    my $row = $sth->fetchrow_hashref;
    
    return $row;
}

sub checkLogin($$$)
{
    my ($dbh, $username, $password) = @_;

    ASSERT(defined $$PerlLib::Security::Config::CONSTS{PEPPER}, "Undefined Config: PEPPER");
    
    ASSERT_USER(defined $username, "No username specified", "S01"); 
    ASSERT_USER(defined $password, "No password specified", "S02");

    my $sth = $dbh->prepare(q{
        SELECT *
        FROM sys_users 
        WHERE username = ?
    });
    $sth->execute($username);
    ASSERT($sth->rows <= 1);

    ASSERT_USER($sth->rows == 1, "Incorrect Username or Password", "S03");
    my $row = $sth->fetchrow_hashref;

    ASSERT_USER(sha256_hex($$row{salt} . $password . $$PerlLib::Security::Config::CONSTS{PEPPER}) eq $$row{password}, "Incorrect Username or Password", "S03");

    return $row;
}

sub createSession($$;$)
{
    my ($dbh, $sys_user_id, $expiration_min) = @_;

    $expiration_min = $expiration_min // $$PerlLib::Security::Config::CONSTS{SESSION_EXPIRATION_MINUTES};

    my $sth = $dbh->prepare(q{
        INSERT INTO sys_users_sessions(sys_user_id, expires_at)
        VALUES(?, now() + ?::interval) RETURNING *
    });
    $sth->execute($sys_user_id, "$expiration_min minutes");
    ASSERT($sth->rows == 1);
    my $row = $sth->fetchrow_hashref;

    return $row;
}

sub refreshSessionToken($$)
{
    my ($dbh, $session_token) = @_;

    my $sth = $dbh->prepare(q{
        UPDATE sys_users_sessions 
        SET session_id = md5(random()::text || now()::text || random()::text)
        WHERE session_id = ?
        RETURNING *
    });
    $sth->execute($session_token);
    ASSERT($sth->rows == 1);
    
    my $result_row = $sth->fetchrow_hashref;

    return $$result_row;
}

sub checkSession($$$)
{
    my ($dbh, $username, $session_token) = @_;
    
    my $sth = $dbh->prepare(q{
        SELECT SUS.*
        FROM sys_users_sessions SUS
            JOIN sys_users SU ON SUS.sys_user_id = SU.id
        WHERE SU.username = ?
          AND SUS.session_id = ?
          AND (SUS.expires_at IS NULL OR SUS.expires_at > now())
    });
    $sth->execute($username, $session_token);
    
    if($sth->rows > 0)
    {
        my $row = $sth->fetchrow_hashref;
        
        return $row;
    }
    else
    {
        return undef;
    }
}

sub expireSession($$)
{
    my ($dbh, $session_token) = @_;

    my $sth = $dbh->prepare(q{
        UPDATE sys_users_sessions
            SET expires_at = now() 
        WHERE session_id = ?
    });
    $sth->execute($session_token);
    ASSERT($sth->rows == 1);

    return $session_token;
}

1;

