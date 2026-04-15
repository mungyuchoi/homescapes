import 'package:homescapes/features/search/data/models/search_models.dart';
import 'package:homescapes/features/search/data/repositories/search_repository.dart';

class SearchService {
  SearchService({SearchRepository? repository})
    : _repository = repository ?? SearchRepositoryImpl();

  final SearchRepository _repository;

  Future<SearchData> getCachedSearchData() {
    return _repository.fetchCachedSearchData();
  }

  Future<SearchData> getSearchData() {
    return _repository.fetchSearchData();
  }

  Future<List<String>> search(String query) {
    return _repository.searchByKeyword(query: query);
  }

  Future<void> trackSearchKeyword(String keyword) {
    return _repository.trackSearchKeyword(keyword: keyword);
  }

  Future<void> removeRecentKeyword(String keyword) {
    return _repository.removeRecentKeyword(keyword: keyword);
  }
}
