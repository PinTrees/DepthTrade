import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../style/style.dart';

class IndicatorMeta {
  final String id;
  final String title;
  final String englishName;
  final String category;
  final Color categoryColor;
  final String summary;
  final String formula;
  final List<String> signals;
  final List<String> quantBotTips;

  const IndicatorMeta({
    required this.id,
    required this.title,
    required this.englishName,
    required this.category,
    required this.categoryColor,
    required this.summary,
    required this.formula,
    required this.signals,
    required this.quantBotTips,
  });

  static IndicatorMeta get(String id) {
    return _registry[id] ?? _defaultMeta(id);
  }

  static List<IndicatorMeta> get all => _registry.values.toList();

  static IndicatorMeta _defaultMeta(String id) => IndicatorMeta(
        id: id,
        title: id.toUpperCase(),
        englishName: 'Technical Indicator',
        category: '기술적 지표',
        categoryColor: AppColor.accent,
        summary: '캔들 데이터 시계열을 바탕으로 산출된 보조지표입니다.',
        formula: 'Formula not defined',
        signals: const ['추세 방향과 지지/저항을 관찰하여 매매에 활용합니다.'],
        quantBotTips: const ['그리드 봇의 변동성 이격 관리에 참고할 수 있습니다.'],
      );

  static final Map<String, IndicatorMeta> _registry = {
    'sma': const IndicatorMeta(
      id: 'sma',
      title: '단순이동평균 (SMA)',
      englishName: 'Simple Moving Average (7, 25, 99, 200)',
      category: '추세 추종 (Trend)',
      categoryColor: Color(0xFFFFD700),
      summary: '일정 기간 동안의 종가 평균을 단순 산술 합산하여 시장의 단기, 중기, 장기 추세 흐름을 직관적으로 시각화합니다.',
      formula: 'SMA = (P₁ + P₂ + ... + Pₙ) / n (n = 7, 25, 99, 200)',
      signals: [
        '골든크로스(Golden Cross): 단기선(SMA 7)이 중장기선(SMA 25/99)을 아래에서 위로 강하게 돌파할 때 상승 추세 진입 신호.',
        '데드크로스(Dead Cross): 단기선이 장기선을 하향 이탈할 때 추세 하락 전환 및 리스크 관리 신호.',
        '동적 지지/저항: 정배열 상승장에서는 SMA선이 강력한 바닥 지지선, 역배열 하락장에서는 천장 저항선 역할 수행.',
      ],
      quantBotTips: [
        'DepthTrade 그리드 봇은 SMA 25/99일선 위에서 가격이 형성될 때 매수 익절 회전 주기가 가장 빠르고 안정적입니다.',
        '장기 200일선 아래로 급락하는 장세에서는 이격 취소(canclePer) 규칙이 발동되어 하방 물림을 자동으로 방어합니다.',
      ],
    ),
    'ema': const IndicatorMeta(
      id: 'ema',
      title: '지수이동평균 (EMA)',
      englishName: 'Exponential Moving Average (9, 21, 50, 200)',
      category: '추세 가중치 (Trend Momentum)',
      categoryColor: Color(0xFF00E676),
      summary: '과거 가격보다 최신 가격에 높은 가중치(Multiplier)를 부여하여 SMA의 지연(Lag) 현상을 획기적으로 개선한 추세 지표입니다.',
      formula: 'EMA_today = Price_today × (2/(N+1)) + EMA_yesterday × (1 - 2/(N+1))',
      signals: [
        '민감한 변곡점 포착: 가격 급변 시 SMA보다 훨씬 빠르게 반응하여 빠른 진입/탈출 시점 제시.',
        'EMA 9 / EMA 21 크로스: 전 세계 단타 스캘퍼와 스윙 트레이더가 가장 애용하는 핵심 매수/매도 트리거.',
        'EMA 200 기관 기준선: 월가 및 대형 펀드가 장기 불마켓(상승장)/베어마켓(하락장)을 구분하는 절대 기준선.',
      ],
      quantBotTips: [
        '변동성이 극심한 비트코인 선물 시장에서는 SMA보다 EMA의 크로스를 추적하는 것이 슬리피지를 줄이는 데 유리합니다.',
      ],
    ),
    'bb': const IndicatorMeta(
      id: 'bb',
      title: '볼린저 밴드 (Bollinger Bands)',
      englishName: 'Bollinger Bands (Period: 20, Multiplier: 2.0σ)',
      category: '변동성 채널 (Volatility)',
      categoryColor: Color(0xFF2979FF),
      summary: '통계학의 정규분포 원리에 기반하여 가격의 95.4%가 상하단 밴드 내에서 수렴/발산한다는 법칙을 이용한 대표적 변동성 채널입니다.',
      formula: '중심선 = SMA(20)\n상단 밴드 = SMA(20) + 2σ\n하단 밴드 = SMA(20) - 2σ',
      signals: [
        '밴드 스퀴즈(Squeeze): 밴드 폭이 극도로 좁아지면 조만간 위/아래로 거대한 시세 분출(폭발) 발생 예고.',
        '상단 밴드 터치/돌파: 단기 과매수 영역으로 일시적 조정이나 차익 실현 저항 발생 가능성.',
        '하단 밴드 지지 반등: 단기 과매도 영역으로 기술적 반등 및 분할 매수 타점.',
      ],
      quantBotTips: [
        'DepthTrade의 마틴게일 그리드는 볼린저 밴드 하단 영역에서 주문 배수를 분할 배치하고, 상단 밴드 근처에서 일괄 익절을 실현하도록 설계되었습니다.',
      ],
    ),
    'sar': const IndicatorMeta(
      id: 'sar',
      title: '파라볼릭 SAR (Parabolic SAR)',
      englishName: 'Stop and Reverse (AF: 0.02, Max: 0.20)',
      category: '추세 반전 (Reversal)',
      categoryColor: Color(0xFFFF5252),
      summary: '차트 위아래에 포물선 점(Dot) 형태로 표시되며, 추세가 유지되는지 혹은 반전(Stop and Reverse)되는지를 명확하게 짚어줍니다.',
      formula: 'SAR_next = SAR_curr + AF × (EP - SAR_curr) (AF: 가속계수, EP: 극단점)',
      signals: [
        '점의 위치 반전: 캔들 위에 있던 점이 캔들 아래로 찍히기 시작하면 즉각 매수(롱) 전환 신호.',
        '가속도 원리: 추세가 지속될수록 점의 이동 간격이 가속되어 캔들에 바짝 밀착되므로 트레일링 스탑에 최적.',
        '위험 회피: 캔들 위에 점이 유지되는 동안에는 섣부른 역추세 롱 진입을 자제.',
      ],
      quantBotTips: [
        '파라볼릭 점이 캔들 위로 역전되었을 때는 신규 매수 주문을 일시 억제하고 보유 포지션 탈출에 집중합니다.',
      ],
    ),
    'super_trend': const IndicatorMeta(
      id: 'super_trend',
      title: '슈퍼트렌드 (SuperTrend)',
      englishName: 'SuperTrend (ATR Period: 10, Multiplier: 3.0)',
      category: '추세 추종 (Trend)',
      categoryColor: Color(0xFF00E5FF),
      summary: '실제 변동폭(ATR)을 활용해 시장의 지지선과 저항선을 계산하여 초록색(상승)과 빨간색(하락) 밴드로 즉시 판별하는 트렌드 추종 지표입니다.',
      formula: '상승 밴드 = (High+Low)/2 - 3×ATR(10)\n하락 밴드 = (High+Low)/2 + 3×ATR(10)',
      signals: [
        '초록색 밴드(BUY): 가격이 밴드 위에서 지지를 받으며 강세 추세가 지속되는 구간.',
        '빨간색 밴드(SELL): 가격이 밴드를 깨고 내려가면 즉시 약세장으로 전환되는 손절 기준선.',
        '밴드 색상 전환 봉: 지표가 색을 바꾸는 첫 번째 완성 캔들이 가장 신뢰도 높은 추세 전환 타점.',
      ],
      quantBotTips: [
        '슈퍼트렌드가 초록색일 때 그리드 봇을 가동하면 마틴게일 청산 속도가 현저히 빨라져 누적 손익이 가파르게 상승합니다.',
      ],
    ),
    'vwap': const IndicatorMeta(
      id: 'vwap',
      title: 'VWAP (거래량 가중 평균가)',
      englishName: 'Volume Weighted Average Price',
      category: '거래량 기준선 (Volume Benchmark)',
      categoryColor: Color(0xFF818CF8),
      summary: '단순 가격이 아닌 실제 거래량이 실린 가격의 누적 가중 평균선으로, 월가 기관 투자자와 알고리즘 봇의 공정 가치(Fair Value) 기준선입니다.',
      formula: 'VWAP = Σ(Typical Price × Volume) / Σ(Volume)',
      signals: [
        '가격 > VWAP: 매수세가 시장을 장악하고 있으며 평균 거래가보다 프리미엄이 붙은 강세장.',
        '가격 < VWAP: 매도세 우위, 상대적 저평가 할인 구간으로 매수 진입 유리.',
        '기관 되돌림 지지/저항: 가격이 VWAP 선에 접근할 때 대규모 기관 매수/매도 벽 발생.',
      ],
      quantBotTips: [
        'VWAP 아래에서 분할 그리드 매수를 체결하고, VWAP 위로 반등할 때 익절을 실현하는 평균 회귀(Mean Reversion) 전략에 최적입니다.',
      ],
    ),
    'ichimoku': const IndicatorMeta(
      id: 'ichimoku',
      title: '일목균형표 (Ichimoku Cloud)',
      englishName: 'Ichimoku Kinko Hyo (9, 26, 52)',
      category: '종합 균형 (Multi-Timeframe)',
      categoryColor: Color(0xFFAB47BC),
      summary: '시간론, 파동론, 가격론을 종합한 동양 최고의 지표로, 전환선·기준선과 선행스팬 구름대(Kumo)로 지지와 저항의 두께를 직관적으로 파악합니다.',
      formula: '전환선(9일 고저평균), 기준선(26일 고저평균), 선행스팬 1·2 구름대 26일 선행',
      signals: [
        '구름대 위: 장기 강세장 (롱 포지션 전략 유리).',
        '구름대 아래: 장기 약세장 (보수적 방어 전략).',
        '구름대 내부: 대표적인 박스권 횡보 구간으로 지지와 저항 사이 스캘핑 기회.',
      ],
      quantBotTips: [
        '캔들이 두터운 구름대 안에서 횡보할 때는 그리드 봇의 자동 주문 체결이 쉴 새 없이 발생하며 최대 수익을 창출합니다.',
      ],
    ),
    'rsi': const IndicatorMeta(
      id: 'rsi',
      title: 'RSI (상대강도지수)',
      englishName: 'Relative Strength Index (Period: 14)',
      category: '모멘텀 오실레이터 (Momentum)',
      categoryColor: Color(0xFFBA68C8),
      summary: '0부터 100까지의 진동자로 최근 14일간 상승폭과 하락폭의 상대적 강도를 측정하여 시장의 과열과 침체를 정밀 포착합니다.',
      formula: 'RSI = 100 - [100 / (1 + (평균 상승폭 / 평균 하락폭))]',
      signals: [
        '과매수(70 이상): 단기 상승 피로 누적 구간으로 추격 매수 금지 및 분할 익절 타이밍.',
        '과매도(30 이하): 공포 심리로 인한 과매도 구간으로 기술적 급반등 타점.',
        '상승 다이버전스: 가격은 신저가를 경신하지만 RSI 저점은 상승할 때 강력한 바닥 반전 신호.',
      ],
      quantBotTips: [
        'RSI가 30 이하로 진입했을 때 그리드 봇의 2배, 4배 마틴게일 매수가 체결되면 반등 시 평균단가 인하 효과가 극대화됩니다.',
      ],
    ),
    'macd': const IndicatorMeta(
      id: 'macd',
      title: 'MACD (이동평균수렴확산)',
      englishName: 'Moving Average Convergence Divergence (12, 26, 9)',
      category: '추세 모멘텀 (Trend Oscillator)',
      categoryColor: Color(0xFF00E5FF),
      summary: '단기 EMA(12)와 장기 EMA(26)의 간격을 측정하여 추세의 강도와 가속도를 히스토그램 막대와 시그널 교차선으로 보여줍니다.',
      formula: 'MACD = EMA(12) - EMA(26)\nSignal = MACD의 EMA(9)\nHistogram = MACD - Signal',
      signals: [
        '골든크로스: MACD선이 시그널선을 상향 돌파 시 강력한 매수 신호.',
        '히스토그램 반전: 음수 막대가 줄어들며 0선 위로 올라서는 첫 봉이 가장 빠른 모멘텀 변곡점.',
        '0선 기준: MACD선이 0선 위에 있으면 상승 추세, 0선 아래는 하락 추세 지속.',
      ],
      quantBotTips: [
        '히스토그램이 양수 영역으로 전환될 때 봇 가동을 시작하면 횡보 지연 없이 즉시 익절 사이클을 순환할 수 있습니다.',
      ],
    ),
    'kdj': const IndicatorMeta(
      id: 'kdj',
      title: 'KDJ 지표 (스토캐스틱)',
      englishName: 'KDJ Stochastic (9, 3, 3)',
      category: '초단기 오실레이터 (Fast Oscillator)',
      categoryColor: Color(0xFFFFB300),
      summary: '스토캐스틱에 빠른 J 라인을 결합하여 아시아권에서 가장 대중적으로 사용되는 초단타 모멘텀 3선 지표입니다.',
      formula: 'RSV = (Close - Low9)/(High9 - Low9)×100\nK = SMA(RSV), D = SMA(K), J = 3K - 2D',
      signals: [
        'J선 0 이하(초과매도): J선이 0 아래로 떨어졌다가 K선을 뚫고 올라올 때 최고의 단기 저점 매수 기회.',
        'J선 100 이상(초과매수): 급등 후 상단 피로감으로 단기 조정 주의.',
        '3선 골든크로스(J > K > D): 빠른 상승 가속도 국면.',
      ],
      quantBotTips: [
        '1분봉/5분봉 단타 시 J선의 극단적 저점(J < 0)에서 그리드 봇의 첫 주문이 진입하도록 타이밍을 맞출 수 있습니다.',
      ],
    ),
    'wr': const IndicatorMeta(
      id: 'wr',
      title: '윌리엄스 %R (Williams %R)',
      englishName: 'Williams %R (Period: 14)',
      category: '과열/침체 (Momentum)',
      categoryColor: Color(0xFFFF7043),
      summary: '-100부터 0 사이의 역방향 스케일로 최근 14봉 동안의 최고점 대비 현재 종가의 위치를 정밀하게 파악합니다.',
      formula: '%R = [(High14 - Close) / (High14 - Low14)] × -100',
      signals: [
        '-80 이하: 강력한 과매도 상태로 곧 평균치로 회귀하는 반등 매수 구간.',
        '-20 이상: 강력한 과매수 상태로 고점 매도 압력 발생 가능성.',
      ],
      quantBotTips: [
        'RSI와 함께 -80 이하 동시 도달 시 기술적 반등 확률이 85% 이상으로 급상승합니다.',
      ],
    ),
    'cci': const IndicatorMeta(
      id: 'cci',
      title: 'CCI (상품채널지수)',
      englishName: 'Commodity Channel Index (Period: 20)',
      category: '순환 주기 (Cyclical)',
      categoryColor: Color(0xFFFFCA28),
      summary: '가격이 평균치로부터 얼마나 벗어났는지를 통계적 오차로 측정하여 주기적인 파동의 변곡점을 감지합니다.',
      formula: 'CCI = (Typical Price - SMA(20)) / (0.015 × Mean Deviation)',
      signals: [
        '+100 상향 돌파: 강력한 시세 상승 구간 진입 신호.',
        '-100 하향 이탈 후 재진입: 극단적 과매도 탈출 시 매수 타점.',
      ],
      quantBotTips: [
        'CCI가 -100 이하에서 위로 턴할 때 그리드 봇을 시작하면 안전 마진을 확보할 수 있습니다.',
      ],
    ),
    'atr': const IndicatorMeta(
      id: 'atr',
      title: 'ATR (평균실제범위)',
      englishName: 'Average True Range (Period: 14)',
      category: '변동성 측정 (Volatility Size)',
      categoryColor: Color(0xFF26A69A),
      summary: '상승/하락 방향과 무관하게 시장의 순수한 일일 가격 진폭(변동성 크기)만을 화폐 단위로 측정하는 리스크 관리 필수 지표입니다.',
      formula: 'TR = Max(H-L, |H-Close_prev|, |L-Close_prev|), ATR = EMA(TR, 14)',
      signals: [
        'ATR 급등: 대형 뉴스나 고래 매매로 변동성이 폭발하는 구간 (슬리피지 주의).',
        'ATR 바닥: 변동성이 극도로 수축된 구간으로 곧 대규모 방향성 추세 폭발 임박.',
      ],
      quantBotTips: [
        'DepthTrade 설정에서 ATR이 클 때는 주문 간격(openOrderPer)을 넓히고, ATR이 작을 때는 좁혀 수익을 극대화합니다.',
      ],
    ),
    'obv': const IndicatorMeta(
      id: 'obv',
      title: 'OBV (온밸런스볼륨)',
      englishName: 'On-Balance Volume',
      category: '세력 거래량 (Smart Money)',
      categoryColor: Color(0xFF42A5F5),
      summary: '가격 변동에 앞서 움직이는 큰손(스마트 머니)의 매집과 분산을 누적 거래량 흐름으로 선행 추적합니다.',
      formula: 'Close > Close_prev면 OBV += Vol, Close < Close_prev면 OBV -= Vol',
      signals: [
        'OBV 신고가 + 가격 횡보: 세력의 은밀한 매집 진행 중으로 곧 강력한 상방 폭발 예고.',
        'OBV 하락 + 가격 상승: 거래량이 실리지 않은 허수 상승으로 폭락 경고.',
      ],
      quantBotTips: [
        'OBV가 우상향을 그릴 때 그리드 봇을 장기 가동하면 큰손의 매집 파동에 편승할 수 있습니다.',
      ],
    ),
    'heikin_ashi': const IndicatorMeta(
      id: 'heikin_ashi',
      title: '하이킨 아시 캔들 (Heikin-Ashi)',
      englishName: 'Average Bar Japanese Candlestick',
      category: '차트 스타일 (Trend Filter)',
      categoryColor: Color(0xFF00E676),
      summary: '일반 캔들의 불필요한 단기 잔파동(노이즈)을 필터링하여 명확한 추세의 지속과 전환을 한눈에 파악하도록 개조된 평균 캔들입니다.',
      formula: 'HA_Close = (O+H+L+C)/4, HA_Open = (Prev_HA_O + Prev_HA_C)/2',
      signals: [
        '아래 꼬리 없는 연속 양봉: 가장 강력한 상승 추세 진행형 (지속 홀딩).',
        '위 꼬리 없는 연속 음봉: 가장 강력한 하락 추세 진행형 (매수 보류).',
        '도지형 캔들(위아래 긴 꼬리): 추세의 피로감 및 변곡점 반전 경고.',
      ],
      quantBotTips: [
        '하이킨 아시 차트를 켜두면 거짓 양봉에 낚여 뇌동매매하는 실수를 원천 방지할 수 있습니다.',
      ],
    ),
    'log_scale': const IndicatorMeta(
      id: 'log_scale',
      title: '로그 스케일 (Logarithmic)',
      englishName: 'Logarithmic Price Scaling',
      category: '디스플레이 (Display Options)',
      categoryColor: Color(0xFF00E5FF),
      summary: '단순 달러 금액이 아닌 가격의 상승 비율(%)을 기준으로 수직 축을 균등하게 스케일링합니다.',
      formula: 'Y축 픽셀 위치 ∝ ln(Price)',
      signals: [
        '장기 차트 왜곡 방지: 비트코인처럼 수백% 이상 상승한 장기 차트에서 정확한 추세선 작도 가능.',
      ],
      quantBotTips: [
        '수익률(%) 기반으로 주문을 분할 배치하는 퀀트 봇 특성에 가장 적합한 차트 뷰입니다.',
      ],
    ),
    'grid_order_lines': const IndicatorMeta(
      id: 'grid_order_lines',
      title: '그리드 봇 주문선 오버레이',
      englishName: 'Live Grid Limit Order Overlay',
      category: '디스플레이 (Display Options)',
      categoryColor: Color(0xFF7C4DFF),
      summary: '퀀트 봇이 실시간으로 거래소 오더북에 배치해둔 미체결 매수선(초록선)과 미체결 익절선(빨강선)을 캔들 차트 위에 실시간으로 투영합니다.',
      formula: '엔진 내 `liveOrders` 및 `liveCloseOrders` 실시간 가격선 매핑',
      signals: [
        '시각적 체결 확인: 캔들이 어느 선을 터치할 때 매수/익절이 체결되는지 실시간 직관적 관찰.',
      ],
      quantBotTips: [
        '가격이 내 주문선에 접근할 때 호가창 두께와 함께 보며 봇의 최적 작동 상태를 검증할 수 있습니다.',
      ],
    ),
    'high_low_badges': const IndicatorMeta(
      id: 'high_low_badges',
      title: '최고가 / 최저가 뱃지',
      englishName: 'Dynamic Swing High & Low Badges',
      category: '디스플레이 (Display Options)',
      categoryColor: Color(0xFFFFD700),
      summary: '현재 화면에 렌더링된 가시 영역 캔들 중 최고가(High)와 최저가(Low)를 자동으로 추적하여 형광 뱃지로 차트에 마킹합니다.',
      formula: 'Visible Window Max(High), Min(Low)',
      signals: [
        '박스권 고점/저점 식별: 현재 줌 구간의 레인지 범위를 즉시 파악.',
      ],
      quantBotTips: [
        '최저가 뱃지 부근에서 그리드 매수가 체결되고, 최고가 뱃지 부근에서 익절이 나가면 최고의 수익 구간입니다.',
      ],
    ),
    'countdown_timer': const IndicatorMeta(
      id: 'countdown_timer',
      title: '캔들 마감 카운트다운 타이머',
      englishName: 'Candle Close Countdown Timer',
      category: '디스플레이 (Display Options)',
      categoryColor: Color(0xFF00E5FF),
      summary: '현재 진행 중인 캔들의 확정 마감(봉 마감)까지 남은 시간을 초 단위로 실시간 표시합니다.',
      formula: 'Time_remaining = Next_Interval_Epoch - Current_Timestamp',
      signals: [
        '봉 마감 원칙: 모든 신뢰도 높은 기술적 지표의 돌파나 시그널은 반드시 캔들 마감을 확인하고 판단해야 합니다.',
      ],
      quantBotTips: [
        '봉 마감 직전 급격한 변동성이 생길 때 봇의 주문 취소 및 재주문 알고리즘이 자동으로 슬리피지를 방어합니다.',
      ],
    ),
  };
}

/// Indicator Educational & Visual Simulation Dialog
class IndicatorGuideDialog extends StatelessWidget {
  final IndicatorMeta meta;
  final bool isCurrentlyEnabled;
  final ValueChanged<bool>? onToggle;

  const IndicatorGuideDialog({
    super.key,
    required this.meta,
    this.isCurrentlyEnabled = false,
    this.onToggle,
  });

  static Future<void> show(
    BuildContext context,
    String indicatorId, {
    bool isEnabled = false,
    ValueChanged<bool>? onToggle,
  }) {
    final meta = IndicatorMeta.get(indicatorId);
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => IndicatorGuideDialog(
        meta: meta,
        isCurrentlyEnabled: isEnabled,
        onToggle: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColor.isDark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColor.cardSurface.withValues(alpha: isDark ? 0.92 : 0.96),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColor.elevationShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Bar
                  _buildHeader(context),

                  // 2. Scrollable Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Virtual Mini Chart Demonstration
                          _buildVirtualChartCard(isDark),
                          const SizedBox(height: 18),

                          // Summary Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: meta.categoryColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 20, color: meta.categoryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    meta.summary,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Mathematical Formula
                          _buildSectionTitle('📐 연산 수식 및 알고리즘 원리', meta.categoryColor),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColor.inputSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              meta.formula,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppColor.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Trading Signals
                          _buildSectionTitle('🎯 핵심 매매 시그널 해석법', AppColor.longGreen),
                          const SizedBox(height: 8),
                          ...meta.signals.map((sig) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(Icons.arrow_right, size: 16, color: AppColor.longGreen),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        sig,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.45,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 16),

                          // Quant Bot Tips
                          _buildSectionTitle('🤖 DepthTrade 퀀트 봇 활용 팁', AppColor.accent),
                          const SizedBox(height: 8),
                          ...meta.quantBotTips.map((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(Icons.check_circle_outline, size: 14, color: AppColor.accent),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.45,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                  // 3. Bottom Action Bar
                  _buildBottomBar(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: meta.categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              meta.category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: meta.categoryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  meta.englishName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColor.textSecondary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualChartCard(bool isDark) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.inputSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Virtual Candlestick & Indicator Simulation Canvas
            CustomPaint(
              painter: VirtualIndicatorChartPainter(
                indicatorId: meta.id,
                isDark: isDark,
                primaryColor: meta.categoryColor,
              ),
              child: const SizedBox.expand(),
            ),

            // Top overlay badge
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: meta.categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '가상 시뮬레이션 차트 데모',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: BoxDecoration(
        color: AppColor.inputSurface.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기', style: TextStyle(color: AppColor.textSecondary)),
          ),
          const Spacer(),
          if (onToggle != null) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentlyEnabled ? AppColor.inputSurface : meta.categoryColor,
                foregroundColor: isCurrentlyEnabled ? AppColor.textPrimary : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isCurrentlyEnabled ? Icons.check_circle : Icons.add_chart,
                size: 16,
              ),
              label: Text(
                isCurrentlyEnabled ? '적용 중 (ON)' : '이 지표 차트에 켜기',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () {
                onToggle!(!isCurrentlyEnabled);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Real mathematical painter drawing simulated candlesticks and indicators
class VirtualIndicatorChartPainter extends CustomPainter {
  final String indicatorId;
  final bool isDark;
  final Color primaryColor;

  VirtualIndicatorChartPainter({
    required this.indicatorId,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Background
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Synthetic 20-candle Price Time-series
    final double isSub = ['rsi', 'macd', 'kdj', 'wr', 'cci', 'atr', 'obv'].contains(indicatorId) ? 1.0 : 0.0;
    final double mainHeight = isSub == 1.0 ? size.height * 0.58 : size.height;
    final double subHeight = isSub == 1.0 ? size.height * 0.40 : 0.0;
    final double subTop = size.height - subHeight;

    const int count = 22;
    final double candleWidth = size.width / count;

    // Synthetic base prices (Dips first, then Golden rally)
    final List<double> prices = [
      100, 98, 97, 95, 94, 93, 94, 96, 98, 100, 102, 101, 103, 106, 108, 107, 110, 113, 112, 115, 118, 120
    ];

    double minP = 90;
    double maxP = 125;

    double pToY(double p) => mainHeight - 20 - ((p - minP) / (maxP - minP)) * (mainHeight - 40);

    // 3. Draw Candles
    for (int i = 0; i < count; i++) {
      final p = prices[i];
      final prevP = i > 0 ? prices[i - 1] : p;
      final bool isUp = p >= prevP;
      final color = isUp ? const Color(0xFF00E676) : const Color(0xFFFF5252);

      final openY = pToY(prevP);
      final closeY = pToY(p);
      final highY = min(openY, closeY) - 5;
      final lowY = max(openY, closeY) + 5;
      final x = i * candleWidth + candleWidth * 0.5;

      // Wick
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        Paint()..color = color..strokeWidth = 1.2,
      );

      // Body
      final topY = min(openY, closeY);
      final bodyHeight = max(2.0, (openY - closeY).abs());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, topY + bodyHeight / 2),
            width: candleWidth * 0.65,
            height: bodyHeight,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }

    // 4. Draw Specific Indicator Curves & Visualizations
    final Path indPath = Path();

    if (indicatorId == 'sma' || indicatorId == 'ema') {
      // Short-term Fast Line
      indPath.reset();
      for (int i = 0; i < count; i++) {
        final x = i * candleWidth + candleWidth * 0.5;
        final y = pToY(prices[i] * 0.99 + 0.5);
        if (i == 0) {
          indPath.moveTo(x, y);
        } else {
          indPath.lineTo(x, y);
        }
      }
      canvas.drawPath(
        indPath,
        Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      // Long-term Slow Line
      final slowPath = Path();
      for (int i = 0; i < count; i++) {
        final x = i * candleWidth + candleWidth * 0.5;
        final y = pToY(96 + (i * 0.8));
        if (i == 0) {
          slowPath.moveTo(x, y);
        } else {
          slowPath.lineTo(x, y);
        }
      }
      canvas.drawPath(
        slowPath,
        Paint()
          ..color = const Color(0xFF2979FF)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    } else if (indicatorId == 'bb') {
      // Bollinger Bands Channel
      final upperPath = Path();
      final lowerPath = Path();
      final midPath = Path();

      for (int i = 0; i < count; i++) {
        final x = i * candleWidth + candleWidth * 0.5;
        final midY = pToY(prices[i]);
        if (i == 0) {
          midPath.moveTo(x, midY);
          upperPath.moveTo(x, midY - 20);
          lowerPath.moveTo(x, midY + 20);
        } else {
          midPath.lineTo(x, midY);
          upperPath.lineTo(x, midY - 20);
          lowerPath.lineTo(x, midY + 20);
        }
      }
      // Fill band
      final bandFill = Path.from(upperPath);
      bandFill.lineTo(size.width, pToY(prices.last) + 20);
      for (int i = count - 1; i >= 0; i--) {
        final x = i * candleWidth + candleWidth * 0.5;
        bandFill.lineTo(x, pToY(prices[i]) + 20);
      }
      bandFill.close();
      canvas.drawPath(
        bandFill,
        Paint()..color = const Color(0xFF2979FF).withValues(alpha: 0.12),
      );

      canvas.drawPath(upperPath, Paint()..color = const Color(0xFF2979FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      canvas.drawPath(lowerPath, Paint()..color = const Color(0xFF2979FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      canvas.drawPath(midPath, Paint()..color = const Color(0xFFFFB300)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    } else if (indicatorId == 'sar') {
      // Parabolic Dots
      for (int i = 0; i < count; i++) {
        final x = i * candleWidth + candleWidth * 0.5;
        final bool isBull = i > 6;
        final y = isBull ? pToY(prices[i]) + 15 : pToY(prices[i]) - 15;
        canvas.drawCircle(
          Offset(x, y),
          2.5,
          Paint()..color = isBull ? const Color(0xFF00E676) : const Color(0xFFFF5252),
        );
      }
    } else if (indicatorId == 'super_trend') {
      // SuperTrend Band
      final stPath = Path();
      for (int i = 0; i < count; i++) {
        final x = i * candleWidth + candleWidth * 0.5;
        final bool isBull = i > 5;
        final y = isBull ? pToY(prices[i]) + 12 : pToY(prices[i]) - 12;
        if (i == 0) {
          stPath.moveTo(x, y);
        } else {
          stPath.lineTo(x, y);
        }
      }
      canvas.drawPath(
        stPath,
        Paint()
          ..color = const Color(0xFF00E676)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    } else if (indicatorId == 'vwap') {
      final vwapPath = Path();
      for (int i = 0; i < count; i++) {
        final x = i * candleWidth + candleWidth * 0.5;
        final y = pToY(98 + (i * 0.9));
        if (i == 0) {
          vwapPath.moveTo(x, y);
        } else {
          vwapPath.lineTo(x, y);
        }
      }
      canvas.drawPath(
        vwapPath,
        Paint()
          ..color = const Color(0xFF818CF8)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke,
      );
    } else if (indicatorId == 'grid_order_lines') {
      // Horizontal buy lines (green dashed) and sell lines (red dashed)
      final greenPaint = Paint()..color = const Color(0xFF00E676)..strokeWidth = 1.2;
      final redPaint = Paint()..color = const Color(0xFFFF5252)..strokeWidth = 1.2;

      canvas.drawLine(Offset(0, pToY(94)), Offset(size.width, pToY(94)), greenPaint);
      canvas.drawLine(Offset(0, pToY(92)), Offset(size.width, pToY(92)), greenPaint);
      canvas.drawLine(Offset(0, pToY(116)), Offset(size.width, pToY(116)), redPaint);
      canvas.drawLine(Offset(0, pToY(118)), Offset(size.width, pToY(118)), redPaint);
    }

    // 5. Sub Indicator Bottom Panel
    if (isSub == 1.0) {
      final divPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, subTop), Offset(size.width, subTop), divPaint);

      if (indicatorId == 'rsi') {
        // Draw 70 and 30 guide lines
        final guidePaint = Paint()
          ..color = Colors.purple.withValues(alpha: 0.3)
          ..strokeWidth = 1.0;
        final y70 = subTop + subHeight * 0.3;
        final y30 = subTop + subHeight * 0.7;
        canvas.drawLine(Offset(0, y70), Offset(size.width, y70), guidePaint);
        canvas.drawLine(Offset(0, y30), Offset(size.width, y30), guidePaint);

        // RSI Line
        final rsiPath = Path();
        for (int i = 0; i < count; i++) {
          final x = i * candleWidth + candleWidth * 0.5;
          final rsiVal = 30 + (i / count) * 45;
          final y = subTop + subHeight * (1.0 - (rsiVal / 100));
          if (i == 0) {
            rsiPath.moveTo(x, y);
          } else {
            rsiPath.lineTo(x, y);
          }
        }
        canvas.drawPath(rsiPath, Paint()..color = const Color(0xFFBA68C8)..strokeWidth = 2.0..style = PaintingStyle.stroke);
      } else if (indicatorId == 'macd') {
        // MACD Histogram Bars & Lines
        final midY = subTop + subHeight * 0.5;
        for (int i = 0; i < count; i++) {
          final x = i * candleWidth + candleWidth * 0.5;
          final diff = (i - 7) * 2.0;
          final isPos = diff >= 0;
          final barColor = isPos ? const Color(0xFF00E676) : const Color(0xFFFF5252);
          canvas.drawRect(
            Rect.fromLTRB(x - 3, min(midY, midY - diff), x + 3, max(midY, midY - diff)),
            Paint()..color = barColor,
          );
        }
        // MACD & Signal line
        final macdPath = Path();
        final sigPath = Path();
        for (int i = 0; i < count; i++) {
          final x = i * candleWidth + candleWidth * 0.5;
          final my = midY - (i - 7) * 1.8;
          final sy = midY - (i - 9) * 1.3;
          if (i == 0) {
            macdPath.moveTo(x, my);
            sigPath.moveTo(x, sy);
          } else {
            macdPath.lineTo(x, my);
            sigPath.lineTo(x, sy);
          }
        }
        canvas.drawPath(macdPath, Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 1.8..style = PaintingStyle.stroke);
        canvas.drawPath(sigPath, Paint()..color = const Color(0xFFFFB300)..strokeWidth = 1.8..style = PaintingStyle.stroke);
      } else {
        // Other Oscillators
        final subP = Path();
        for (int i = 0; i < count; i++) {
          final x = i * candleWidth + candleWidth * 0.5;
          final y = subTop + subHeight * 0.5 + sin(i * 0.4) * (subHeight * 0.35);
          if (i == 0) {
            subP.moveTo(x, y);
          } else {
            subP.lineTo(x, y);
          }
        }
        canvas.drawPath(subP, Paint()..color = primaryColor..strokeWidth = 2.0..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant VirtualIndicatorChartPainter oldDelegate) =>
      oldDelegate.indicatorId != indicatorId || oldDelegate.isDark != isDark;
}
