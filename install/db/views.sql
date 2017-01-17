DROP VIEW blog_posts_vw;
CREATE VIEW blog_posts_vw AS (
    SELECT *,
        to_char(inserted_at, 'Month DD, YYYY') inserted_at_format
    FROM blog_posts
);
