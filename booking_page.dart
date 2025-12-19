// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/booking_service.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  final String mejaId;
  final String namaMeja;
  final String tipeMeja;

  const BookingPage({
    super.key,
    required this.mejaId,
    required this.namaMeja,
    required this.tipeMeja,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int durasiJam = 1;
  DateTime? tanggal;
  TimeOfDay? jamMulai;

  String? mejaImagePath;

  @override
  void initState() {
    super.initState();
    _loadMejaImage();
  }

  Future<void> _loadMejaImage() async {
    final snap = await FirebaseFirestore.instance
        .collection('meja')
        .doc(widget.mejaId)
        .get();

    final data = snap.data();
    if (data != null &&
        data['meja'] != null &&
        data['meja'].toString().isNotEmpty) {
      mejaImagePath = 'assets/images/${data['meja']}';
    } else {
      mejaImagePath = 'assets/images/meja1.jpg';
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Booking Meja"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E4D8C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ================= IMAGE HEADER =================
          if (mejaImagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.asset(
                    mejaImagePath!,
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
                      widget.namaMeja,
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

          /// ================= FORM CARD =================
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
              children: [
                _fieldTile(
                  icon: Icons.calendar_today,
                  label: "Tanggal Main",
                  value: tanggal == null
                      ? "Pilih tanggal"
                      : "${tanggal!.day}-${tanggal!.month}-${tanggal!.year}",
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => tanggal = picked);
                    }
                  },
                ),

                const Divider(height: 28),

                _fieldTile(
                  icon: Icons.access_time,
                  label: "Jam Mulai",
                  value: jamMulai == null
                      ? "Pilih jam"
                      : jamMulai!.format(context),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => jamMulai = picked);
                    }
                  },
                ),

                const Divider(height: 28),

                DropdownButtonFormField<int>(
                  value: durasiJam,
                  decoration: const InputDecoration(
                    labelText: "Durasi Main",
                    prefixIcon: Icon(Icons.timelapse),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("1 Jam")),
                    DropdownMenuItem(value: 2, child: Text("2 Jam")),
                    DropdownMenuItem(value: 3, child: Text("3 Jam")),
                    DropdownMenuItem(value: 4, child: Text("4 Jam")),
                    DropdownMenuItem(value: 5, child: Text("5 Jam")),
                  ],
                  onChanged: (v) => setState(() => durasiJam = v ?? 1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          /// ================= CTA =================
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text(
                "Konfirmasi Booking & Bayar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4D8C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                if (tanggal == null || jamMulai == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tanggal dan jam wajib diisi"),
                    ),
                  );
                  return;
                }

                final mulai = DateTime(
                  tanggal!.year,
                  tanggal!.month,
                  tanggal!.day,
                  jamMulai!.hour,
                  jamMulai!.minute,
                );

                final selesai = mulai.add(Duration(hours: durasiJam));

                try {
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  final userSnap = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get();

                  final userData = userSnap.data() as Map<String, dynamic>;
                  final namaUser = userData['nama'] as String;

                  final bookingId = await BookingService().buatBooking(
                    mulai: mulai,
                    selesai: selesai,
                    namaUser: namaUser,
                    mejaId: widget.mejaId,
                    namaMeja: widget.namaMeja,
                    tipeMeja: widget.tipeMeja,
                  );

                  final mejaSnap = await FirebaseFirestore.instance
                      .collection('meja')
                      .doc(widget.mejaId)
                      .get();

                  final hargaPerJam = mejaSnap.data()?['hargaPerJam'] ?? 0;

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(
                        bookingId: bookingId,
                        mejaId: widget.mejaId,
                        namaMeja: widget.namaMeja,
                        hargaPerJam: hargaPerJam,
                        lamaMain: durasiJam,
                        totalBayar: hargaPerJam * durasiJam,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E4D8C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
