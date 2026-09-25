import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/grid_config.dart';
import '../models/trade_order.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  /// 그리드 봇 설정 저장
  Future<void> saveConfig(GridConfig config) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('bot_settings')
          .doc('current')
          .set(config.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('saveConfig firestore error: $e');
    }
  }

  /// 그리드 봇 설정 불러오기
  Future<GridConfig?> loadConfig() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('bot_settings')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        return GridConfig.fromMap(doc.data()!);
      }
    } catch (e) {
      print('loadConfig firestore error: $e');
    }
    return null;
  }

  /// 주문 기록 저장
  Future<void> logOrder(TradeOrder order) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('orders')
          .doc(order.orderId)
          .set(order.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('logOrder firestore error: $e');
    }
  }

  /// 백테스트 결과 저장
  Future<void> saveBacktestRecord(Map<String, dynamic> record) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('backtest_history')
          .add({
        ...record,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('saveBacktestRecord firestore error: $e');
    }
  }
}
