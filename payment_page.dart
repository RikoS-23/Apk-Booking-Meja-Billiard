// payment_page.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatelessWidget {
  final String bookingId;
  final String mejaId;
  final String namaMeja;
  final int hargaPerJam;
  final int lamaMain;
  final int totalBayar;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.mejaId,
    required this.namaMeja,
    required this.hargaPerJam,
    required this.lamaMain,
    required this.totalBayar,
  });

@override
Widget build(BuildContext context) {
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final primaryBlue = const Color(0xFF1E4D8C);

  return Scaffold(
    appBar: AppBar(
      title: const Text("Pembayaran Booking"),
      centerTitle: true,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue.withOpacity(0.08), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== CARD DETAIL =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Booking",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),

                  _row("Meja", namaMeja),
                  _row("Harga / Jam", currency.format(hargaPerJam)),
                  _row("Durasi", "$lamaMain Jam"),

                  const Divider(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL BAYAR",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currency.format(totalBayar),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ===== PAY BUTTON =====
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text(
                  "Bayar Sekarang",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                onPressed: () async {
                  try {
                    final bookingRef = FirebaseFirestore.instance
                        .collection('booking')
                        .doc(bookingId);

                    await bookingRef.update({
                      'status': 'confirmed',
                      'statusPembayaran': 'lunas',
                    });

                    final snap = await bookingRef.get();

                    if (!snap.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Booking tidak ditemukan"),
                        ),
                      );
                      return;
                    }

                    await bookingRef.update({
                      'status': 'confirmed',
                      'statusPembayaran': 'lunas',
                      'paidAt': FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('meja')
                        .doc(mejaId)
                        .update({'status': 'terpakai'});

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pembayaran berhasil"),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.popUntil(context, (route) => route.isFirst);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error pembayaran: $e")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
