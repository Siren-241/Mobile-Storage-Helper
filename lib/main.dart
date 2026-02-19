import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      home: MediaCounterScreen(),
    );
  }
}

class MediaCounterScreen extends StatefulWidget {
  const MediaCounterScreen({super.key});

  @override
  State<MediaCounterScreen> createState() => _MediaCounterScreenState();
}

class _MediaCounterScreenState extends State<MediaCounterScreen> {
  int imageCount = 0;

  String status = "Requesting Permissions...";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      setState(() {
        status = "Permission Denied";
      });
      return;
    }

    setState(() {
      status = "Loading Images...";
    });

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // List<AssetEntity> allImages = [];
    int total = 0;

    for (final album in albums) {
      final count = await album.assetCountAsync;
      total += count;
    }

    setState(() {
      imageCount = total;
      status = "Done";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Storage Helper")),
      body: Center (
        child: Text(
          status == "Done"
              ? "Found $imageCount images"
              : status,

          style: const TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        )
      )
    );
  }
}
