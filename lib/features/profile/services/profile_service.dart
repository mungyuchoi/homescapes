import 'package:flutter/material.dart';

import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';

class ProfileService {
  ProfileService({
    ProfileRepository? repository,
  }) : _repository = repository ?? ProfileRepositoryImpl();

  final ProfileRepository _repository;

  Future<ProfilePageData> getProfileData() {
    return _repository.fetchProfileData();
  }

  Future<ProfileLoginUiConfig> getLoginUiConfig({
    required TargetPlatform platform,
  }) {
    return _repository.fetchLoginUiConfig(platform: platform);
  }

  Future<List<ProfileSettingSection>> getSettingSections() {
    return _repository.fetchSettingSections();
  }
}
