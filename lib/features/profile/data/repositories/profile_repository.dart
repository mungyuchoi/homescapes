import 'package:homescapes/features/profile/data/models/profile_models.dart';
import 'package:flutter/material.dart';

import '../datasources/profile_seed_data_source.dart';

abstract class ProfileRepository {
  Future<ProfilePageData> fetchProfileData();

  Future<ProfileLoginUiConfig> fetchLoginUiConfig({
    required TargetPlatform platform,
  });

  Future<List<ProfileSettingSection>> fetchSettingSections();
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    ProfileSeedDataSource? dataSource,
  }) : _dataSource = dataSource ?? const ProfileSeedDataSource();

  final ProfileSeedDataSource _dataSource;

  @override
  Future<ProfilePageData> fetchProfileData() {
    return _dataSource.fetchProfileData();
  }

  @override
  Future<ProfileLoginUiConfig> fetchLoginUiConfig({
    required TargetPlatform platform,
  }) {
    return _dataSource.fetchLoginUiConfig(platform: platform);
  }

  @override
  Future<List<ProfileSettingSection>> fetchSettingSections() {
    return _dataSource.fetchSettingSections();
  }
}
