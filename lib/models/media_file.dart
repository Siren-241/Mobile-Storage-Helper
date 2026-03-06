import 'package:isar/isar.dart';

part 'media_file.g.dart';

@collection
class MediaFile {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String   assetId;

  @Index(type: IndexType.value)
  late String   fileName;

  @Index(type: IndexType.value)
  late String   mimeType;

  @Index(type: IndexType.value)
  late DateTime createdAt;

  @Index(type: IndexType.value)
  late int      size;

  @Index(type: IndexType.hash, caseSensitive: false)
  String?       extractedText;

  late DateTime lastModified;
  late String?  path;
  late String   albumName;
  int?          duration;
  int?          width;
  int?          height;

  String?       exifCamera;
  DateTime?     exifDate;
  double?       latitude;
  double?       longitude;

  bool          metadataProcessed = false;
  bool          metadataFailed = false;
}