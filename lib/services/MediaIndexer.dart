import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_file.dart';

class MediaIndexer {
  late Isar isar;
  final Function(String) onStatusUpdate;

  // Constructor
  MediaIndexer({required this.isar, required this.onStatusUpdate});

  // Returns number of new media sent to DB
  Future<int> loadMedia() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      onStatusUpdate("Permissions denied");
      return 0;
    }

    onStatusUpdate("Loading Media...");

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

    // totalInDB = await isar.mediaFiles.count();
    // setState(() {
    //   newlyIndexedMediaCount = totalIndexed;
    //   status = "Done";
    // });
    return totalIndexed;
  }

  Future<int> loadAllPDFs() async {
    onStatusUpdate("Requesting Storage Permissions...");

    var storagePermission = await Permission.manageExternalStorage.request();

    if (!storagePermission.isGranted) {
      storagePermission = await Permission.storage.request();
    }
    if (!storagePermission.isGranted) {
      onStatusUpdate("Storage Permission Denied");
      return 0;
    }
    onStatusUpdate("Loading PDFs...");
    int newIndexed = 0;

    final List<String> targetPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents'
    ];

    List<MediaFile> newPDFs = [];

    for (String path in targetPaths){
      final dir = Directory(path);

      if(!await dir.exists()) continue;

      try {
        final files = dir.listSync(recursive: true, followLinks: false);

        for (final entity in files){
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            final existing = await isar.mediaFiles
                .filter()
                .pathEqualTo(entity.path)
                .findFirst();

            if (existing != null) continue;

            final stat = await entity.stat();
            final media = MediaFile()
              ..assetId = entity.path
              ..fileName = entity.path.split('/').last
              ..path = entity.path
              ..createdAt = stat.changed
              ..mimeType = "application/pdf"
              ..size = stat.size
              ..albumName = path.split('/').last;

            newPDFs.add(media);
          }
        }
      } catch (e){
        print("Failed to load pdfs from $path");
        print(e);
        continue;
      }
    }

    if (newPDFs.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.mediaFiles.putAll(newPDFs);
      });
      newIndexed += newPDFs.length;
    }
    return newIndexed;
  }
}