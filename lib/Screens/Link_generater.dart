import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class LinkGenerater extends StatefulWidget {
  final String generatedLink;
  final String docId;

  const LinkGenerater({
    super.key,
    required this.generatedLink,
    required this.docId,
  });

  @override
  State<LinkGenerater> createState() => _LinkGeneraterState();
}

class _LinkGeneraterState extends State<LinkGenerater> {
  final GlobalKey _qrKey = GlobalKey();
  bool isDeleting = false;

  Future<void> deleteFromCloudinary(String publicId) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/ddgirrs3x/image/destroy");

    await http.post(url, body: {
      "public_id": publicId,
      "upload_preset": "secret-preset",
    });
  }

  Future<void> _deleteSecret() async {
    try {
      setState(() => isDeleting = true);

      final docRef = FirebaseFirestore.instance
          .collection('secrets_data')
          .doc(widget.docId);

      final doc = await docRef.get();

      if (doc.exists) {
        List files = doc.data()?['files'] ?? [];

        for (var file in files) {
          await deleteFromCloudinary(file['public_id']);
        }
      }

      await docRef.delete();

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint("Delete error: $e");
    } finally {
      if (mounted) setState(() => isDeleting = false);
    }
  }

  Future<void> _downloadQR() async {
    try {
      var status = await Permission.storage.request();
      if (!status.isGranted) return;

      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await ImageGallerySaverPlus.saveImage(
        pngBytes,
        name: "secure_qr_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Saved to Gallery")),
      );
    } catch (e) {
      debugPrint("QR Download Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  "lib/Assets/Group 49.png",
                  height: 60,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Send notes and files anonymously\nwith self-destruct system",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text("Your secret URL",
                            style: TextStyle(color: Colors.white)),
                        Spacer(),
                        Icon(Icons.link, color: Colors.white54),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(widget.generatedLink,
                                style: const TextStyle(color: Colors.white70)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.generatedLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Link copied!")),
                              );
                            },
                            child:
                                const Icon(Icons.copy, color: Colors.white54),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text("Access with QR code",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: widget.generatedLink,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _downloadQR,
                      child: const Column(
                        children: [
                          Icon(Icons.download, color: Colors.white),
                          SizedBox(height: 5),
                          Text("Download",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: isDeleting ? null : _deleteSecret,
                  icon: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.delete),
                  label: Text(isDeleting ? "Deleting..." : "Delete"),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Create New"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
