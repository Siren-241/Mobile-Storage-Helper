import 'package:storage_query_engine/services/db_service.dart';

abstract class Indexer {
  late DbService dbService;

  Future<Set<String>> scan(Map<String, DateTime> currentEntries);
}