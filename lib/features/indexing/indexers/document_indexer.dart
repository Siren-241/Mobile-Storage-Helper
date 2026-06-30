import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:storage_query_engine/features/indexing/indexers/indexer.dart';
import 'package:storage_query_engine/services/db_service.dart';

import '../../../models/media_item.dart';

class DocumentIndexer implements Indexer {
  @override
  late DbService dbService;

  DocumentIndexer({required this.dbService});

  Future<bool> _isUnchanged(
    FileSystemEntity entity,
    Map<String, DateTime> currentEntries,
  ) async {
    final stat = await entity.stat();
    final lastModifiedCache = currentEntries[entity.path];
    if (lastModifiedCache != null && lastModifiedCache == stat.modified) {
      return true; // Last Modified date is same, no change
    }

    return false; // Last Modified date didn't line up therefore file has been changed
  }

  MediaItem _entityToMediaItem(
    FileSystemEntity entity,
    FileStat stat,
    String path,
  ) {
    final media = MediaItem()
      ..assetId = entity.path // Asset Id for pdfs is the path itself!!
      ..fileName = entity.path.split('/').last
      ..path = entity.path
      ..createdAt = stat.changed
      ..lastModified = stat.modified
      ..mimeType = "application/pdf"
      ..size = stat.size
      ..albumName = path.split('/').last;
    return media;
  }

  // @param currentEntries - compares with current cached entries and ignores them when adding file to isar db
  @override
  Future<Set<String>> scan(Map<String, DateTime> currentEntries) async {
    Set<String> scannedIds = {};

    final List<String> targetPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
    ];

    List<MediaItem> newPDFs = [];
    int newCount = 0;

    for (String path in targetPaths) {
      final dir = Directory(path);

      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            scannedIds.add(
              entity.path,
            ); // Add to scanned ids regardless of current entries

            final stat = await entity.stat();

            if (await _isUnchanged(entity, currentEntries)) {
              continue; // File already exists in DB. Don't add
            }

            MediaItem media = _entityToMediaItem(entity, stat, path);

            newPDFs.add(media);
          }
        }
      } catch (e) {
        debugPrint("[document_indexer] Error indexing files from path:$path");
        debugPrint(e.toString());
        continue;
      }
    }

    if (newPDFs.isNotEmpty) {
      // insert into db in bulk
      await dbService.insertAll(newPDFs);

      newCount += newPDFs.length;

      // update current entries (cache) with new entries
      for (var media in newPDFs) {
        currentEntries[media.assetId] = media.lastModified;
      }
    }
    debugPrint("[document_indexer] Indexed $newCount PDFs");
    return scannedIds;
  }
}
