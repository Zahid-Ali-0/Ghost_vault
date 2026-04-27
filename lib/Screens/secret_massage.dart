import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ViewSecretScreen extends StatefulWidget {
  final String docId;
  final String? password;

  const ViewSecretScreen({
    super.key,
    required this.docId,
    this.password,
  });

  @override
  State<ViewSecretScreen> createState() => _ViewSecretScreenState();
}

class _ViewSecretScreenState extends State<ViewSecretScreen> {
  bool isLoading = true;
  bool isValid = false;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('secrets_data')
          .doc(widget.docId)
          .get();

      if (!doc.exists) throw Exception("Not found");

      final fetched = doc.data()!;

      if ((fetched['password'] ?? "") != (widget.password ?? "")) {
        throw Exception("Invalid password");
      }

      final expiresAt = (fetched['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception("Expired");
      }

      int views = fetched['views'] ?? 0;
      int maxViews = fetched['maxViews'] ?? 1;

      if (views > maxViews) {
        throw Exception("Max views reached");
      }

      await doc.reference.update({'views': views + 1});

      if (!mounted) return;

      setState(() {
        data = fetched;
        isValid = true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
      if (!mounted) return;

      setState(() {
        isValid = false;
        isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isValid || data == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "❌ Invalid / Expired / Limit Reached",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final message = data!['message'] ?? "";
    final files = List<Map<String, dynamic>>.from(data!['files'] ?? []);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              /// LOGO + TITLE
              const SizedBox(height: 30),

              Image.asset(
                "lib/Assets/Group 49.png",
                width: 200,
              ),

              const SizedBox(height: 15),

              const Text(
                "View your secret\nmessage & file",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 30),

              /// MAIN CARD
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// MESSAGE TITLE
                      const Text(
                        "Message",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// MESSAGE BOX
                      if (message.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      /// FILES LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            return _fileCard(files[index]);
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// DONE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff8A2BE2),
                                Color(0xffD946EF),
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Done",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= FILE CARD =================
  Widget _fileCard(Map<String, dynamic> file) {
    final url = file['url'] ?? "";
    final type = (file['type'] ?? "").toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PREVIEW
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: _buildPreview(url, type),
            ),
          ),

          /// FILE INFO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                /// FILE TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Type: $type",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                /// DOWNLOAD BUTTON
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff8A2BE2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.download,
                      color: Colors.white,
                    ),
                    onPressed: () => _downloadFile(url, type),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= PREVIEW =================
  Widget _buildPreview(String url, String type) {
    if (["jpg", "jpeg", "png", "webp"].contains(type)) {
      return GestureDetector(
        onTap: () => _openImage(url),
        child: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
        ),
      );
    }

    if (["mp4", "mov"].contains(type)) {
      return VideoPreview(url: url);
    }

    return Center(
      child: ElevatedButton(
        onPressed: () => _downloadFile(url, type),
        child: const Text("Download Document"),
      ),
    );
  }

  /// ================= IMAGE FULL SCREEN =================
  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= DOWNLOAD =================
  Future<void> _downloadFile(String url, String type) async {
    try {
      /// 🔹 Request storage permission
      PermissionStatus status = await Permission.storage.request();

      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      /// 🔹 If user permanently denied permission
      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please enable storage permission in settings")),
        );
        await openAppSettings();
        return;
      }

      /// 🔹 Download file from URL
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Failed to download file");
      }

      /// 🔹 Select directory
      Directory directory;

      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/Download");
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      /// 🔹 Ensure folder exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      /// 🔹 Generate file name
      final fileName =
          "ghost_transfer_${DateTime.now().millisecondsSinceEpoch}.$type";

      final filePath = "${directory.path}/$fileName";

      final file = File(filePath);

      /// 🔹 Save file
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      /// 🔹 Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ File saved to Downloads"),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Download error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Download failed")),
      );
    }
  }
}

/// ================= VIDEO PREVIEW =================
class VideoPreview extends StatefulWidget {
  final String url;

  const VideoPreview({super.key, required this.url});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => loading = false);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoFullScreen(url: widget.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _openFullScreen,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          const Icon(Icons.play_circle, size: 60, color: Colors.white),
        ],
      ),
    );
  }
}

/// ================= VIDEO FULL SCREEN =================
class VideoFullScreen extends StatefulWidget {
  final String url;

  const VideoFullScreen({super.key, required this.url});

  @override
  State<VideoFullScreen> createState() => _VideoFullScreenState();
}

class _VideoFullScreenState extends State<VideoFullScreen> {
  late VideoPlayerController _controller;
  bool loading = true;
  bool muted = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => loading = false);
        _controller.play();
      });
  }

  void _toggleMute() {
    setState(() {
      muted = !muted;
      _controller.setVolume(muted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),

                /// CONTROLS
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              muted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                            ),
                            onPressed: _toggleMute,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
