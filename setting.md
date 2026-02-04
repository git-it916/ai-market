# AI Market System - 설치 가이드

## 개요

이 문서는 Windows 환경에서 AI Market System을 실행하기 위한 전체 설치 과정을 설명합니다.

---

## 1. WSL (Windows Subsystem for Linux) 설치

WSL은 Windows에서 Linux를 실행할 수 있게 해주는 기능입니다.

### PowerShell (관리자 모드)에서 실행:

```powershell
wsl --install
```

설치 후 **컴퓨터 재시작** 필요.

### 재시작 후 Ubuntu 설정:

- Ubuntu가 자동으로 시작됨
- Unix 사용자 이름 입력 (예: `bloomberg-ssh`)
- 비밀번호 설정

### WSL 상태 확인:

```powershell
wsl --list --verbose
```

출력 예시:
```
NAME              STATE           VERSION
* Ubuntu            Running         2
```

---

## 2. PostgreSQL 설치 (WSL Ubuntu 내부)

### Ubuntu 터미널 접속:

```powershell
wsl -d Ubuntu
```

### PostgreSQL 설치:

```bash
# 패키지 업데이트 & PostgreSQL 설치
sudo apt update && sudo apt install postgresql postgresql-contrib -y

# PostgreSQL 서비스 시작
sudo service postgresql start

# 데이터베이스 생성
sudo -u postgres psql -c "CREATE DATABASE ai_market_system;"

# postgres 사용자 비밀번호 설정
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'password';"
```

### (선택) Windows에서 접속 허용 설정:

Windows PowerShell에서 직접 PostgreSQL에 접속하려면:

```bash
# postgresql.conf 수정 - 모든 IP에서 접속 허용
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# pg_hba.conf 수정 - 외부 접속 허용
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# PostgreSQL 재시작
sudo service postgresql restart
```

### PostgreSQL 상태 확인:

```bash
sudo service postgresql status
```

---

## 3. Python 환경 설정

### 방법 A: WSL Ubuntu에서 실행 (권장)

```bash
# Ubuntu 접속
wsl -d Ubuntu

# PostgreSQL 시작
sudo service postgresql start

# 프로젝트 폴더로 이동
cd /mnt/c/Users/Bloomberg/Documents/ssh_project/ai-market

# python3-venv 설치 (최초 1회)
sudo apt install python3.12-venv -y

# 가상환경 생성 & 활성화
python3 -m venv .venv-linux
source .venv-linux/bin/activate

# 패키지 설치
pip install -r requirements.txt

# 앱 실행
python start_system_final.py
```

### 방법 B: Windows PowerShell에서 실행

```powershell
# 프로젝트 폴더로 이동
cd C:\Users\Bloomberg\Documents\ssh_project\ai-market

# 가상환경 생성 (최초 1회)
py -3.12 -m venv .venv

# 가상환경 활성화
.venv\Scripts\activate

# 패키지 설치
pip install -r requirements.txt

# 앱 실행
python start_system_final.py
```

**주의**: Windows에서 실행 시 WSL PostgreSQL에 접속하려면 위의 "Windows에서 접속 허용 설정"이 필요합니다.

---

## 4. 환경 변수 설정 (.env 파일)

프로젝트 루트에 `.env` 파일 생성:

```bash
# .env.example을 복사
cp .env.example .env
```

### .env 내용:

```env
# PostgreSQL Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432          # WSL PostgreSQL 기본 포트
POSTGRES_DB=ai_market_system
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password

# API Keys (선택 - 없어도 기본 기능 동작)
NEWS_API_KEY=your_newsapi_key_here
TWITTER_API_KEY=your_twitter_api_key_here
```

**포트 주의사항**:
- WSL PostgreSQL: `5432` (기본값)
- Windows PostgreSQL: 설치 시 설정한 포트 (보통 `5432` 또는 `5433`)

---

## 5. 데이터베이스 초기화

테이블 생성 (최초 1회):

### Ubuntu에서:

```bash
sudo -u postgres psql -d ai_market_system -f config/init.sql
```

### 또는 psql 직접 접속:

```bash
sudo -u postgres psql -d ai_market_system
```

```sql
-- init.sql 내용 직접 실행
\i config/init.sql
```

---

## 6. 서비스 실행

### 매번 실행 시:

```bash
# 1. WSL Ubuntu 접속
wsl -d Ubuntu

# 2. PostgreSQL 시작
sudo service postgresql start

# 3. 프로젝트 폴더로 이동
cd /mnt/c/Users/Bloomberg/Documents/ssh_project/ai-market

# 4. 가상환경 활성화
source .venv-linux/bin/activate

# 5. 앱 실행
python start_system_final.py
```

### 접속 URL:

- API: http://localhost:8001
- Swagger Docs: http://localhost:8001/docs
- Health Check: http://localhost:8001/health

---

## 7. Docker 설치 (선택사항)

Docker Desktop을 사용하면 PostgreSQL을 더 쉽게 관리할 수 있습니다.

### Docker Desktop 설치:

1. https://www.docker.com/products/docker-desktop/ 다운로드
2. 설치 (WSL 2 backend 선택)
3. 재시작

### Docker로 PostgreSQL 실행:

```powershell
docker run -d --name ai-market-postgres -e POSTGRES_DB=ai_market_system -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -p 5433:5432 postgres:15
```

### .env 설정 (Docker 사용 시):

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
```

---

## 용어 정리

| 용어 | 설명 |
|------|------|
| **WSL** | Windows Subsystem for Linux - Windows에서 Linux 실행 |
| **Ubuntu** | Linux 운영체제의 한 종류 |
| **PostgreSQL** | 관계형 데이터베이스 |
| **Docker** | 컨테이너 기반 가상화 플랫폼 |
| **venv** | Python 가상환경 |

---

## 문제 해결

### PostgreSQL 연결 거부 에러

```
ConnectionRefusedError: [WinError 1225] 원격 컴퓨터가 네트워크 연결을 거부했습니다
```

**해결**:
1. PostgreSQL 서비스 실행 확인: `sudo service postgresql status`
2. 포트 확인: `.env`의 `POSTGRES_PORT`가 맞는지 확인
3. WSL에서 앱 실행 권장

### WSL Ubuntu 접속 방법

```powershell
wsl -d Ubuntu
```

### PostgreSQL 서비스 시작

```bash
sudo service postgresql start
```

### 가상환경 활성화 안 될 때

- Windows: `.venv\Scripts\activate`
- Linux/WSL: `source .venv-linux/bin/activate`

---

## 파일 구조

```
ai-market/
├── .env                    # 환경 변수 (git에 포함 안 됨)
├── .env.example            # 환경 변수 예시
├── .gitignore              # git 제외 파일
├── .venv/                  # Windows 가상환경
├── .venv-linux/            # Linux 가상환경
├── requirements.txt        # Python 패키지 목록
├── start_system_final.py   # 메인 실행 파일
├── config/
│   └── init.sql            # DB 스키마
└── ...
```
