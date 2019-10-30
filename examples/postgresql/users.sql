-- https://github.com/jedisct1/pure-ftpd/blob/master/pureftpd-pgsql.conf
CREATE TABLE "users" (
  "User" TEXT NOT NULL,
  "Password" TEXT NOT NULL,
  "Uid" INTEGER NOT NULL default '-1',
  "Gid" INTEGER NOT NULL default '-1',
  "Dir" TEXT NOT NULL,
  PRIMARY KEY ("User")
) WITHOUT OIDS;