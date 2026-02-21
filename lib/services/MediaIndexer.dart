import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_file.dart';

class MediaIndexer {
  late Isar isar;
  final Function(String) onStatusUpdate;

  Map<String, DateTime>? existingFilesMap;

  // Constructor
  MediaIndexer({required this.isar, required this.onStatusUpdate});

  Future<void> init() async {
    await _populateExistingFiles();
  }

  Future<void> _populateExistingFiles() async {
    final existingFiles = await isar.mediaFiles
        .where()
        .findAll();
    existingFilesMap = {
      for (var file in existingFiles)
        file.assetId: file.lastModified
    }; // Map of assetId and its last updated time
  }

  // Returns number of new media sent to DB
  Future<int> loadMedia() async {
    if (existingFilesMap == null) await _populateExistingFiles();

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
          final existingModified = existingFilesMap?[asset.id];
          if (existingModified != null &&
              existingModified == asset.modifiedDateTime){
            continue; // File already exists in DB. Don't add
          }

          final media = MediaFile()
            ..assetId = asset.id
            ..fileName = asset.title ?? "" //file.path.split('/').last
            ..path = null //file.path
            ..createdAt = DateTime.fromMillisecondsSinceEpoch(asset.createDateTime.millisecondsSinceEpoch)
            ..lastModified = asset.modifiedDateTime
            ..mimeType = asset.mimeType ?? ""
            ..size = 0 //await file.length()
            ..albumName = album.name
            ..width = asset.width
            ..height = asset.height
            ..duration = asset.type == AssetType.video ? asset.duration : null;

          newMediaFiles.add(media);
        }
        if (newMediaFiles.isNotEmpty) {
          await isar.writeTxn(() async {
            await isar.mediaFiles.putAll(newMediaFiles);
            for (var media in newMediaFiles) {
              existingFilesMap?[media.assetId] = media.lastModified;
            }
          });
          totalIndexed += newMediaFiles.length;
        }
        page++;
      }
    }

    // totalInDB = await isar.mediaFiles.count();
    onStatusUpdate("Done Indexing Media");
    return totalIndexed;
  }

  Future<int> loadAllPDFs() async {
    if (existingFilesMap == null) await _populateExistingFiles();

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
        await for (final entity in dir.list(recursive: true, followLinks: false)){
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            final stat = await entity.stat();

            final existingModified = existingFilesMap?[entity.path];
            if (existingModified != null &&
                existingModified == stat.modified){
              continue; // File already exists in DB. Don't add
            }

            final media = MediaFile()
              ..assetId = entity.path
              ..fileName = entity.path.split('/').last
              ..path = entity.path
              ..createdAt = stat.changed
              ..lastModified = stat.modified
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
        for (var media in newPDFs) {
          existingFilesMap?[media.assetId] = media.lastModified;
        }
      });
      newIndexed += newPDFs.length;
    }
    onStatusUpdate("Done Indexing PDFs");
    return newIndexed;
  }
}