import 'package:flutter_test/flutter_test.dart';
import 'package:homescapes/models/app_models.dart';

void main() {
  test('community category defaults keep the all category separate', () {
    expect(CommunityCategory.all.label, '전체');
    expect(
      CommunityCategory.defaults.map((category) => category.label),
      containsAll(['자유', '궁금해요', '꿀팁', '자랑']),
    );
  });
}
