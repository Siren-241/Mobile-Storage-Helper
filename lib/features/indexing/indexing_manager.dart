import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storage_query_engine/features/indexing/indexers/document_indexer.dart';
import 'package:storage_query_engine/models/media_item.dart';
import 'package:storage_query_engine/features/indexing/indexers/media_indexer.dart';
import 'package:storage_query_engine/services/db_service.dart';

class IndexingManager {
  final DbService dbService;
  final MediaIndexer mediaIndexer;
  final DocumentIndexer documentIndexer;

  late var currentEntries = <String, DateTime>{};
  Set<String> scannedIds = {};

  IndexingManager({
    required this.dbService,
    required this.mediaIndexer,
    required this.documentIndexer,
  }) {
    _init();
  }

  Future<void> _init() async {
    await _getPermissions();

    debugPrint("[indexing_manager] Starting indexing...");

    startFullIndex();
  }

  Future<void> _getPermissions() async {
    // TODO: Permission.manageExternalStorage.request() is difficult to use, research
    // MediaStore for file access instead as it will increase compatibility

    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      debugPrint("[indexing_manager] Permission not granted");
      return;
    }

    // For accessing documents and downloads folders
    PermissionStatus storagePermission = await Permission.manageExternalStorage
        .request();

    if (!storagePermission.isGranted) {
      storagePermission = await Permission.storage.request();
    }

    if (!storagePermission.isGranted) {
      debugPrint("[indexing_manager] Permission not granted");
      return;
    }
  }

  Future<void> _syncCurrentEntriesToDB() async {
    final existing = await dbService.findAll();
    currentEntries = {
      for (MediaItem file in existing) file.assetId: file.lastModified,
    };
  }

  Future<void> _syncDeletions() async {
    // Scan through the database and find which files were deleted
    final deletedIds = currentEntries.keys
        .where((id) => !scannedIds.contains(id))
        .toList();

    dbService.deleteAll(deletedIds);

    for (final id in deletedIds) {
      currentEntries.remove(id);
    }
  }

  Future<void> _scanMedia() async {
    Set<String> s = await mediaIndexer.scan(currentEntries);
    scannedIds.union(s);
  }

  Future<void> _scanDocs() async {
    Set<String> s = await documentIndexer.scan(currentEntries);
    scannedIds.union(s);
  }

  // ======== Public API =========

  Future<void> startFullIndex() async {
    await _getPermissions();

    await _syncCurrentEntriesToDB();

    await _scanMedia();
    await _scanDocs();

    // Queue enrichment here
    // enrichmentManager.process()

    await _syncDeletions();
  }
}
