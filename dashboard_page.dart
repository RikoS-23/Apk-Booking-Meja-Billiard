// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final User user;
  late final Timestamp nowTs;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
    nowTs = Timestamp.fromDate(DateTime.now());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat pagi";
    if (hour < 18) return "Selamat siang";
    return "Selamat malam";
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// ===== HEADER =====
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            final nama = snapshot.hasData && snapshot.data!.data() != null
                ? (snapshot.data!.data() as Map<String, dynamic>)['nama'] ??
                      'User'
                : 'User';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E4D8C), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_greeting()},",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Gass mii booking meja billiard 🎱",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        /// ===== BOOKING AKTIF =====
        const Text(
          "Booking Aktif",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('booking')
              .where('userId', isEqualTo: user.uid)
              .where('status', whereIn: ['pending', 'confirmed'])
              .where('tanggalMulai', isLessThanOrEqualTo: Timestamp.now())
              .where('tanggalSelesai', isGreaterThan: Timestamp.now())
              .orderBy('tanggalMulai')
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loadingCard();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _emptyBookingCard();
            }

            final data =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final mulai = (data['tanggalMulai'] as Timestamp).toDate();
            final selesai = (data['tanggalSelesai'] as Timestamp).toDate();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_bar, size: 40, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['namaMeja'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_jam(mulai)} - ${_jam(selesai)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      data['status'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        /// ===== MENU CEPAT =====
        const Text(
          "Menu Cepat",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            _menuCard(
              icon: Icons.table_bar,
              label: "Pesan Meja",
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            _menuCard(
              icon: Icons.history,
              label: "Riwayat",
              color: Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 24),

        /// ===== REKOMENDASI =====
        const Text(
          "Rekomendasi Meja Favorit",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _RekomendasiMejaSection(userId: user.uid),
      ],
    );
  }

  static String _jam(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  Widget _menuCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _emptyBookingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: const [
          Icon(Icons.event_busy, color: Colors.grey),
          SizedBox(width: 12),
          Text("Tidak ada booking aktif"),
        ],
      ),
    );
  }
}

/// ================= REKOMENDASI SECTION =================

class _RekomendasiMejaSection extends StatelessWidget {
  final String userId;

  const _RekomendasiMejaSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meja')
          .where('aktif', isEqualTo: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("Belum ada rekomendasi meja");
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _RekomendasiMejaCard(
              nama: data['namaMeja'],
              tipe: data['tipe'],
              harga: data['hargaPerJam'],
              image: data['meja'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      mejaId: doc.id,
                      namaMeja: data['namaMeja'],
                      tipeMeja: data['tipe'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// ================= CARD =================

class _RekomendasiMejaCard extends StatelessWidget {
  final String nama;
  final String tipe;
  final int harga;
  final String image;
  final VoidCallback onTap;

  const _RekomendasiMejaCard({
    required this.nama,
    required this.tipe,
    required this.harga,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.asset(
                'assets/images/$image',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipe,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rp $harga / Jam",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E4D8C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
