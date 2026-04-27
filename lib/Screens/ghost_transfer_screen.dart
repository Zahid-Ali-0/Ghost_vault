import 'package:Ghost_Vault/Screens/Link_generater.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/section_title.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/upload_box.dart';
import '../widgets/file_card.dart';
import '../widgets/dropdown_tile.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GhostTransferScreen extends StatefulWidget {
  const GhostTransferScreen({super.key});

  @override
  State<GhostTransferScreen> createState() => _GhostTransferScreenState();
}

class _GhostTransferScreenState extends State<GhostTransferScreen> {
  String selectedLifetime = "5 Minutes";
  String selectedViews = "5";
  bool isLoading = false;

  final TextEditingController _messagecontroller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  List<dynamic> selectedFiles = [];

  // 🔥 Expiry Logic
  DateTime getExpiryDate(String lifetime) {
    final now = DateTime.now();

    switch (lifetime) {
      case "5 Minutes":
        return now.add(const Duration(minutes: 5));
      case "10 Minutes":
        return now.add(const Duration(minutes: 10));
      case "30 Minutes":
        return now.add(const Duration(minutes: 30));
      case "1 Hour":
        return now.add(const Duration(hours: 1));
      case "24 Hours":
        return now.add(const Duration(hours: 24));
       case "48 Hours":
        return now.add(const Duration(hours: 48));
      default:
        return now.add(const Duration(hours: 24));
        
    }
  }

  final List<String> lifetimeOptions = [    
    "5 Minutes",
    "10 Minutes",
    "30 Minutes",
    "1 Hour",
    "24 Hours",
    "48 Hours",
  ];

  final List<String> viewOptions = ["1", "5", "10", "20", "50"];

  // 🚀 MULTI FILE UPLOAD (PARALLEL)
  Future<List<Map<String, dynamic>>> uploadMultipleToCloudinary(
      List<dynamic> files) async {
    try {
      final futures = files.map((fileItem) async {
        File file = File(fileItem.path);

        final url =
            Uri.parse("https://api.cloudinary.com/v1_1/ddgirrs3x/auto/upload");

        var request = http.MultipartRequest('POST', url);
        request.fields['upload_preset'] = 'secret-preset';

        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonData = json.decode(responseData);

          return {
            "url": jsonData['secure_url'],
            "public_id": jsonData['public_id'],
            "type": fileItem.name.split('.').last,
          };
        } else {
          throw Exception("Upload failed");
        }
      }).toList();

      // 🔥 Parallel execution
      return await Future.wait(futures);
    } catch (e) {
      debugPrint("Upload error: $e");
      return [];
    }
  }

  @override
  void dispose() {
    _messagecontroller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              /// 🔹 Logo
              Image.asset("lib/Assets/Group 49.png"),
              const SizedBox(height: 20),

              /// 🔹 Subtitle
              const Text(
                "Send notes and files anonymously\nwith self-destruct system",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),

              /// 🔹 Main Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const SectionTitle("New Message"),

                    CustomTextField(
                      controller: _messagecontroller,
                      hint: "Write your message here...",
                      maxLines: 4,
                    ),

                    const SizedBox(height: 20),

                    const SectionTitle("Upload Files"),

                    UploadBox(
                      onFilesPicked: (files) {
                        setState(() {
                          selectedFiles.addAll(files);
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// 🔹 Selected Files
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.8,
                      ),
                      itemCount: selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = selectedFiles[index];

                        return FileCard(
                          fileName: file.name,
                          fileSize:
                              "${(file.size / 1024 / 1024).toStringAsFixed(2)} MB",
                          onDelete: () {
                            setState(() {
                              selectedFiles.removeAt(index);
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    /// 🔹 Lifetime
                    DropdownTile(
                      hint: "Set time",
                      title: "Lifetime",
                      value: selectedLifetime,
                      items: lifetimeOptions,
                      onChanged: (value) {
                        setState(() => selectedLifetime = value!);
                      },
                    ),

                    /// 🔹 Max Views
                    DropdownTile(
                      hint: "Set Max Views",
                      title: "Max Views",
                      value: selectedViews,
                      items: viewOptions,
                      onChanged: (value) {
                        setState(() => selectedViews = value!);
                      },
                    ),

                    const SizedBox(height: 10),

                    /// 🔹 Password
                    CustomTextField(
                      controller: _passwordController,
                      hint: "Enter Strong Password",
                      obscure: true,
                    ),

                    const SizedBox(height: 10),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      hint: "Confirm Password",
                      obscure: true,
                    ),

                    const SizedBox(height: 25),

                    /// 🔥 CREATE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                // ✅ VALIDATION
                                if (_messagecontroller.text.isEmpty &&
                                    selectedFiles.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Add message or file")),
                                  );
                                  return;
                                }

                                String password = _passwordController.text;
                                String confirmPassword =
                                    _confirmPasswordController.text;

                                if (password.isEmpty ||
                                    confirmPassword.isEmpty ||
                                    password != confirmPassword ||
                                    !RegExp(r'^(?=.*[A-Z])(?=.*[!@#$%^&*]).+$')
                                        .hasMatch(password)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Password must match, contain uppercase & special char"),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  setState(() => isLoading = true);

                                  final docRef = FirebaseFirestore.instance
                                      .collection('secrets_data')
                                      .doc();

                                  /// 🔥 MULTI FILE UPLOAD
                                  List<Map<String, dynamic>> uploadedFiles = [];

                                  if (selectedFiles.isNotEmpty) {
                                    uploadedFiles =
                                        await uploadMultipleToCloudinary(
                                            selectedFiles);

                                    if (uploadedFiles.isEmpty) {
                                      throw Exception("Upload failed");
                                    }
                                  }

                                  /// 🔥 SAVE DATA
                                  await docRef.set({
                                    "message": _messagecontroller.text,
                                    "password": password,
                                    "files": uploadedFiles,
                                    "createdAt": Timestamp.now(),
                                    "expiresAt": Timestamp.fromDate(
                                        getExpiryDate(selectedLifetime)),
                                    "views": 0,
                                    "maxViews": int.parse(selectedViews),
                                  });

                                  String generatedLink =
                                      "https://securevaulet.com/view/${docRef.id}";

                                  if (!mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LinkGenerater(
                                        generatedLink: generatedLink,
                                        docId: docRef.id,
                                      ),
                                    ),
                                  );

                                  /// 🔹 RESET
                                  _messagecontroller.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  selectedFiles.clear();
                                } catch (e) {
                                  debugPrint("Error: $e");

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Something went wrong")),
                                  );
                                } finally {
                                  if (mounted)
                                    setState(() => isLoading = false);
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Create a Secret Link",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
