use warnings;
use strict;

use DBI;
use Try::Tiny;

use PerlLib::Security::Security;




sub printHelp()
{
    print "
    Usage:
        perl create_sys_user <username> <password>
    ";
}

if( ! defined $ARGV[0] || ! defined $ARGV[1])
{
    printHelp();
}
else
{
    my $dbh = DBI->connect("DBI:Pg:dbname=cms;host=localhost", "cmssite", "123", {RaiseError => 1, AutoCommit => 0});
    $dbh->{pg_enable_utf8} = 1;
    try
    {
        #TODO Consts in settings;

        PerlLib::Security::Security::createUser($dbh, {
                username => $ARGV[0],
                password => $ARGV[1],
                email => $ARGV[2],
                first_name => $ARGV[3],
                last_name => $ARGV[4]
            }
        );

        $dbh->commit();        
        print "Done.\n";
        $dbh->disconnect();
    }
    catch
    {
        my $err = shift;
        if($dbh)
        {
            $dbh->rollback();
            $dbh->disconnect();
        }
        print "ERR: " . $$err{msg} . " " . $$err{code} . "\n";
    };
    
}
