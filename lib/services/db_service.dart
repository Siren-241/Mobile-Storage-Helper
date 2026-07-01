import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_query_engine/repositories/media_repository.dart';

import '../models/media_item.dart';

class DbService {

  late final Isar _isar;

  late final MediaRepository mediaRepository;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
        [MediaItemSchema],
        directory: dir.path,
        inspector: true
    );

    mediaRepository = MediaRepository(isar: _isar);
  }

  // CREATE

  Future<int> insert(MediaItem mediaItem) async {
    // TODO: check if already exists
    // String assetId = mediaFile.assetId;

    int id;
    try {
      id = await mediaRepository.insert(mediaItem);
    } catch(error) {
      debugPrint("[db_service] Error inserting media file into db: $error");
      return -1;
    }
    return id;
  }

  Future<List<int>> insertAll(List<MediaItem> mediaItems) async {
    late List<int> ids;

    try {
      ids = await mediaRepository.insertAll(mediaItems);
    } catch(error) {
      debugPrint("[db_service] Error inserting media files into db: $error");
      return [];
    }

    return ids;
  }


  // READ

  Future<List<MediaItem>> findAll() async {
    return await mediaRepository.findAll();
  }

  Future<MediaItem?> findById(String assetId) async {
    return await mediaRepository.findById(assetId);
  }

  // DELETE

  // Returns whether file is deleted
  Future<bool> delete(String assetId) async {
    late bool isDeleted;
    try {
      isDeleted = await mediaRepository.delete(assetId);
    } catch (error) {
      debugPrint("[db_service] Error deleting file: $error");
      isDeleted = false;
    }

    return isDeleted;
  }

  // Returns number of objects deleted
  Future<int> deleteAll(List<String> assetIds) async {
    late int count;

    try {
      count = await mediaRepository.deleteAll(assetIds);
    } catch (error) {
      debugPrint("[db_service] Error deleting files: $error");
      count = -1;
    }
    return count;
  }

}