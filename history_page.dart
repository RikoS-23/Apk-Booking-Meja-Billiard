// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Riwayat Booking",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E4D8C),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _HistorySkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada riwayat booking",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;

              final imagePath =
                  (data['meja'] != null && data['meja'].toString().isNotEmpty)
                  ? 'assets/images/${data['meja']}.jpg'
                  : 'assets/images/meja1.jpg';

              final status = (data['status'] ?? 'pending').toString();
              final namaMeja = data['namaMeja'] ?? 'Meja';

              return GestureDetector(
                onTap: () {
                  // Buka halaman detail booking
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingDetailPage(data: data, imagePath: imagePath),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('meja')
                              .doc(data['mejaId'])
                              .get(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                              );
                            }

                            final mejaData =
                                snap.data!.data() as Map<String, dynamic>;
                            final image = mejaData['meja'] ?? 'meja1.jpg';

                            return Image.asset(
                              'assets/images/$image',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              namaMeja,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _StatusBadge(status: status),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Halaman detail booking
class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String imagePath;

  const BookingDetailPage({
    super.key,
    required this.data,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final mejaId = data['mejaId'];

    final mulai = (data['tanggalMulai'] as Timestamp).toDate();
    final selesai = (data['tanggalSelesai'] as Timestamp).toDate();
    final durasi = selesai.difference(mulai).inHours;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Detail Booking"),
        backgroundColor: const Color(0xFF1E4D8C),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('meja').doc(mejaId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meja = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// ================= IMAGE HEADER =================
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/${meja['meja']}',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Text(
                        meja['namaMeja'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ================= INFO CARD =================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      icon: Icons.category,
                      label: "Tipe Meja",
                      value: meja['tipe'],
                    ),
                    const Divider(height: 24),

                    _infoRow(
                      icon: Icons.payments,
                      label: "Harga",
                      value: "Rp ${meja['hargaPerJam']} / Jam",
                      valueColor: const Color(0xFF1E4D8C),
                    ),
                    const Divider(height: 24),

                    _infoRow(
                      icon: Icons.calendar_today,
                      label: "Tanggal",
                      value:
                          "${mulai.day.toString().padLeft(2, '0')}/"
                          "${mulai.month.toString().padLeft(2, '0')}/"
                          "${mulai.year}",
                    ),
                    const Divider(height: 24),

                    _infoRow(
                      icon: Icons.access_time,
                      label: "Waktu",
                      value: "${_jam(mulai)} - ${_jam(selesai)}",
                    ),
                    const Divider(height: 24),

                    _infoRow(
                      icon: Icons.timelapse,
                      label: "Durasi",
                      value: "$durasi jam",
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ================= HELPER =================
  static String _jam(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black87,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E4D8C)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Status Badge
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = "Confirmed";
        break;
      case 'pending':
        color = Colors.orange;
        label = "Pending";
        break;
      default:
        color = Colors.red;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Skeleton loading
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
