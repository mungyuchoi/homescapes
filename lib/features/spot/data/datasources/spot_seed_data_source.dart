import 'package:homescapes/data/app_seed_data.dart';
import 'package:homescapes/models/app_models.dart';

class SpotSeedDataSource {
  const SpotSeedDataSource();

  Future<Map<String, SpotDoc>> fetchSpotsCollection() async {
    return buildSpotsCollection();
  }

  Future<DayFacilitySlotsDoc> fetchTodaySlotsDoc({DateTime? now}) async {
    return buildTodaySlotsDoc(now: now ?? DateTime.now());
  }

  Future<List<FacilityMapNode>> fetchMapNodes() async {
    return buildMapNodes();
  }
}
