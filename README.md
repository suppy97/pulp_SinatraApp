# Pulp_SinatraApp
##  機能の説明
ファイル名　機能概要にpgf形式で詳細画像がございます

## データベースの準備
データベース名　CODEBASE_Sinatra
## テーブル
* CREATE TABLE users (
id INT( 5 ) NOT NULL AUTO_INCREMENT PRIMARY KEY ,
name VARCHAR( 25 ) NOT NULL ,
email VARCHAR( 35 ) NOT NULL ,
password VARCHAR( 60 ) NOT NULL ,
UNIQUE (email)
);
* CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INT( 5 ) NOT NULL,
  user_name VARCHAR( 25 ) NOT NULL ,
  title varchar(255),
  description varchar(255),
  image_path varchar(255),
  created_at date NOT NULL,
  updated_at date NOT NULL
);
* CREATE TABLE comments(
    user_name VARCHAR( 25 ) NOT NULL ,
    body text,
  created_at date NOT NULL,
  posts_id INT( 5 ) NOT NULL
);
* CREATE TABLE save(
    user_id INT( 5 ) NOT NULL,
    post_id INT( 5 ) NOT NULL,
    post_title varchar(255),
    Image_path varchar(255)
);
* CREATE TABLE likes(
  id INT( 5 ) NOT NULL AUTO_INCREMENT PRIMARY KEY ,
    post_id INT( 5 ) NOT NULL,
    user_id INT( 5 ) NOT NULL
);
* CREATE TABLE topics(
    id INT( 5 ) NOT NULL AUTO_INCREMENT PRIMARY KEY ,
    post_id INT( 5 ) NOT NULL,
    user_id INT( 5 ) NOT NULL,
    post_title varchar(255),
    image_path varchar(255)
);
