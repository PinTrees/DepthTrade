import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/candle_data.dart';

class BitgetApiService {
  static final BitgetApiService instance = BitgetApiService._();
  BitgetApiService._();

  String apiKey = '';
  String secretKey = '';
  String passphrase = '';

  final String _baseUrl = 'https://api.bitget.com';

  void setCredentials({
    required String key,
    required String secret,
    required String pass,
  }) {
    apiKey = key.trim();
    secretKey = secret.trim();
    passphrase = pass.trim();
  }

  bool get hasCredentials =>
      apiKey.isNotEmpty && secretKey.isNotEmpty && passphrase.isNotEmpty;

  /// Bitget HMAC SHA-256 Signature 생성기
  Map<String, String> _buildHeaders(
      String method, String requestPath, String body) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    String preHash = timestamp + method.toUpperCase() + requestPath + body;
    var key = utf8.encode(secretKey);
    var bytes = utf8.encode(preHash);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    String sign = base64.encode(digest.bytes);

    return {
      'Content-Type': 'application/json',
      'ACCESS-KEY': apiKey,
      'ACCESS-SIGN': sign,
      'ACCESS-TIMESTAMP': timestamp,
      'ACCESS-PASSPHRASE': passphrase,
      'locale': 'en-US',
    };
  }

  /// 실시간 시장 가격 조회 (Bitget v2 public ticker -> fallback Binance)
  Future<double?> getMarketPrice(String symbol) async {
    try {
      // 1) Bitget v2 Mix Ticker
      final url = Uri.parse(
          '$_baseUrl/api/v2/mix/market/ticker?symbol=${symbol.toUpperCase()}&productType=USDT-FUTURES');
      final res = await http.get(url).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['code'] == '00000' && data['data'] != null) {
          final list = data['data'] as List;
          if (list.isNotEmpty && list[0]['lastPr'] != null) {
            return double.tryParse(list[0]['lastPr'].toString());
          }
        }
      }
    } catch (_) {}

    // Fallback: Binance Public Ticker (Very stable for web without CORS issues)
    try {
      final binanceSymbol = symbol.replaceAll('-', '').toUpperCase();
      final url = Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=$binanceSymbol');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['price'] != null) {
          return double.tryParse(data['price'].toString());
        }
      }
    } catch (_) {}

    return null;
  }

  /// 오더북 호가창 (Bids / Asks Depth)
  Future<Map<String, List<List<double>>>> getOrderBook(String symbol) async {
    try {
      final binanceSymbol = symbol.replaceAll('-', '').toUpperCase();
      final url = Uri.parse(
          'https://api.binance.com/api/v3/depth?symbol=$binanceSymbol&limit=15');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<List<double>> bids = [];
        List<List<double>> asks = [];

        for (var item in data['bids'] ?? []) {
          bids.add([
            double.tryParse(item[0].toString()) ?? 0.0,
            double.tryParse(item[1].toString()) ?? 0.0,
          ]);
        }
        for (var item in data['asks'] ?? []) {
          asks.add([
            double.tryParse(item[0].toString()) ?? 0.0,
            double.tryParse(item[1].toString()) ?? 0.0,
          ]);
        }
        return {'bids': bids, 'asks': asks};
      }
    } catch (_) {}
    return {'bids': [], 'asks': []};
  }

  /// 캔들스틱 데이터 조회 (차트 및 백테스팅용)
  Future<List<CandleData>> getCandles(
      String symbol, String interval, int limit) async {
    try {
      final binanceSymbol = symbol.replaceAll('-', '').toUpperCase();
      // interval: 1m, 5m, 15m, 1h, 4h, 1d
      final url = Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$binanceSymbol&interval=$interval&limit=$limit');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((item) => CandleData.fromBinanceList(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 실제 Bitget 계좌 잔고 조회 (API Key 필요)
  Future<Map<String, dynamic>?> getAccountDetail(String symbol) async {
    if (!hasCredentials) return null;

    try {
      final path =
          '/api/v2/mix/account/account?symbol=$symbol&productType=USDT-FUTURES';
      final headers = _buildHeaders('GET', path, '');
      final res = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['code'] == '00000') {
          return data['data'];
        }
      }
    } catch (e) {
      print('getAccountDetail error: $e');
    }
    return null;
  }

  /// 실제 Bitget 주문 생성 (API Key 필요)
  Future<Map<String, dynamic>?> placeOrder({
    required String symbol,
    required String side, // 'buy' or 'sell'
    required String orderType, // 'limit' or 'market'
    required double price,
    required double size,
    required String clientOid,
  }) async {
    if (!hasCredentials) return null;

    try {
      const path = '/api/v2/mix/order/place-order';
      final bodyMap = {
        'symbol': symbol,
        'productType': 'USDT-FUTURES',
        'marginMode': 'crossed',
        'marginCoin': 'USDT',
        'size': size.toString(),
        'price': price.toString(),
        'side': side,
        'orderType': orderType,
        'clientOid': clientOid,
      };
      final bodyStr = jsonEncode(bodyMap);
      final headers = _buildHeaders('POST', path, bodyStr);

      final res = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: bodyStr,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data;
      }
    } catch (e) {
      print('placeOrder error: $e');
    }
    return null;
  }

  /// 실제 Bitget 주문 일괄 취소 (긴급 주문 취소 - TR_CloseLiveOrders)
  Future<bool> cancelAllOrders(String symbol) async {
    if (!hasCredentials) return false;

    try {
      const path = '/api/v2/mix/order/cancel-all-orders';
      final bodyMap = {
        'symbol': symbol,
        'productType': 'USDT-FUTURES',
        'marginCoin': 'USDT',
      };
      final bodyStr = jsonEncode(bodyMap);
      final headers = _buildHeaders('POST', path, bodyStr);

      final res = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: bodyStr,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['code'] == '00000';
      }
    } catch (e) {
      print('cancelAllOrders error: $e');
    }
    return false;
  }

  /// API 연결 테스트
  Future<bool> testConnection([String symbol = 'BTCUSDT']) async {
    final detail = await getAccountDetail(symbol);
    return detail != null;
  }
}
