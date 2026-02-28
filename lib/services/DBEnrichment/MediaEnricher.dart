import 'package:exif/exif.dart';
import 'dart:io';
import 'package:storage_query_engine/models/media_file.dart';

Future<void> processMediaMetadata(MediaFile media) async {
  try {
    if (media.path == null) throw Exception("Path is null"); // Requires path to be filled in before func call

    final bytes = await File(media.path!).readAsBytes();
    final data = await readExifFromBytes(bytes);

    media.exifCamera = data['Image Model']?.printable;

    final dateStr = data['EXIF DataTimeOriginal']?.printable;
    if (dateStr != null) {
      media.exifDate = DateTime.tryParse(dateStr.replaceAll(":", "-"));
    }

    final lat = data['GPS GPSLatitude'];
    final lon = data['GPS GPSLongitude'];

    if (lat != null && lon != null) {
      media.latitude = _convertToDegree(lat.values);
      media.longitude = _convertToDegree(lon.values);
    }

    media.metadataProcessed = true;
  } catch (e) {
    print("Metadata Enrichment Failed for ${media.fileName}: $e");
    media.metadataFailed = true;
  }
}

double _convertToDegree(IfdValues val){
 return 0; // TODO
}