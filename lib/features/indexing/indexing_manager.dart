import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storage_query_engine/features/indexing/indexers/document_indexer.dart';
import 'package:storage_query_engine/models/media_item.dart';
import 'package:storage_query_engine/repositories/media_repository.dart';
import 'package:storage_query_engine/features/indexing/indexers/media_indexer.dart';

class IndexingManager {

  final MediaRepository mediaRepository;
  final MediaIndexer mediaIndexer;
  final DocumentIndexer documentIndexer;

  late var currentEntries = <String, DateTime>{};

  IndexingManager({
    required this.mediaRepository,
    required this.mediaIndexer,
    required this.documentIndexer,
  }){
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

    if(!permission.isAuth) {
      debugPrint("[indexing_manager] Permission not granted");
      return;
    }
  }

  Future<void> _syncCurrentEntries() async {
    final existing = await mediaRepository.findAll();
    currentEntries = {
      for(MediaItem file in existing) file.assetId: file.lastModified
    };
  }

  Future<void> _syncDeletions() async {
    // use currentEntries.containsKey()
  }

  Future<void> _scanMedia() async {
    mediaIndexer.scan(currentEntries);
  }

  Future<void> _scanDocs() async {
    // documentIndexer.scan(currentEntries);
  }


  // ======== Public API =========

  Future<void> startFullIndex() async {
    await _getPermissions();

    await _syncCurrentEntries();

    await _scanMedia();
    await _scanDocs();

    // Queue enrichment here
    // enrichmentManager.process()

    await _syncDeletions();
  }


}