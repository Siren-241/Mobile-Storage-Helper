import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_file.dart';

class MediaIndexer {
  late Isar isar;
  final Function(String) onStatusUpdate;

  Map<String, DateTime> _existingFilesMap = {};

  final _scannedIds = <String>{};

  // Constructor
  MediaIndexer({required this.isar, required this.onStatusUpdate});

  Future<void> _init() async {
    await _populateExistingFiles();
    _scannedIds.clear();
  }

  Future<void> _populateExistingFiles() async {
    final existingFiles = await isar.mediaFiles
        .where()
        .findAll();
    _existingFilesMap = {
      for (var file in existingFiles)
        file.assetId: file.lastModified
    }; // Map of assetId and its last updated time
  }

  // Returns number of new media sent to DB
  Future<int> _loadMedia() async {
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
          // Append asset id to scanned ids to not delete it in _syncDeletions
          _scannedIds.add(asset.id);

          final existingModified = _existingFilesMap[asset.id];
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
              _existingFilesMap[media.assetId] = media.lastModified;
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

  Future<int> _loadAllPDFs() async {
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
            // Append asset id to scanned ids to not delete it in _syncDeletions
            _scannedIds.add(entity.path);

            final stat = await entity.stat();

            final existingModified = _existingFilesMap[entity.path];
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
          _existingFilesMap[media.assetId] = media.lastModified;
        }
      });
      newIndexed += newPDFs.length;
    }
    onStatusUpdate("Done Indexing PDFs");
    return newIndexed;
  }

  Future<void> _syncDeletions() async {
    final idsToDelete = _existingFilesMap.keys
        .where((id) => !_scannedIds.contains(id))
        .toList();

    await isar.writeTxn(() async {
      // Try later for optimization
      await isar.mediaFiles.deleteAllByAssetId(idsToDelete);
      for (final id in idsToDelete) {
        // await isar.mediaFiles
        //     .filter()
        //     .assetIdEqualTo(id)
        //     .deleteFirst();
        _existingFilesMap.remove(id);
      }
    });
  }

  Future<int> runFullIndex() async {
    await _init();

    int temp = 0;
    temp += await _loadMedia();
    temp += await _loadAllPDFs();

    await _syncDeletions();

    return temp;
  }

}