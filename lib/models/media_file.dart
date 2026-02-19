import 'package:isar/isar.dart';

part 'media_file.g.dart';

@collection
class MediaFile {
  Id id = Isar.autoIncrement;

  late String   assetId;
  late String   fileName;
  late String?  path;
  late DateTime createdAt;
  late String   mimeType;
  late int      size;
  late String   albumName;
}