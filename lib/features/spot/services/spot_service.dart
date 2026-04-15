import 'package:homescapes/models/app_models.dart';

import '../data/repositories/spot_repository.dart';

class SpotService {
  const SpotService({
    required this.repository,
  });

  final SpotRepository repository;

  Future<Map<String, SpotDoc>> getSpotsCollection() {
    return repository.fetchSpotsCollection();
  }

  Future<DayFacilitySlotsDoc> getTodaySlotsDoc({DateTime? now}) {
    return repository.fetchTodaySlotsDoc(now: now);
  }

  Future<List<FacilityMapNode>> getMapNodes() {
    return repository.fetchMapNodes();
  }
}
