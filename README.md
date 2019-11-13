<p align="center"><a href="https://github.com/crazy-max/docker-pure-ftpd" target="_blank"><img height="128" src="https://raw.githubusercontent.com/crazy-max/docker-pure-ftpd/master/.res/docker-pure-ftpd.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/crazymax/pure-ftpd/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/crazy-max/docker-pure-ftpd?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/crazy-max/docker-pure-ftpd/actions?workflow=build"><img src="https://github.com/crazy-max/docker-pure-ftpd/workflows/build/badge.svg" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/pure-ftpd/"><img src="https://img.shields.io/docker/stars/crazymax/pure-ftpd.svg?style=flat-square" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/pure-ftpd/"><img src="https://img.shields.io/docker/pulls/crazymax/pure-ftpd.svg?style=flat-square" alt="Docker Pulls"></a>
  <a href="https://www.codacy.com/app/crazy-max/docker-pure-ftpd"><img src="https://img.shields.io/codacy/grade/f897b01327ba4b4c9fcb23e33c0a65b6.svg?style=flat-square" alt="Code Quality"></a>
  <br /><a href="https://github.com/sponsors/crazy-max"><img src="https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square" alt="Become a sponsor"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square" alt="Donate Paypal"></a>
</p>

## About

🐳 [Pure-FTPd](https://www.pureftpd.org/) Docker image based on Alpine Linux with MySQL, PostgreSQL and LDAP support.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other 🐳 Docker images!

💡 Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun) project!

## Features

* Multi-platform image
* [PureDB](#puredb-authentication-method), [MySQL](#mysql-authentication-method), [PostgreSQL](examples/postgresql) and LDAP support
* Latest [Pure-FTPd](https://github.com/jedisct1/pure-ftpd) release compiled from source
* Support of `argon2` and `scrypt` hashing method through [Libsodium](https://libsodium.org/)
* Logs processed to `stdout` through syslog-ng
* `PASSIVE_IP` for PASV support automatically resolved

## Docker

### Multi-platform image

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery crazymax/pure-ftpd:latest
Image: crazymax/pure-ftpd:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/386
   - linux/ppc64le
   - linux/s390x
```

### Environment variables

* `TZ` : Timezone assigned to the container (default `UTC`)
* `AUTH_METHOD` : Authentication method to use. Can be `puredb`, `mysql`, `pgsql` or `ldap` (default `puredb`)
* `SECURE_MODE` : Enable [secure mode](#secure-mode) (default `true`)
* `PASSIVE_IP` : IP/Host for PASV support (default auto resolved with `dig +short myip.opendns.com @resolver1.opendns.com`)
* `DB_TIMEOUT` : Time in seconds after which we stop trying to reach the database server. Only used for `mysql` and `pgsql` auth method (default `45`)

### Volumes

* `/data` : Contains config files and PureDB file

### Ports

* `2100` : FTP port
* `30000-30009` : PASV port range

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following [docker compose template](examples/puredb/docker-compose.yml), then run the container:

```bash
docker-compose up -d
docker-compose logs -f
```

### Command line

You can also use the following minimal command:

```bash
$ docker run -d --name pure-ftpd \
  -p 2100:2100 \
  -p 30000-30009:30000-30009 \
  -e "TZ=Europe/Paris" \
  -v $(pwd)/data:/data \
  crazymax/pure-ftpd
```

## Update

Recreate the container whenever I push an update:

```bash
docker-compose pull
docker-compose up -d
```

## Notes

### Flags

This image uses flags instead of the configuration file to set Pure-FTPd. Some [flags are forced](entrypoint.sh#L28-L34) but you can pass additional flags in `/data/pureftpd.flags` file:

```
-d
-d
--maxclientsperip 5
--minuid 100
--limitrecursion 10000:3
```

### Secure mode

`SECURE_MODE` enables [specially crafted flags](entrypoint.sh#L40-L52) to enforced security of Pure-FTPd.

### PureDB authentication method

Using [PureDB](examples/puredb) authentication method, the container will create a blank password file in `/data/pureftpd.passwd` and a initialize a PureDB database in `/data/pureftpd.pdb`. If a password file is already available, it will be read on startup and the PureDB database will be updated.

At first execution of the container no user will be available and you will have to create one:

```
$ docker-compose exec pureftpd pure-pw useradd foo -u 1003 -g 1005 -d /home/foo -m
Password:
Enter it again:
$ docker-compose exec pureftpd pure-pw list
foo                 /home/foo/./
$ cat ./data/pureftpd.passwd
foo:$2a$10$Oqn7I2P7YaGxQrtuydcDKuxmCJqPR7a79EeDy2gChyOGEnYA4UIPK:1003:1005::/home/foo/./::::::::::::
```
> User `foo` will be created with uid `1003`, gid `1005` with his home directory located at `/home/foo`. The password will be asked after.
> More info about local users database: https://github.com/jedisct1/pure-ftpd/blob/master/README.Virtual-Users

### Persist FTP user home

Looking at the previous example, don't forget to persist the home directory through a [named or bind mounted volume](https://docs.docker.com/storage/volumes/) like:

```bash
version: "3.2"

services:
  pureftpd:
    image: crazymax/pure-ftpd
    container_name: pureftpd
    ports:
      - "2100:2100"
      - "30000-30009:30000-30009"
    volumes:
      - "./data:/data"
      - "./foo:/home/foo"
    environment:
      - "TZ=Europe/Paris"
      - "AUTH_METHOD=puredb"
    restart: always
```

### MySQL authentication method

A [quick example](examples/mariadb) to use MySQL authentication method is also available using a MariaDB container. Before using starting the container, a [MySQL configuration file](examples/mariadb/data/pureftpd-mysql.conf) must be available in `/data/pureftpd-mysql.conf`.

In the [docker compose example](examples/mariadb) available, the database and the [users table](examples/mariadb/users.sql) will be created at first launch.

To create your first user you can use this one line command:

```
$ docker-compose exec db mysql -u pureftpd -p'asupersecretpassword' -e "INSERT INTO users (User,Password,Uid,Gid,Dir) VALUES ('foo',ENCRYPT('test'),'1003','1005','/home/foo');" pureftpd
$ docker-compose exec db mysql -u pureftpd -p'asupersecretpassword' -e "SELECT * FROM users;" pureftpd
+------+---------------+------+------+-----------+
| User | Password      | Uid  | Gid  | Dir       |
+------+---------------+------+------+-----------+
| foo  | Oo4cJdd1HNVA6 | 1003 | 1005 | /home/foo |
+------+---------------+------+------+-----------+
```
> User `foo` will be created with uid `1003`, gid `1005` with his home directory located at `/home/foo`. Here we assume `crypt` is the `MySQLCrypt` method and the password `test` is hashed using crypt.
> More info about MySQL authentication method: https://github.com/jedisct1/pure-ftpd/blob/master/README.MySQL

### PostgreSQL authentication method

Like MySQL, there is also a [quick example](examples/postgresql) to use PostgreSQL authentication method using a PostgreSQL container. And also before starting the container, a [PostgreSQL configuration file](examples/postgresql/data/pureftpd-pgsql.conf) must be available in `/data/pureftpd-pgsql.conf`.

In the [docker compose example](examples/postgresql) available, the database and the [users table](examples/postgresql/users.sql) will be also created at first launch.

> More info about PostgreSQL authentication method: https://github.com/jedisct1/pure-ftpd/blob/master/README.PGSQL

### Logs

Logs are displayed through `stdout` using syslog-ng. You can increase verbosity with `-d -d` flags.

```
$ docker-compose logs -f pureftpd
Attaching to pureftpd
pureftpd    | Use MySQL authentication method
pureftpd    | Waiting 45s for MySQL database to be ready...
pureftpd    | MySQL database ready!
pureftpd    | Flags
pureftpd    |   Secure: --maxclientsnumber 5 --maxclientsperip 5 --antiwarez --customerproof --dontresolve --norename --prohibitdotfilesread --prohibitdotfileswrite
pureftpd    |   Additional: -d -d
pureftpd    |   All: -d -d --bind 0.0.0.0,2100 --ipv4only --passiveportrange 30000:30009 --noanonymous --createhomedir --nochmod --syslogfacility ftp --forcepassiveip 10.0.0.5 --maxclientsnumber 5 --maxclientsperip 5 --antiwarez --customerproof --dontresolve --norename --prohibitdotfilesread --prohibitdotfileswrite --login mysql:/data/pureftpd-mysql.conf
pureftpd    | 2019-10-30 02:56:30,557 INFO Included extra file "/etc/supervisord/pure-ftpd.conf" during parsing
pureftpd    | 2019-10-30 02:56:30,557 INFO Included extra file "/etc/supervisord/syslog-ng.conf" during parsing
pureftpd    | 2019-10-30 02:56:30,557 INFO Set uid to user 0 succeeded
pureftpd    | 2019-10-30 02:56:30,560 INFO supervisord started with pid 1
pureftpd    | 2019-10-30 02:56:31,563 INFO spawned: 'syslog-ng' with pid 20
pureftpd    | 2019-10-30 02:56:31,566 INFO spawned: 'pure-ftpd' with pid 21
pureftpd    | 2019-10-30 02:56:32,582 INFO success: syslog-ng entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
pureftpd    | 2019-10-30 02:56:32,583 INFO success: pure-ftpd entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [INFO] New connection from 10.0.0.1
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] 220---------- Welcome to Pure-FTPd [privsep] [TLS] ----------
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] 220-You are user number 1 of 5 allowed.
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] 220-Local time is now 02:56. Server port: 2100.
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] 220-This is a private system - No anonymous login
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] 220 You will be disconnected after 15 minutes of inactivity.
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] Command [user] [foo]
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] 331 User foo OK. Password required
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [DEBUG] Command [pass] [<*>]
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (?@10.0.0.1) [INFO] foo is now logged in
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (foo@10.0.0.1) [DEBUG] 230 OK. Current directory is /home/foo
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (foo@10.0.0.1) [DEBUG] Command [syst] []
pureftpd    | Oct 30 02:56:53 04b6e4ca4116 pure-ftpd: (foo@10.0.0.1) [DEBUG] 215 UNIX Type: L8
...
```

## How can I help ?

All kinds of contributions are welcome :raised_hands:! The most basic way to show your support is to star :star2: the project, or to raise issues :speech_balloon: You can also support this project by [**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) :clap: or by making a [Paypal donation](https://www.paypal.me/crazyws) to ensure this journey continues indefinitely! :rocket:

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
