import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';

import '../models/media_item.dart';

class MediaRepository {

  late Isar isar;

  MediaRepository({ required this.isar });

  // CREATE

  Future<int> insert(MediaItem mediaFile) async {
    late int id;
    await isar.writeTxn(() async {
      id = await isar.mediaItems.put(mediaFile);
    });

    return id;
  }

  Future<List<int>> insertAll(List<MediaItem> mediaItems) async {
    late List<int> ids;

    await isar.writeTxn(() async {
      ids = await isar.mediaItems.putAll(mediaItems);
    });

    return ids;
  }

  // READ

  Future<List<MediaItem>> findAll() async {
    final files = await isar.mediaItems
        .where()
        .findAll();

    return files;
  }

  Future<MediaItem?> findById(String assetId) async {
    final file = isar.mediaItems.getByAssetId(assetId);

    return file;
  }

  // DELETE

  // Returns whether file is deleted
  Future<bool> delete(String assetId) async {
    late bool isDeleted;
    await isar.writeTxn(() async {
      isDeleted = await isar.mediaItems.deleteByAssetId(assetId);
    });

    return isDeleted;
  }

  // Returns number of objects deleted
  Future<int> deleteAll(List<String> assetIds) async {
    late int count;
    await isar.writeTxn(() async {
      count = await isar.mediaItems.deleteAllByAssetId(assetIds);
    });

    return count;
  }





}

// class MediaRepository {
//   final Isar isar;
//
//   MediaRepository(this.isar);
//
//   // ---------- CREATE ----------
//
//   Future<void> insert(MediaFile file);
//
//   Future<void> insertAll(List<MediaFile> files);
//
//   // ---------- READ ----------
//
//   Future<MediaFile?> getByAssetId(String assetId);
//
//   Future<List<MediaFile>> getAll();
//
//   Future<List<MediaFile>> getAllImages();
//
//   Future<List<MediaFile>> getAllVideos();
//
//   Future<List<MediaFile>> getAllPdfs();
//
//   Future<List<MediaFile>> searchByText(String query);
//
//   Future<List<MediaFile>> searchByDate(
//       DateTime start,
//       DateTime end,
//       );
//
//   Future<List<MediaFile>> searchByMimeType(String mimeType);
//
//   Future<List<MediaFile>> getUnprocessed();
//
//   Future<Map<String, DateTime>> getExistingFileMap();
//
//   // ---------- UPDATE ----------
//
//   Future<void> update(MediaFile file);
//
//   Future<void> updateAll(List<MediaFile> files);
//
//   Future<void> markProcessed(String assetId);
//
//   Future<void> markFailed(String assetId);
//
//   // ---------- DELETE ----------
//
//   Future<bool> delete(String assetId);
//
//   Future<void> deleteMany(List<String> assetIds);
//
//   Future<void> clear();
//
//   // ---------- STATS ----------
//
//   Future<int> count();
//
//   Future<int> countImages();
//
//   Future<int> countVideos();
//
//   Future<int> countPdfs();
// }