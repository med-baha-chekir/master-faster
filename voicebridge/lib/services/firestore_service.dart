import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/call_record.dart';
import '../models/user_profile.dart';

/// Single point of access for all Firestore operations.
///
/// For the prototype we use a fixed userId ('demo_user').
/// Replace with FirebaseAuth.instance.currentUser!.uid once auth is live.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── user id ────────────────────────────────────────────────────────
  /// Dynamic user ID based on authenticaton state.
  static String get userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

  // ─── collection references ──────────────────────────────────────────
  DocumentReference get _profileDoc => _db.collection('users').doc(userId);

  CollectionReference get _callsCol =>
      _db.collection('users').doc(userId).collection('calls');

  // ══════════════════════ UserProfile ════════════════════════════════

  /// Load the profile; returns null if the document doesn't exist yet.
  Future<UserProfile?> getProfile() async {
    final snap = await _profileDoc.get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data() as Map<String, dynamic>, snap.id);
  }

  /// Create or overwrite the profile document.
  Future<void> saveProfile(UserProfile profile) async {
    await _profileDoc.set(profile.toMap(), SetOptions(merge: true));
  }

  // ══════════════════════ CallRecord ═════════════════════════════════

  /// Real-time stream of call records, newest first.
  Stream<List<CallRecord>> callsStream() {
    return _callsCol
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CallRecord.fromDoc).toList());
  }

  /// Save a new call record. Returns the generated document id.
  Future<String> saveCall(CallRecord record) async {
    final ref = await _callsCol.add(record.toMap());
    return ref.id;
  }
}
