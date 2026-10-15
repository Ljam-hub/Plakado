import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/vehicle_registration.dart';
import '../models/scan_log_model.dart';
import '../models/visitor_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _vehiclesCol =>
      _firestore.collection('vehicles');
  CollectionReference<Map<String, dynamic>> get _logsCol =>
      _firestore.collection('gate_logs');
  CollectionReference<Map<String, dynamic>> get _visitorsCol =>
      _firestore.collection('visitors');

  // --- USER PROFILE ---
  Future<void> saveUser(UserProfile user) async {
    try {
      await _usersCol.doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Gracefully handled if offline
    }
  }

  Future<UserProfile?> getUser(String userId) async {
    try {
      final doc = await _usersCol.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  // --- VEHICLES ---
  Future<void> saveVehicle(VehicleRegistration vehicle) async {
    try {
      await _vehiclesCol.doc(vehicle.id).set(vehicle.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Gracefully handled
    }
  }

  Stream<List<VehicleRegistration>> streamVehicles() {
    return _vehiclesCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => VehicleRegistration.fromJson(doc.data())).toList();
    });
  }

  Future<List<VehicleRegistration>> fetchVehicles() async {
    try {
      final snapshot = await _vehiclesCol.get();
      return snapshot.docs.map((doc) => VehicleRegistration.fromJson(doc.data())).toList();
    } catch (_) {
      return [];
    }
  }

  // --- GATE SCAN LOGS ---
  Future<void> saveGateLog(ScanLogModel log) async {
    try {
      await _logsCol.doc(log.id).set(log.toJson());
    } catch (e) {
      // Gracefully handled
    }
  }

  Stream<List<ScanLogModel>> streamGateLogs() {
    return _logsCol
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ScanLogModel.fromJson(doc.data())).toList();
    });
  }

  Future<List<ScanLogModel>> fetchGateLogs() async {
    try {
      final snapshot = await _logsCol.orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) => ScanLogModel.fromJson(doc.data())).toList();
    } catch (_) {
      return [];
    }
  }

  // --- VISITORS ---
  Future<void> saveVisitor(VisitorModel visitor) async {
    try {
      await _visitorsCol.doc(visitor.id).set(visitor.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Gracefully handled
    }
  }

  Stream<List<VisitorModel>> streamVisitors() {
    return _visitorsCol
        .orderBy('entryTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => VisitorModel.fromJson(doc.data())).toList();
    });
  }
}
