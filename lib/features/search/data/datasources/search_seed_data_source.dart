import 'package:homescapes/features/search/data/models/search_models.dart';

class SearchSeedDataSource {
  const SearchSeedDataSource();

  Future<SearchData> fetchSearchData() async {
    return const SearchData(
      popularKeywords: <String>[],
      recentKeywords: <String>[],
    );
  }
}
