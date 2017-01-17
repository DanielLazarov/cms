CREATE TABLE blog_posts (
    id SERIAL PRIMARY KEY,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    content TEXT NOT NULL,
    descr TEXT NOT NULL,
    title TEXT NOT NULL,
    views INT NOT NULL DEFAULT 0,
    sys_user_id INT NOT NULL REFERENCES sys_users,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    content TEXT NOT NULL,
    upvotes INT NOT NULL DEFAULT 0,
    downvotes INT NOT NULL DEFAULT 0,
    blog_post_id INT REFERENCES blog_posts,
    guide_post_id INT REFERENCES blog_posts,
    sys_user_id INT NOT NULL REFERENCES sys_users
);

CREATE TABLE vote_types (
    id INT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO vote_types VALUES(10, 'Upvote');
INSERT INTO vote_types VALUES(20, 'Downvote');

CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    type_id INT NOT NULL REFERENCES vote_types,
    blog_post_id INT REFERENCES blog_posts,
    guide_post_id INT REFERENCES blog_posts,
    sys_user_id INT NOT NULL REFERENCES sys_users
);

CREATE TABLE guide_levels (
    id INT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

INSERT INTO guide_levels VALUES(10, 'Begginer');
INSERT INTO guide_levels VALUES(20, 'Intermidate');
INSERT INTO guide_levels VALUES(30, 'Advanced');

CREATE TABLE guides (
    id SERIAL PRIMARY KEY,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    content TEXT NOT NULL,
    descr TEXT NOT NULL,
    title TEXT NOT NULL,
    views INT NOT NULL DEFAULT 0,
    upvotes INT NOT NULL DEFAULT 0,
    downvotes INT NOT NULL DEFAULT 0,
    sys_user_id INT NOT NULL REFERENCES sys_users,
    level_id INT NOT NULL REFERENCES guide_levels
);
