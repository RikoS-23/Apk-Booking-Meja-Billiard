// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_page.dart';

class MejaPage extends StatefulWidget {
  const MejaPage({super.key});

  @override
  State<MejaPage> createState() => _MejaPageState();
}

class _MejaPageState extends State<MejaPage> {
  String filter = 'Semua'; // filter profesional

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Pilih Meja',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E4D8C), // Tournament Blue
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ===== FILTER PROFESIONAL =====
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Semua"),
                  selected: filter == 'Semua',
                  selectedColor: const Color(0xFF1E4D8C),
                  backgroundColor: Colors.grey.shade300,
                  labelStyle: TextStyle(
                      color: filter == 'Semua' ? Colors.white : Colors.black),
                  onSelected: (_) => setState(() => filter = 'Semua'),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Tersedia"),
                  selected: filter == 'Tersedia',
                  selectedColor: const Color(0xFF1E4D8C),
                  backgroundColor: Colors.grey.shade300,
                  labelStyle: TextStyle(
                      color: filter == 'Tersedia' ? Colors.white : Colors.black),
                  onSelected: (_) => setState(() => filter = 'Tersedia'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('meja').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SkeletonGrid();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text(
                    "Tidak ada meja",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ));
                }

                final mejaDocs = snapshot.data!.docs.where((doc) {
                  if (filter == 'Semua') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == null || data['status'] == '';
                }).toList();

                if (mejaDocs.isEmpty) {
                  return const Center(
                      child: Text(
                    "Semua meja sedang terpakai",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ));
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: mejaDocs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final doc = mejaDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tersedia =
                        data['status'] == null || data['status'].toString().isEmpty;
                    final imagePath =
                        (data['meja'] != null && data['meja'] != '')
                            ? 'assets/images/${data['meja']}'
                            : 'assets/images/meja1.jpg';
                    final harga = (data['hargaPerJam'] ?? '-').toString();

                    return _AnimatedMejaCard(
                      tersedia: tersedia,
                      imagePath: imagePath,
                      namaMeja: data['namaMeja'] ?? 'Meja',
                      tipe: data['tipe'] ?? '-',
                      harga: harga,
                      onTap: tersedia
                          ? () async {
                              await FirebaseFirestore.instance
                                  .collection('meja')
                                  .doc(doc.id)
                                  .update({'status': 'terpakai'});

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingPage(
                                    mejaId: doc.id,
                                    namaMeja: data['namaMeja'] ?? 'Meja',
                                    tipeMeja: data['tipe'] ?? '',
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================
   ANIMATED MEJA CARD
======================= */
class _AnimatedMejaCard extends StatelessWidget {
  final bool tersedia;
  final String imagePath;
  final String namaMeja;
  final String tipe;
  final String harga;
  final VoidCallback? onTap;

  const _AnimatedMejaCard({
    required this.tersedia,
    required this.imagePath,
    required this.namaMeja,
    required this.tipe,
    required this.harga,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: tersedia ? 1 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (!tersedia)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: const Text(
                            "TERPAKAI",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      namaMeja,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Tipe: $tipe",
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      "Rp $harga / jam",
                      style: const TextStyle(
                        color: Color(0xFF1E4D8C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =======================
   SKELETON LOADING
======================= */
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
