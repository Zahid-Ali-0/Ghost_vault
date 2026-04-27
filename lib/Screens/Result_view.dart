import 'package:Ghost_Vault/Screens/secret_massage.dart';
import 'package:Ghost_Vault/widgets/custom_textfield.dart';
import 'package:Ghost_Vault/widgets/tose_massage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _docIDController = TextEditingController();
  bool isLoading = false;

  Future<void> _viewSecret() async {
    String link = _docIDController.text.trim();
    String password = _passwordController.text.trim();

    if (link.isEmpty || password.isEmpty) {
      context.showError("Enter BOTH link and password");
      return;
    }

    try {
      setState(() => isLoading = true);

      /// 🔥 Extract docId safely
      String docId = link.contains("/") ? link.split("/").last : link;

      if (docId.isEmpty) {
        context.showError("Invalid link");
        return;
      }

      final ref =
          FirebaseFirestore.instance.collection('secrets_data').doc(docId);

      /// 🔥 TRANSACTION (SECURE)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception("Secret not found");
        }

        final data = snapshot.data()!;

        /// 🔐 Password check
        if (data['password'] != password) {
          throw Exception("Invalid password");
        }

        /// ⏰ Expiry check
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        if (DateTime.now().isAfter(expiresAt)) {
          throw Exception("Expired");
        }

        /// 👁️ Views check
        int views = data['views'] ?? 0;
        int maxViews = data['maxViews'] ?? 1;

        if (views >= maxViews) {
          throw Exception("Max views reached");
        }

        /// ✅ Increment safely
        transaction.update(ref, {"views": views + 1});
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewSecretScreen(
            docId: docId,
            password: password,
          ),
        ),
      );
      _passwordController.clear();

      _docIDController.clear();
    } catch (e) {
      context.showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("lib/Assets/Group 49.png"),
                const SizedBox(height: 16),
                const Text(
                  "GHOST TRANSFER",
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "View your secret message & file",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "View remaining: ?",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _passwordController,
                  hint: "Enter your secret password",
                  obscure: false,
                ),
                const SizedBox(height: 5),
                const Text("AND", style: TextStyle(color: Colors.grey)),
                CustomTextField(
                  controller: _docIDController,
                  hint: "Enter your secret URL",
                  obscure: false,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _viewSecret,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "View my Secret",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
