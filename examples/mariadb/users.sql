# https://github.com/jedisct1/pure-ftpd/blob/master/pureftpd-mysql.conf
CREATE TABLE users (
  User VARCHAR(255) BINARY NOT NULL,
  Password VARCHAR(255) BINARY NOT NULL,
  Uid INT NOT NULL default '-1',
  Gid INT NOT NULL default '-1',
  Dir VARCHAR(255) BINARY NOT NULL,
  PRIMARY KEY (User)
);