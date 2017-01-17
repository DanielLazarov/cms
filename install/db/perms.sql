GRANT SELECT, INSERT, UPDATE ON sys_users TO cmssite;
GRANT USAGE ON sys_users_id_seq TO cmssite;

GRANT SELECT ON blog_posts_vw TO cmssite;


GRANT SELECT, INSERT, UPDATE ON comments TO cmssite;
GRANT USAGE ON comments_id_seq TO cmssite;

GRANT SELECT, INSERT, UPDATE ON votes TO cmssite;
GRANT USAGE ON votes_id_seq TO cmssite;

