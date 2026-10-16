import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/vehicle_registration.dart';
import '../models/scan_log_model.dart';
import '../models/visitor_model.dart';

class FirestoreService {
  static const String projectId = 'plakado-security-2026';
  static const String apiKey = 'AIzaSyBzLxM-P_91bN_HkAkIYxHY05xU7vbCL68';
  static const String restBaseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  final FirebaseFirestore? _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (kIsWeb ? null : FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>>? get _usersCol =>
      _firestore?.collection('users');
  CollectionReference<Map<String, dynamic>>? get _vehiclesCol =>
      _firestore?.collection('vehicles');
  CollectionReference<Map<String, dynamic>>? get _logsCol =>
      _firestore?.collection('gate_logs');
  CollectionReference<Map<String, dynamic>>? get _visitorsCol =>
      _firestore?.collection('visitors');

  // --- REST SERIALIZATION HELPERS ---
  static Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> rawJson) {
    final fields = <String, dynamic>{};
    rawJson.forEach((key, value) {
      if (value == null) {
        fields[key] = {'nullValue': null};
      } else if (value is String) {
        fields[key] = {'stringValue': value};
      } else if (value is int) {
        fields[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        fields[key] = {'doubleValue': value};
      } else if (value is bool) {
        fields[key] = {'booleanValue': value};
      } else if (value is List) {
        fields[key] = {
          'arrayValue': {
            'values': value.map((v) => {'stringValue': v.toString()}).toList()
          }
        };
      } else if (value is Map) {
        fields[key] = {
          'mapValue': {
            'fields': _toFirestoreFields(Map<String, dynamic>.from(value))
          }
        };
      }
    });
    return fields;
  }

  static Map<String, dynamic> _fromFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        if (val.containsKey('stringValue')) {
          result[key] = val['stringValue'];
        } else if (val.containsKey('integerValue')) {
          result[key] = int.tryParse(val['integerValue'].toString()) ?? 0;
        } else if (val.containsKey('doubleValue')) {
          result[key] = (val['doubleValue'] as num).toDouble();
        } else if (val.containsKey('booleanValue')) {
          result[key] = val['booleanValue'] as bool;
        } else if (val.containsKey('nullValue')) {
          result[key] = null;
        } else if (val.containsKey('timestampValue')) {
          result[key] = val['timestampValue'];
        }
      }
    });
    return result;
  }

  // --- USER PROFILE ---
  Future<bool> saveUser(UserProfile user) async {
    bool success = false;
    // 1. Direct REST API write
    try {
      final url = Uri.parse('$restBaseUrl/users/${user.id}?key=$apiKey');
      final payload = jsonEncode({'fields': _toFirestoreFields(user.toJson())});
      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        success = true;
        debugPrint('✅ Cloud Firestore REST: User profile for ${user.email} saved.');
      } else {
        debugPrint('⚠️ Cloud Firestore REST user error: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Cloud Firestore REST saveUser note: $e');
    }

    // 2. SDK write if available
    try {
      await _usersCol?.doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (_) {}

    return success;
  }

  Future<UserProfile?> getUser(String userId) async {
    try {
      final url = Uri.parse('$restBaseUrl/users/$userId?key=$apiKey');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('fields')) {
          final fields = _fromFirestoreFields(Map<String, dynamic>.from(data['fields']));
          return UserProfile.fromJson(fields);
        }
      }
    } catch (_) {}

    try {
      final doc = await _usersCol?.doc(userId).get();
      if (doc != null && doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  // --- VEHICLES ---
  Future<bool> saveVehicle(VehicleRegistration vehicle) async {
    bool success = false;
    // 1. Direct Cloud Firestore REST API Sync (Guaranteed on Web and Mobile)
    try {
      final url = Uri.parse('$restBaseUrl/vehicles/${vehicle.id}?key=$apiKey');
      final payload = jsonEncode({'fields': _toFirestoreFields(vehicle.toJson())});
      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        success = true;
        debugPrint('✅ Cloud Firestore REST: Vehicle ${vehicle.plateNumber} successfully saved to Cloud Firestore.');
      } else {
        debugPrint('⚠️ Cloud Firestore REST saveVehicle: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Cloud Firestore REST saveVehicle exception: $e');
    }

    // 2. SDK write for realtime listeners
    try {
      await _vehiclesCol?.doc(vehicle.id).set(vehicle.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore SDK saveVehicle note: $e');
    }

    return success;
  }

  Stream<List<VehicleRegistration>> streamVehicles() {
    if (_vehiclesCol != null) {
      return _vehiclesCol!.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => VehicleRegistration.fromJson(doc.data())).toList();
      });
    }
    // Stream fallback
    return Stream.fromFuture(fetchVehicles());
  }

  Future<List<VehicleRegistration>> fetchVehicles() async {
    // 1. Direct REST fetch (fast, guaranteed, matches C# Desktop)
    try {
      final url = Uri.parse('$restBaseUrl/vehicles?key=$apiKey');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('documents') && data['documents'] is List) {
          final list = <VehicleRegistration>[];
          for (final doc in data['documents']) {
            if (doc is Map && doc.containsKey('fields')) {
              try {
                final fields = _fromFirestoreFields(Map<String, dynamic>.from(doc['fields']));
                list.add(VehicleRegistration.fromJson(fields));
              } catch (e) {
                debugPrint('Vehicle doc parse error: $e');
              }
            }
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint('Cloud Firestore REST fetchVehicles note: $e');
    }

    // 2. SDK Fallback
    try {
      if (_vehiclesCol != null) {
        final snapshot = await _vehiclesCol!.get();
        return snapshot.docs.map((doc) => VehicleRegistration.fromJson(doc.data())).toList();
      }
    } catch (_) {}

    return [];
  }

  // --- GATE SCAN LOGS ---
  Future<bool> saveGateLog(ScanLogModel log) async {
    bool success = false;
    try {
      final url = Uri.parse('$restBaseUrl/gate_logs/${log.id}?key=$apiKey');
      final payload = jsonEncode({'fields': _toFirestoreFields(log.toJson())});
      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        success = true;
        debugPrint('✅ Cloud Firestore REST: Gate log for ${log.plateNumber} saved.');
      }
    } catch (e) {
      debugPrint('Cloud Firestore REST saveGateLog note: $e');
    }

    try {
      await _logsCol?.doc(log.id).set(log.toJson());
    } catch (_) {}

    return success;
  }

  Stream<List<ScanLogModel>> streamGateLogs() {
    if (_logsCol != null) {
      return _logsCol!
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => ScanLogModel.fromJson(doc.data())).toList();
      });
    }
    return Stream.fromFuture(fetchGateLogs());
  }

  Future<List<ScanLogModel>> fetchGateLogs() async {
    try {
      final url = Uri.parse('$restBaseUrl/gate_logs?key=$apiKey');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('documents') && data['documents'] is List) {
          final list = <ScanLogModel>[];
          for (final doc in data['documents']) {
            if (doc is Map && doc.containsKey('fields')) {
              try {
                final fields = _fromFirestoreFields(Map<String, dynamic>.from(doc['fields']));
                list.add(ScanLogModel.fromJson(fields));
              } catch (_) {}
            }
          }
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        }
      }
    } catch (_) {}

    try {
      if (_logsCol != null) {
        final snapshot = await _logsCol!.orderBy('timestamp', descending: true).get();
        return snapshot.docs.map((doc) => ScanLogModel.fromJson(doc.data())).toList();
      }
    } catch (_) {}

    return [];
  }

  // --- VISITORS ---
  Future<bool> saveVisitor(VisitorModel visitor) async {
    bool success = false;
    try {
      final url = Uri.parse('$restBaseUrl/visitors/${visitor.id}?key=$apiKey');
      final payload = jsonEncode({'fields': _toFirestoreFields(visitor.toJson())});
      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        success = true;
      }
    } catch (_) {}

    try {
      await _visitorsCol?.doc(visitor.id).set(visitor.toJson(), SetOptions(merge: true));
    } catch (_) {}

    return success;
  }

  Stream<List<VisitorModel>> streamVisitors() {
    if (_visitorsCol != null) {
      return _visitorsCol!
          .orderBy('entryTime', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => VisitorModel.fromJson(doc.data())).toList();
      });
    }
    return const Stream.empty();
  }
}

