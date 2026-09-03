# Linux 3-Tier 인프라 구축



## 목표

VMware환경에서 리눅스 서버 3대를 WEB /WAS / DB 서버를 분리하여,

서비스 통신을 직접 구성했습니다.

WEB → WAS → DB 요청 흐름을 직접 구성하고 확인하는 것을 목표로 진행했습니다.



## 서버 역할

**- WEB01 (192.168.10.10)**

사용자가 처음 접속하는 서버로,

80번 포트에서 Nginx가 요청을 받고 → WAS01 8080포트로 요청 전달하도록 구성함

WEB01 주소 접속 시 WAS01에서 조회한 Inventory 화면이 출력되는 것으로 Reverse Proxy 동작을 확인함



**- WAS01 (192.168.10.20)**

실제 애플리케이션이 실행되는 서버로,

Flask 애플리케이션을 8080 포트에서 실행하고 DB01 MariaDB 접속해 데이터를 조회하도록 구성함

애플리케이션은 root가 아닌 appuser 계정으로 실행하도록 구성함



**- DB01 (192.168.10.30)**

Inventory 데이터가 저장되는 데이터베이스 서버로,

MariaDB를 3306 포트에서 실행하고, inventory 데이터베이스와 products 테이블 생성함

mariadb-dump를 이용해 백업하며, cron 등록으로 매일 자동으로 실행되도록 구성함



## 관련설정 경로

Nginx 설정 : config/nginx/was.conf

systemd 설정 : config/systemd/inventory.service

DB 백업 스크립트 : scripts/db-backup.sh



## 설계 포인트

\- Flask 애플리케이션을 systemd 서비스로 등록해 자동 실행되도록 구성

\- Flask 애플리케이션은 root가 아닌 Linux appuser 계정으로 실행

\- MariaDB에는 WAS01에서만 접근 가능한 별도 DB 사용자 appuser 계정을 생성하고 필요한 권한만 부여

\- 서버 역할에 필요한 통신만 허용하도록 firewalld를 구성

\- mariadb-dump와 Bash 스크립트로 DB 백업 자동화+cron으로 매일 실행+7일 이상 지난 백업은 자동 삭제되도록 구성



## 결론

Windows Browser에서 WEB01에 접속, DB에 저장된 상품 데이터가 화면에 출력되었습니다.

즉 최종적으로 WEB → WAS → DB 전체 요청 흐름이 정상적으로 동작하는 것을 확인했습니다.

