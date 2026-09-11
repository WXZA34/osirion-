import 'package:firebase_database/firebase_database.dart';

class DuelSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  late DatabaseReference _duelRef;
  late String _duelId;
  late String _userId;
  late String _opponentId;

  // Streams for listening to opponent changes
  Stream<DatabaseEvent>? opponentStream;

  void initializeDuel(String duelId, String currentUserId, String opponentUserId) {
    _duelId = duelId;
    _userId = currentUserId;
    _opponentId = opponentUserId;
    
    _duelRef = _db.ref('duels/$_duelId');
    
    // Set initial state
    _duelRef.child('players/$_userId').set({
      'reps': 0,
      'status': 'ready',
      'last_updated': ServerValue.timestamp,
    });

    // Listen to opponent's node
    opponentStream = _duelRef.child('players/$_opponentId').onValue;
  }

  Future<void> sendRep(int repCount) async {
    await _duelRef.child('players/$_userId').update({
      'reps': repCount,
      'last_updated': ServerValue.timestamp,
    });
  }

  Future<void> leaveDuel() async {
    await _duelRef.child('players/$_userId/status').set('left');
  }
}
