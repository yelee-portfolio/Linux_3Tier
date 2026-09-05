# Linux 3-Tier 인프라 구축 및 운영



## 0. 목표

WEB / WAS / DB의 역할을 분리한 3-Tier 환경을 VMware와 AWS에 각각 구축하고,

서비스 자동 실행, 접근 제어, DB 백업·복구와 Nginx 로그 관리까지 확인하는 것을 목표로 했습니다.



## 1. VMware 구축

- WEB01 (192.168.10.10)

사용자가 처음 접속하는 서버로,

80번 포트에서 Nginx가 요청을 받고 → WAS01 8080포트로 요청 전달하도록 구성함

WEB01 주소 접속 시 WAS01에서 조회한 Inventory 화면이 출력되는 것으로 Reverse Proxy 동작을 확인함



- WAS01 (192.168.10.20)

실제 애플리케이션이 실행되는 서버로,

Flask 애플리케이션을 8080 포트에서 실행하고 DB01의 MariaDB에 접속해 데이터를 조회하도록 구성함

애플리케이션은 root가 아닌 appuser 계정으로 실행하도록 구성함


- DB01 (192.168.10.30)

Inventory 데이터가 저장되는 데이터베이스 서버로,

MariaDB를 3306 포트에서 실행하고, inventory 데이터베이스와 products 테이블 생성함

mariadb-dump와 cron을 이용해 매일 백업하도록 구성함



### 설계 포인트

- Flask 애플리케이션을 systemd 서비스로 등록해 자동 실행되도록 구성

- Flask 애플리케이션은 root가 아닌 Linux appuser 계정으로 실행

- MariaDB에는 WAS01에서만 접근 가능한 별도 appuser 계정을 생성하고 필요한 권한만 부여

- 서버 역할에 필요한 통신만 허용하도록 firewalld를 구성

- mariadb-dump와 Bash 스크립트로 DB 백업 자동화

- cron으로 매일 백업하고 7일이 지난 파일은 자동 삭제되도록 구성




### 관련설정 경로

- Nginx 설정 : config/nginx/was.conf

- systemd 설정 : config/systemd/inventory.service

- DB 백업 스크립트 : scripts/db-backup.sh



## 2. AWS 구축

- WEB01 (10.0.1.10/Public Subnet)

WEB 서버는 Public 접근을 허용하고,
HTTP 80 요청을 받아 WAS01의 8080 포트로 전달하도록 구성함

- WAS01 (10.0.2.20/Private Subnet)

WAS 서버는 Public IP 없이 Private Subnet에 배치하고,
WEB01에서 전달된 요청을 처리한 뒤 DB01의 3306 포트로 MariaDB에 접속하도록 구성함

- DB01 (10.0.3.30/Private Subnet)

DB 서버는 Public IP 없이 Private Subnet에 배치하고,

WAS01에만 MariaDB 3306 포트로 접속할 수 있게 설정함

또한 WAS, DB서버의 관리용 SSH 접속은 WEB01을 경유하도록 구성함



### 네트워크

- VPC : 10.0.0.0/16
  
- Public Subnet : 10.0.1.0/24
  
- WAS Private Subnet : 10.0.2.0/24
  
- DB Private Subnet : 10.0.3.0/24

- Security Group으로 WEB → WAS(8080), WAS → DB(3306) 통신만 허용



## 3. 트러블 슈팅

- 문제1: Private DB 패키지 설치 실패

원인: Private Subnet에 인터넷 경로가 없어 dnf timeout이 발생함

해결: 별도 패키지 설치가 필요 없는 systemd timer를 이용해 DB 백업 자동화를 구성함



- 문제2: MariaDB Dump 인증 오류

원인: ec2-user로 dump 실행 시 DB 인증이 실패함

해결: 최소 권한의 백업 전용 DB 계정을 생성하고 systemd 백업 작업에 적용함



## 4. 운영 검증

- DB Backup / Restore

최소 권한의 전용 DB 계정으로 Dump 파일이 정상적으로 생성되는 것을 확인함

생성한 백업 파일을 별도의 테스트 DB에 Restore하고,

products 테이블의 데이터와 건수가 원본과 동일하게 복구되는 것을 확인함



- Nginx Log Rotation

logrotate를 강제로 실행해 access.log가 정상적으로 분리되는 것을 확인함

이후 새 access.log에도 HTTP 요청 로그가 정상적으로 기록되는 것을 확인함



- 서비스 자동 실행

WEB / WAS / DB 서버 재부팅 후 Nginx, Flask, MariaDB가 자동 실행되고

전체 서비스가 정상 동작하는 것을 확인함



## 5. 결론

VMware와 AWS 환경에서 WEB → WAS → DB로 이어지는 3-Tier 구성을 완료했습니다.

AWS에서는 WEB을 Public Subnet, WAS와 DB를 Private Subnet으로 분리하고 필요한 서버 간 통신만 허용했습니다.

또한 서비스 자동 실행, 전용 DB 계정을 이용한 백업 자동화, 데이터 복구와 Nginx Log Rotation을 검증했습니다.
