import 'package:flutter/material.dart';

class CryptoCoin {
  final String symbol; // 예: 'BTCUSDT'
  final String name; // 예: 'Bitcoin'
  final String koreanName; // 예: '비트코인'
  final double defaultBaseSize; // 기본 주문 크기
  final int priceDecimals; // 호가 표시 소수점
  final Color color;
  final IconData icon;

  const CryptoCoin({
    required this.symbol,
    required this.name,
    required this.koreanName,
    required this.defaultBaseSize,
    required this.priceDecimals,
    required this.color,
    required this.icon,
  });

  String get displaySymbol => symbol.replaceFirst('USDT', '/USDT');

  static const List<CryptoCoin> popularCoins = [
    CryptoCoin(
      symbol: 'BTCUSDT',
      name: 'Bitcoin',
      koreanName: '비트코인',
      defaultBaseSize: 0.002,
      priceDecimals: 1,
      color: Color(0xFFF7931A),
      icon: Icons.currency_bitcoin,
    ),
    CryptoCoin(
      symbol: 'ETHUSDT',
      name: 'Ethereum',
      koreanName: '이더리움',
      defaultBaseSize: 0.03,
      priceDecimals: 2,
      color: Color(0xFF627EEA),
      icon: Icons.toll,
    ),
    CryptoCoin(
      symbol: 'SOLUSDT',
      name: 'Solana',
      koreanName: '솔라나',
      defaultBaseSize: 0.5,
      priceDecimals: 2,
      color: Color(0xFF14F195),
      icon: Icons.flash_on,
    ),
    CryptoCoin(
      symbol: 'XRPUSDT',
      name: 'Ripple',
      koreanName: '리플',
      defaultBaseSize: 50.0,
      priceDecimals: 4,
      color: Color(0xFF00AAE4),
      icon: Icons.waves,
    ),
    CryptoCoin(
      symbol: 'DOGEUSDT',
      name: 'Dogecoin',
      koreanName: '도지코인',
      defaultBaseSize: 200.0,
      priceDecimals: 5,
      color: Color(0xFFC2A633),
      icon: Icons.pets,
    ),
    CryptoCoin(
      symbol: 'BNBUSDT',
      name: 'BNB',
      koreanName: '바이낸스코인',
      defaultBaseSize: 0.2,
      priceDecimals: 2,
      color: Color(0xFFF3BA2F),
      icon: Icons.change_history,
    ),
    CryptoCoin(
      symbol: 'SUIUSDT',
      name: 'Sui',
      koreanName: '수이',
      defaultBaseSize: 20.0,
      priceDecimals: 4,
      color: Color(0xFF4DA2FF),
      icon: Icons.water_drop,
    ),
    CryptoCoin(
      symbol: 'ADAUSDT',
      name: 'Cardano',
      koreanName: '에이다',
      defaultBaseSize: 100.0,
      priceDecimals: 4,
      color: Color(0xFF0033AD),
      icon: Icons.scatter_plot,
    ),
    CryptoCoin(
      symbol: 'AVAXUSDT',
      name: 'Avalanche',
      koreanName: '아발란체',
      defaultBaseSize: 1.5,
      priceDecimals: 2,
      color: Color(0xFFE84142),
      icon: Icons.terrain,
    ),
  ];

  static CryptoCoin findBySymbol(String symbol) {
    return popularCoins.firstWhere(
      (c) => c.symbol.toUpperCase() == symbol.replaceAll('/', '').toUpperCase(),
      orElse: () => popularCoins.first,
    );
  }
}
