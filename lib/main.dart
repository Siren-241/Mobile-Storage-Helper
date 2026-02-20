import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/media_file.dart';

late Isar isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [MediaFileSchema],
    directory: dir.path
  );

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
  int newlyIndexedMediaCount = 0;
  int totalInDB = 0;

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
      status = "Loading Media...";
    });

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image | RequestType.video,
    );

    int totalIndexed = 0;

    for (final album in albums) {
      final assetCount = await album.assetCountAsync;

      int page = 0;
      const int pageSize = 200;

      while (page * pageSize < assetCount) {
        final assets = await album.getAssetListPaged(page: page, size: pageSize);

        List<MediaFile> newMediaFiles = [];

        for (final asset in assets) {
          final existing = await isar.mediaFiles
              .filter()
              .assetIdEqualTo(asset.id)
              .findFirst();

          if (existing != null) continue;

          final file = await asset.file;
          if (file == null) continue;

          final media = MediaFile()
            ..assetId = asset.id
            ..fileName = file.path.split('/').last
            ..path = file.path
            ..createdAt = DateTime.fromMillisecondsSinceEpoch(asset.createDateTime.millisecondsSinceEpoch)
            ..mimeType = asset.mimeType ?? ""
            ..size = await file.length()
            ..albumName = album.name
            ..width = asset.width
            ..height = asset.height
            ..duration = asset.type == AssetType.video ? asset.duration : null;

          newMediaFiles.add(media);
        }
        if (newMediaFiles.isNotEmpty) {
          await isar.writeTxn(() async {
            await isar.mediaFiles.putAll(newMediaFiles);
          });
          totalIndexed += newMediaFiles.length;
        }
        page++;
      }
    }

    totalInDB = await isar.mediaFiles.count();
    setState(() {
      newlyIndexedMediaCount = totalIndexed;
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
              ? "Indexed $newlyIndexedMediaCount more media\n$totalInDB media in DB"
              : status,

          style: const TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        )
      )
    );
  }
}
