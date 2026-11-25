import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<UserModel> appUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _handleAuthChanged);
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (user == null) {
      appUser.value = null;
      Get.offAllNamed(Routes.LOGIN);
    } else {
      final doc = await _fire.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Force admin role for this specific email
        if (user.email == 'admin@gmail.com') {
          data['role'] = 'admin';
        }
        appUser.value = UserModel.fromMap({...data, 'uid': user.uid});
        if (appUser.value!.role == 'admin') {
          Get.offAllNamed(Routes.ADMIN_DASHBOARD);
        } else if (appUser.value!.role == 'mechanic') {
          if (appUser.value!.isApproved) {
            Get.offAllNamed(Routes.MECHANIC_DASHBOARD);
          } else {
            Get.offAllNamed(Routes.WAITING_APPROVAL);
          }
        } else {
          Get.offAllNamed(Routes.USER_HOME);
        }
      } else {
        // If user doc missing, create a default
        final isAdmin = user.email == 'admin@gmail.com';
        final userMap = {
          'uid': user.uid,
          'name': user.displayName ?? 'Admin',
          'email': user.email,
          'role': isAdmin ? 'admin' : 'user',
          'isApproved': isAdmin,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _fire.collection('users').doc(user.uid).set(userMap);
        appUser.value = UserModel.fromMap(userMap);
        if (isAdmin) {
          Get.offAllNamed(Routes.ADMIN_DASHBOARD);
        } else {
          Get.offAllNamed(Routes.USER_HOME);
        }
      }
    }
  }

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    String? garageName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;
      final userMap = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isApproved': role == 'admin', // Admins are approved by default
        'garageName': garageName,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _fire.collection('users').doc(uid).set(userMap);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
