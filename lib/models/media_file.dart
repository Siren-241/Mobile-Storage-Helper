import 'package:isar/isar.dart';

part 'media_file.g.dart';

@collection
class MediaFile {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String   assetId;
  late String   fileName;
  late String?  path;
  late DateTime createdAt;
  late DateTime lastModified;
  late String   mimeType;
  late int      size;
  late String   albumName;
  int?          duration;
  int?          width;
  int?          height;
}