import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storage_query_engine/features/indexing/indexers/indexer.dart';
import 'package:storage_query_engine/repositories/media_repository.dart';

import '../../../models/media_item.dart';

class MediaIndexer implements Indexer{
  late MediaRepository mediaRepository;

  MediaItem _assetToMediaFile(AssetEntity asset, String albumName) {
    final media = MediaItem()
      ..assetId = asset.id
      ..fileName = asset.title ?? "" //file.path.split('/').last
      ..path = null //file.path
      ..createdAt = asset.createDateTime
      ..lastModified = asset.modifiedDateTime
      ..mimeType = asset.mimeType ?? ""
      ..size = 0 //await file.length()
      ..albumName = albumName
      ..width = asset.width
      ..height = asset.height
      ..duration = asset.type == AssetType.video ? asset.duration : null;

    return media;
  }

  bool _isUnchanged(AssetEntity asset, Map<String, DateTime> currentEntries) {
    final lastModifiedCache = currentEntries[asset.id];
    if (lastModifiedCache != null &&
        lastModifiedCache == asset.modifiedDateTime){
      return true; // Last Modified date is same, no change
    }

    return false; // Last Modified date didn't line up therefore file has been changed
  }

  // @param currentEntries - compares with current cached entries and ignores them when adding file to isar db
  @override
  Future<void> scan(Map<String, DateTime> currentEntries) async {

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

        List<MediaItem> newMediaItems = [];

        for (final asset in assets) {
          if (!_isUnchanged(asset, currentEntries)){
            continue; // File already exists in DB. Don't add
          }

          final media = _assetToMediaFile(asset, album.name);

          newMediaItems.add(media);
        }
        if (newMediaItems.isNotEmpty) {
          // Insert into repository
          await mediaRepository.insertAll(newMediaItems);
          // TODO: In future, implement a layer of error handling 'media_service'?

          // update current entries
          for (MediaItem media in newMediaItems) {
            currentEntries[media.assetId] = media.lastModified;
          }

          // inc counter
          totalIndexed += newMediaItems.length;
        }
        page++;
      }
    }

    debugPrint("[media_indexer] Indexed $totalIndexed new media files");
  }

}