# AI 시장 분석 시스템 (교육용 정리본)

이 레포지토리는 **FastAPI 백엔드 + PostgreSQL + Angular 프론트엔드**로 구성된 다중 에이전트 기반 시장 분석 시스템입니다. 아래 설명은 **실제 실행 흐름(`start_system_final.py`) 기준**으로 정리했습니다.

**핵심 아이디어 한 줄 요약**
- 여러 분석 에이전트가 각자 신호를 만들고, 이를 데이터베이스에 저장해 대시보드와 API로 제공하는 구조입니다.

**현재 기준 엔트리포인트**
- 백엔드: `start_system_final.py` (FastAPI, 포트 `8001`)
- 프론트엔드: `frontend/` (Angular, 포트 `4200`)
- DB: PostgreSQL (Docker 기본 `5433` → 컨테이너 내부 `5432`)

---

**실제 실행 흐름 (현재 동작 기준)**
1. `start_system_final.py`가 FastAPI 앱을 생성하고 DB 풀을 엽니다.
2. `services/`의 주요 서비스(실시간 데이터, 예측/평가/리포트 등)를 초기화합니다.
3. 스케줄러가 자동 작업을 실행합니다(예측 생성: 30분 주기, 티커 스캔: 매일 09:30/15:30).
4. `routes/`의 라우터들이 REST API로 기능을 제공합니다.
5. Angular 프론트엔드가 API를 호출해 대시보드를 구성합니다.

---

**현재 동작 모듈 지도 (실제 호출되는 것만)**

**백엔드 엔트리포인트**
- `start_system_final.py`: 전체 시스템 부팅, 서비스 초기화, 라우터 등록, 스케줄러 실행

**라우터 (API 진입점)**
- `routes/health.py`: `/health`, `/status` 시스템 상태
- `routes/predictions.py`: 예측/신호 조회
- `routes/symbols.py`: 심볼 CRUD, 관리 심볼 데이터
- `routes/ticker_discovery.py`: 티커 디스커버리 요약/결과
- `routes/forecasting.py`: 데이/스윙 예측 및 저장
- `routes/risk_analysis.py`: 리스크 분석
- `routes/ab_testing.py`: A/B 테스트 요약
- `routes/agent_monitor.py`: 에이전트 모니터
- `routes/agent_router.py`: 시장 레짐 기반 라우팅
- `routes/execution_agent.py`: 주문/포지션 요약
- `routes/rag_event_agent.py`: RAG 이벤트 분석
- `routes/rl_strategy.py`: RL 전략 요약
- `routes/meta_evaluation.py`: 메타 평가
- `routes/latent_pattern.py`: 잠재 패턴 분석
- `routes/ensemble_blender.py`: 앙상블 블렌딩 결과

**서비스 계층 (실제 동작 로직의 중심)**
- `services/real_data_service.py`: Yahoo Finance 기반 실시간 가격/지표 수집
- `services/individual_agent_service.py`: 10개 에이전트 예측을 경량 로직으로 생성
- `services/ensemble_blender_service.py`: 다수 신호를 결합해 앙상블 신호 생성
- `services/enhanced_forecasting_service.py`: 데이/스윙 예측용 서비스
- `services/agent_router_service.py`: 레짐 기반 에이전트 라우팅 판단
- `services/meta_evaluation_service.py`: 에이전트 성능 평가
- `services/latent_pattern_service.py`: 패턴 압축/탐지
- `services/rag_event_agent_service.py`: RAG 이벤트 분석
- `services/rl_training_service.py`: RL 학습 파이프라인
- `services/rl_data_collector.py`: RL 학습 데이터 수집
- `services/automated_rag_service.py`: 뉴스 자동 수집/분석
- `services/symbol_manager_postgres.py`: 심볼 관리(PostgreSQL 연동)

**데이터 계층**
- `data/data_ingestors.py`: 데이터 수집기(Yahoo Finance 등)
- `data/realtime_feeds.py`: 실시간 데이터 피드
- `data/enhanced_data_sources.py`: 보강 데이터 소스
- `data/alternative_data_sources.py`: 대체 데이터 소스
- `data/data_quality_validator.py`: 데이터 품질 체크

**스케줄링 유틸리티**
- `routes/utils.py`: 개별 에이전트 실행 + 티커 디스커버리 스케줄러 작업
- `agents/ticker_scanner_agent.py`: 실제 시장 스캔 로직 (스케줄러에서 호출)

**DB 스키마**
- `config/init.sql`: 핵심 테이블/인덱스/뷰 정의
- `migrations/*.sql`: 예측 테이블 등 추가 스키마

**프론트엔드**
- `frontend/src/app/`: Angular 페이지/서비스/컴포넌트
- `frontend/src/app/services/system-status.service.ts`: 대부분의 API 호출 집결

---

**실행 방법 (최소 설정)**

**Docker 실행(권장)**
```bash
docker-compose up -d
```
접속 주소: API `http://localhost:8001`, Frontend `http://localhost:4200`, pgAdmin `http://localhost:8080`

**로컬 실행**
```bash
pip install -r requirements.txt
python start_system_final.py
```

---

**교육용 이해 포인트 (학부생 관점)**
1. 레이어 구조를 분리해서 생각한다: `routes/`는 API 입구, `services/`는 핵심 로직, `data/ml/rl`은 데이터·모델 처리, `frontend/`는 UI다.
2. 데이터는 “DB가 중심”이다: 예측/리스크/에이전트 성과가 DB에 저장되고, API와 프론트엔드는 DB를 통해 동기화된다.
3. “에이전트”는 분산된 전문가 모델 개념이다: 모멘텀/감성/리스크/예측 등 역할 분담을 하고, 현재 실행 흐름에서는 `services/individual_agent_service.py`가 대표 예측을 생성한다.
4. 스케줄러는 시스템을 자동으로 움직인다: 30분마다 예측 생성, 하루 2회 티커 스캔이 자동 실행된다.

---

**API 요약 (자주 쓰는 엔드포인트)**
- `/health`, `/status`: 시스템 상태
- `/predictions`: 최근 예측
- `/symbols/summary`, `/api/symbols`: 심볼 관리
- `/forecasting/*`: 데이/스윙 예측
- `/ticker-discovery/*`: 티커 디스커버리
- `/risk-analysis/*`: 리스크 분석
- `/ensemble-blender/*`: 앙상블 결과
- `/rag-event-agent/*`: RAG 이벤트 분석
- `/rl-strategy-agent/*`: RL 전략

---

**정리**
이 레포는 “실시간 데이터 수집 → 다중 에이전트 분석 → DB 저장 → API/대시보드 제공”의 구조를 갖춘 **현실적인 분석 플랫폼 예제**입니다. 읽을 때는 `start_system_final.py` → `routes/` → `services/` 순서로 따라가면 구조가 빠르게 잡힙니다.
