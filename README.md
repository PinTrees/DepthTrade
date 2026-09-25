# DepthTrade - Automated Grid Trading Web Platform

Bitget 기반의 심도(Depth) 그리드 자동매매 시스템 및 백테스팅 웹 플랫폼입니다.

## 주요 특징 및 기능

1. **심도 그리드 트레이딩 (Depth Grid Trading)**
   - 원작 Unity C# `BitgetBot_GridTrade`의 수식 및 알고리즘 완벽 이식
   - 실시간 오더북 호가 및 가격 기반 다이나믹 그리드 주문 생성 (`calculateGridPrices`)
   - 중복 가격 주문 방지 필터링 (`overlapPer: 0.074%`)
   - 가격 급변 시 이격도 초과 주문 자동 취소 및 재배치 (`canclePer: 1.74%`)
   - 그리드 누적 주문 수량에 따른 마틴게일 / 피라미딩 승수 적용 (`calculateOrderSize`)
   - 긴급 미체결 주문 일괄 취소 (`TR_CloseLiveOrders`)

2. **실시간 차트 & 오더북 비주얼라이저**
   - 캔들스틱 및 실시간 체결가 트래커
   - 진입 대기 매수선(초록 점선) 및 익절 목표 매도선(하늘색 점선) 시각화
   - 실시간 매수/매도 호가창 잔량 바 비주얼라이저

3. **백테스팅 시뮬레이션 연구소 (Backtest Lab)**
   - 다양한 타임프레임(1분봉, 5분봉, 15분봉, 1시간봉 등) 기반 시뮬레이션
   - 총 수익률, 승률, 최대 낙폭(MDD), 총 거래 횟수, 실시간 자산 곡선(Equity Curve) 그래프 제공

4. **모의투자 & Bitget 실계좌 연동 지원**
   - API 키 없이 즉시 브라우저에서 안전하게 테스트 가능한 시뮬레이션 모드
   - HMAC SHA-256 서명 기반 Bitget 선물 API 실거래 모드 지원

5. **Firebase & Glassmorphism UI**
   - Firebase Auth (게스트 익명 로그인, 이메일 로그인)
   - Cloud Firestore 연동 (설정 및 주문 기록 저장)
   - 사이버 퀀트 다크 테마 및 반응형 웹 레이아웃
