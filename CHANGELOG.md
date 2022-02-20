# Changelog

## 1.0.50-r0 (2022/02/20)

* Pure-FTPd 1.0.50 (#45)
* Alpine Linux 3.15 (#44)

## 1.0.47-r18 (2022/02/20)

* Alpine Linux 3.15 (#44)

## 1.0.49-r20 / 1.0.47-r17 (2021/08/19)

* Alpine Linux 3.14 (#43)

## 1.0.49-r19 / 1.0.47-r16 (2021/06/04)

* Alpine Linux 3.13
* alpine-s6 2.2.0.3

## 1.0.49-r18 / 1.0.47-r15 (2021/03/19)

* Upstream Alpine update
* Disable socklog timestamp
* Publish to GHCR
* Switch to buildx bake (#33)
* Switch to Docker actions
* Remove support for `linux/s390x`

## 1.0.49-RC17 / 1.0.47-RC14 (2020/08/10)

* Now based on [Alpine Linux 3.12 with s6 overlay](https://github.com/crazy-max/docker-alpine-s6/)

## 1.0.49-RC16 / 1.0.47-RC13 (2020/07/27)

* Fix `pure-uploadscript` daemon (#18)

## 1.0.49-RC15 / 1.0.47-RC12 (2020/07/04)

* Fix missing `TARGET_PLATFORM` (#13)
* Alpine Linux 3.12

## 1.0.49-RC14 / 1.0.47-RC11 (2020/05/26)

* Fix Libsodium support (#9)

## 1.0.49-RC13 / 1.0.47-RC10 (2020/05/22)

* Fix parse error (#6)

## 1.0.49-RC12 / 1.0.47-RC9 (2020/05/22)

* Bring back finish script

## 1.0.49-RC11 / 1.0.47-RC8 (2020/05/22)

* Set `S6_BEHAVIOUR_IF_STAGE2_FAILS` behavior (#6)

## 1.0.49-RC10 / 1.0.47-RC7 (2020/05/21)

* Add finish script for s6 service (#6)
* Do not fail if `UPLOADSCRIPT` is empty

## 1.0.49-RC9 / 1.0.47-RC6 (2020/05/21)

* Support of `pure-uploadscript` (#8)
* Fix broken realpath
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
