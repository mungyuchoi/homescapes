import 'package:homescapes/models/app_models.dart';

import '../datasources/spot_firestore_data_source.dart';

abstract class SpotRepository {
  Future<Map<String, SpotDoc>> fetchSpotsCollection();

  Future<DayFacilitySlotsDoc> fetchTodaySlotsDoc({DateTime? now});

  Future<List<FacilityMapNode>> fetchMapNodes();
}

class SpotRepositoryImpl implements SpotRepository {
  const SpotRepositoryImpl({this.firestoreDataSource});

  final SpotFirestoreDataSource? firestoreDataSource;

  @override
  Future<Map<String, SpotDoc>> fetchSpotsCollection() async {
    final remoteDataSource = firestoreDataSource ?? SpotFirestoreDataSource();
    return remoteDataSource.fetchSpotsCollection();
  }

  @override
  Future<DayFacilitySlotsDoc> fetchTodaySlotsDoc({DateTime? now}) async {
    final remoteDataSource = firestoreDataSource ?? SpotFirestoreDataSource();
    return remoteDataSource.fetchTodaySlotsDoc(now: now);
  }

  @override
  Future<List<FacilityMapNode>> fetchMapNodes() async {
    final remoteDataSource = firestoreDataSource ?? SpotFirestoreDataSource();
    return remoteDataSource.fetchMapNodes();
  }
}
