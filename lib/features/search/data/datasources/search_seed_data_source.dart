import 'package:homescapes/features/search/data/models/search_models.dart';

class SearchSeedDataSource {
  const SearchSeedDataSource();

  Future<SearchData> fetchSearchData() async {
    return const SearchData(
      popularKeywords: <String>[
        '클라이밍아레나',
        '키즈미디어 스튜디오',
        '오늘의 루트',
        '체험관 지도',
        '조이 보상',
      ],
      recentKeywords: <String>[
        '키즈미디어',
        '아이라',
        '직무 체험',
      ],
    );
  }
}
