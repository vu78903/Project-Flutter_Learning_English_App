import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../models/app_user.dart';

class UserDatabase {
  UserDatabase({File? databaseFile})
    : _databaseFile =
          databaseFile ??
          File('${Directory.systemTemp.path}/lexigo_users.json');

  final File _databaseFile;

  Future<List<AppUser>> getUsers() async {
    if (FirebaseService.isEnabled) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalEXP', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AppUser.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    }

    await _seedDefaultUsersIfNeeded();

    final rawData = await _databaseFile.readAsString();
    final usersJson = jsonDecode(rawData) as List<dynamic>;

    return usersJson
        .map((userJson) => AppUser.fromJson(userJson as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser?> findByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (FirebaseService.isEnabled) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final doc = snapshot.docs.first;
      return AppUser.fromJson({'id': doc.id, ...doc.data()});
    }

    final users = await getUsers();

    for (final user in users) {
      if (user.email.toLowerCase() == normalizedEmail) {
        return user;
      }
    }

    return null;
  }

  Future<void> insertUser(AppUser user) async {
    if (FirebaseService.isEnabled) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(user.copyWith(email: user.email.trim().toLowerCase()).toJson());
      return;
    }

    final users = await getUsers();
    users.add(user.copyWith(email: user.email.trim().toLowerCase()));
    await _saveUsers(users);
  }

  Future<void> updateUser(AppUser updatedUser) async {
    if (FirebaseService.isEnabled) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.id)
          .set(updatedUser.toJson(), SetOptions(merge: true));
      return;
    }

    final users = await getUsers();
    final updatedUsers = [
      for (final user in users)
        if (user.id == updatedUser.id) updatedUser else user,
    ];
    await _saveUsers(updatedUsers);
  }

  Future<void> _seedDefaultUsersIfNeeded() async {
    if (!await _databaseFile.exists()) {
      await _databaseFile.create(recursive: true);
      await _saveUsers(_defaultUsers());
      return;
    }

    final rawData = await _databaseFile.readAsString();
    final usersJson = jsonDecode(rawData) as List<dynamic>;
    final users = usersJson
        .map((userJson) => AppUser.fromJson(userJson as Map<String, dynamic>))
        .toList();
    var hasChanged = false;

    for (final defaultUser in _defaultUsers()) {
      final exists = users.any(
        (user) => user.email.toLowerCase() == defaultUser.email.toLowerCase(),
      );
      if (!exists) {
        users.add(defaultUser);
        hasChanged = true;
      }
    }

    if (hasChanged) {
      await _saveUsers(users);
    }
  }

  List<AppUser> _defaultUsers() {
    return [
      AppUser(
        id: 'admin-001',
        fullName: 'Quản trị viên LexiGo',
        email: 'admin@lexigo.com',
        password: 'admin123',
        role: UserRole.admin,
        totalExp: 0,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        currentStreak: 0,
        lastStudyDate: null,
      ),
      AppUser(
        id: 'user-anh-vu-001',
        fullName: 'Anh Vu',
        email: 'vu78903@gmail.com',
        password: 'anhvu123',
        role: UserRole.user,
        totalExp: 780,
        isActive: true,
        createdAt: DateTime(2026, 5, 16),
        currentStreak: 5,
        lastStudyDate: DateTime(2026, 5, 16),
      ),
    ];
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final encoder = const JsonEncoder.withIndent('  ');
    await _databaseFile.writeAsString(
      encoder.convert(users.map((user) => user.toJson()).toList()),
    );
  }
}
