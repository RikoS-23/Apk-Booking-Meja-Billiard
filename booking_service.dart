import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final _db = FirebaseFirestore.instance;

  Future<String> buatBooking({
  required DateTime mulai,
  required DateTime selesai,
  required String namaUser,
  required String tipeMeja,
  required String mejaId,
  required String namaMeja,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // CEK KONFLIK
  final konflik = await _db
      .collection('booking')
      .where('mejaId', isEqualTo: mejaId)
      .where('status', whereIn: ['pending', 'confirmed'])
      .get();

  for (var doc in konflik.docs) {
    final b = doc.data();
    final bMulai = (b['tanggalMulai'] as Timestamp).toDate();
    final bSelesai = (b['tanggalSelesai'] as Timestamp).toDate();

    if (mulai.isBefore(bSelesai) && selesai.isAfter(bMulai)) {
      throw Exception("Meja sudah dibooking di waktu tersebut");
    }
  }

  // SIMPAN BOOKING
  final docRef = await _db.collection('booking').add({
    'userId': uid,
    'namaUser': namaUser,
    'mejaId': mejaId,
    'tipeMeja': tipeMeja, 
    'namaMeja': namaMeja,
    'tanggalMulai': mulai,
    'tanggalSelesai': selesai,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });

  return docRef.id; 
}

}
