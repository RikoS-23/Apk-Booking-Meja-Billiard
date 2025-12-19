// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final primaryBlue = const Color(0xFF1E4D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        centerTitle: true,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: Text("Data profil tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nama = data['nama'] ?? '-';
          final email = data['email'] ?? '-';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ===== HEADER PROFILE =====
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 46,
                        color: Color(0xFF1E4D8C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ===== AKUN =====
              const Text(
                "Akun",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text("Edit Profil"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showEditNamaDialog(context, uid, nama);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text("Ganti Password"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final emailUser =
                            FirebaseAuth.instance.currentUser?.email;
                        if (emailUser == null) return;

                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: emailUser);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Link reset password dikirim ke email"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ===== SISTEM =====
              const Text(
                "Sistem",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: _cardDecoration(),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// ===== DIALOG EDIT NAMA =====
  static void _showEditNamaDialog(
    BuildContext context,
    String uid,
    String namaLama,
  ) {
    final controller = TextEditingController(text: namaLama);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Nama"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nama",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Simpan"),
            onPressed: () async {
              final namaBaru = controller.text.trim();
              if (namaBaru.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'nama': namaBaru});

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Profil berhasil diperbarui")),
              );
            },
          ),
        ],
      ),
    );
  }
}
