import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class DataRepository {
  Stream<List<Map<String, dynamic>>> watch(String collection);

  Future<void> write(String collection, String id, Map<String, dynamic> data);

  Future<void> delete(String collection, String id);
}

class FirestoreRepository implements DataRepository {
  final FirebaseFirestore _firestore;
  final String uid;

  FirestoreRepository(this._firestore, this.uid);

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _firestore.collection('users').doc(uid).collection(name);

  @override
  Stream<List<Map<String, dynamic>>> watch(String collection) =>
      _collection(collection).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
                .toList(),
          );

  @override
  Future<void> write(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) =>
      _collection(collection).doc(id).set(data, SetOptions(merge: true));

  @override
  Future<void> delete(String collection, String id) =>
      _collection(collection).doc(id).delete();
}

class CurrentUserRepository implements DataRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CurrentUserRepository(this._firestore, this._auth);

  CollectionReference<Map<String, dynamic>>? _collection(String name) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection(name);
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(String collection) {
    final reference = _collection(collection);
    if (reference == null) return Stream.value(<Map<String, dynamic>>[]);
    return reference.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  @override
  Future<void> write(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final reference = _collection(collection);
    if (reference == null) return;
    await reference.doc(id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String collection, String id) async {
    final reference = _collection(collection);
    if (reference == null) return;
    await reference.doc(id).delete();
  }
}

class InMemoryRepository implements DataRepository {
  final Duration initialDelay;
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers =
      {};

  InMemoryRepository({this.initialDelay = Duration.zero});

  StreamController<List<Map<String, dynamic>>> _controller(String collection) {
    final existing = _controllers[collection];
    if (existing != null) return existing;
    late final StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        if (initialDelay == Duration.zero) {
          controller.add(_snapshot(collection));
        } else {
          Future<void>.delayed(
            initialDelay,
            () => controller.add(_snapshot(collection)),
          );
        }
      },
    );
    _controllers[collection] = controller;
    return controller;
  }

  List<Map<String, dynamic>> _snapshot(String collection) =>
      (_data[collection] ?? {}).values
          .map((value) => Map<String, dynamic>.from(value))
          .toList();

  void _emit(String collection) {
    final controller = _controllers[collection];
    if (controller != null && !controller.isClosed) {
      controller.add(_snapshot(collection));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(String collection) =>
      _controller(collection).stream;

  @override
  Future<void> write(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final bucket = _data.putIfAbsent(collection, () => {});
    bucket[id] = <String, dynamic>{'id': id, ...data};
    _emit(collection);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
    _emit(collection);
  }

  void seed(String collection, String id, Map<String, dynamic> data) {
    final bucket = _data.putIfAbsent(collection, () => {});
    bucket[id] = <String, dynamic>{'id': id, ...data};
  }
}

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().millisecond}';
