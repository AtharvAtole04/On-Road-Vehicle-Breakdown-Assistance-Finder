import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_controller.dart';
import '../models/wallet_transaction.dart';

class WalletController extends GetxController {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final AuthController _auth = Get.find<AuthController>();

  RxDouble balance = 0.0.obs;
  RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    listenToWallet();
  }

  void listenToWallet() {
    final uid = _auth.appUser.value?.uid;
    if (uid == null) return;

    _fire.collection('users').doc(uid).snapshots().listen((snap) {
      if (snap.exists) {
        balance.value = (snap.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
      }
    });

    _fire.collection('transactions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((doc) => WalletTransaction.fromMap(doc.data())).toList();
      // Sort in memory to avoid missing index error
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      transactions.value = list;
    });
  }

  Future<void> addFunds(double amount) async {
    final uid = _auth.appUser.value?.uid;
    if (uid == null) return;

    final docRef = _fire.collection('transactions').doc();
    final transaction = WalletTransaction(
      id: docRef.id,
      userId: uid,
      amount: amount,
      type: 'credit',
      timestamp: DateTime.now(),
    );

    await _fire.runTransaction((tx) async {
      tx.set(docRef, transaction.toMap());
      tx.update(_fire.collection('users').doc(uid), {
        'walletBalance': FieldValue.increment(amount),
      });
    });
  }

  Future<bool> payForService(String orderId, double amount) async {
    final uid = _auth.appUser.value?.uid;
    if (uid == null) return false;

    if (balance.value < amount) {
      Get.snackbar('Insufficient Balance', 'Please add funds to your wallet.');
      return false;
    }

    final docRef = _fire.collection('transactions').doc();
    final mechanicTxRef = _fire.collection('transactions').doc();
    final transaction = WalletTransaction(
      id: docRef.id,
      userId: uid,
      amount: amount,
      type: 'debit',
      orderId: orderId,
      timestamp: DateTime.now(),
    );

    await _fire.runTransaction((tx) async {
      final orderRef = _fire.collection('orders').doc(orderId);
      final orderSnap = await tx.get(orderRef);
      final helperId = orderSnap.data()?['helperId'] as String?;

      tx.set(docRef, transaction.toMap());
      tx.update(_fire.collection('users').doc(uid), {
        'walletBalance': FieldValue.increment(-amount),
      });
      if (helperId != null && helperId.isNotEmpty) {
        final mechanicTransaction = WalletTransaction(
          id: mechanicTxRef.id,
          userId: helperId,
          amount: amount,
          type: 'credit',
          orderId: orderId,
          timestamp: DateTime.now(),
        );

        tx.set(mechanicTxRef, mechanicTransaction.toMap());
        tx.update(_fire.collection('users').doc(helperId), {
          'walletBalance': FieldValue.increment(amount),
        });
      }

      tx.update(orderRef, {
        'status': 'paid',
      });
    });

    return true;
  }
}
