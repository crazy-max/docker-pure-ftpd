# Changelog

## 1.0.49-RC9 / 1.0.47-RC6 (2020/05/21)

* Switch to [s6-overlay](https://github.com/just-containers/s6-overlay/) as process supervisor
* No need pam support

## 1.0.49-RC8 / 1.0.47-RC5 (2020/04/24)

* Don't keep timestamp on syslog-ng (#5)

## 1.0.49-RC7 / 1.0.47-RC4 (2020/04/24)

* Fix timezone (#5)
* Switch to Open Container Specification labels as label-schema.org ones are deprecated

## 1.0.49-RC6 / 1.0.47-RC3 (2020/03/23)

* Typo (#3)

## 1.0.49-RC5 / 1.0.47-RC2 (2019/12/28)

* Add `PASSIVE_PORT_RANGE` env var
* Alpine 3.11

## 1.0.49-RC4 (2019/11/30)

* Back to Pure-FTPd 1.0.49

## 1.0.48-RC1 (2019/11/30)

* Pure-FTPd 1.0.48
* Charset conversion not supported anymore (see jedisct1/pure-ftpd@33eda76)

## 1.0.47-RC1 (2019/11/30)

* Pure-FTPd 1.0.47
* Enable support for charset conversion

## 1.0.49-RC3 (2019/11/30)

* Enable cookie support
* Enable upload script support
* Remove useless inetd support

## 1.0.49-RC2 (2019/11/23)

* Better handling of TLS connection

## 1.0.49-RC1 (2019/10/30)

* Initial version based on Pure-FTPd 1.0.49
