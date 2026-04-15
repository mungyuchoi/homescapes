import 'package:flutter/material.dart';

import '../models/app_models.dart';

String dayId(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y$m$d';
}

String toFacilityId(String name) {
  final codepoints = name.runes.map((rune) => rune.toRadixString(16)).join('_');
  return 'f_$codepoints';
}

Map<String, SpotDoc> buildSpotsCollection() {
  SpotDoc make({
    required String title,
    required String floor,
    required int durationMin,
    required String aptType,
    required String joyReward,
    required String ageRule,
    required String description,
    required String imageUrl,
    String jobDescription = '체험 직무 안내를 준비중입니다.',
  }) {
    return SpotDoc(
      spotId: toFacilityId(title),
      title: title,
      floor: floor,
      durationMin: durationMin,
      aptType: aptType,
      joyReward: joyReward,
      ageRule: ageRule,
      description: description,
      imageUrl: imageUrl,
      officialUrl:
          'https://www.koreajobworld.or.kr/exrPreview/exrPreViewList.do?site=1&floor=1&exhpCd=33&portalMenuNo=158',
      jobDescription: jobDescription,
    );
  }

  final spots = <SpotDoc>[
    make(
      title: '클라이밍아레나',
      floor: '3층',
      durationMin: 20,
      aptType: '흥미유형 R',
      joyReward: '5조이',
      ageRule: '6세 이상, 120cm 이상',
      description:
          '클라이밍 기초자세를 배우고 등반훈련을 통해 스포츠 가치를 이해하며 직접 체험합니다.',
      jobDescription:
          '클라이밍 선수: 실내 인공암벽 시설에서 스포츠 클라이밍 훈련과 대회 출전 미션을 수행합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304155814174_1.jpeg',
    ),
    make(
      title: '디자인센터',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 A',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description:
          '디지털 디자이너의 역할을 이해하고 실생활에서 사용하는 디자인 산출물을 직접 제작합니다.',
      jobDescription: '디지털 디자이너: 광고·브랜딩 요소를 디자인하고 결과물을 발표합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304151946987_1.jpeg',
    ),
    make(
      title: '경찰서',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 S',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: '경찰관이 되어 사이버 범죄를 추적하고 사건 해결 과정을 체험합니다.',
      jobDescription: '경찰관: 사건 조사, 단서 수집, 안전 수칙 안내 등 치안 업무를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304151158986_1.jpeg',
    ),
    make(
      title: 'AR신발패션실',
      floor: 'M층',
      durationMin: 20,
      aptType: '흥미유형 A',
      joyReward: '7조이',
      ageRule: '6세 이상',
      description: 'AR 신발 피팅 체험과 함께 나만의 패션 스타일을 완성해보는 체험입니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304150849985_1.jpeg',
    ),
    make(
      title: '빵부장연구소',
      floor: '3층',
      durationMin: 25,
      aptType: '흥미유형 R',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '음식과학 기반 제빵 체험을 통해 반죽·발효·굽기 과정을 이해합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304145349981_1.jpeg',
    ),
    make(
      title: 'VR게임스테이션',
      floor: '3층',
      durationMin: 20,
      aptType: '흥미유형 R',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: 'VR 환경에서 미션을 수행하며 몰입형 직업 체험을 진행합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304144836983_1.jpeg',
    ),
    make(
      title: '공룡캠프',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 I',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '공룡 고고학자처럼 화석 발굴과 생태 탐험을 체험하는 프로그램입니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304144253982_1.jpeg',
    ),
    make(
      title: '해양경찰구조대',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 S',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: '해양 안전 교육과 구조 미션을 통해 해양경찰의 역할을 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304143521977_1.jpeg',
    ),
    make(
      title: '달콤카페',
      floor: 'M층',
      durationMin: 20,
      aptType: '흥미유형 C',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '바리스타 직무를 중심으로 음료 제조와 서비스 응대를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304143133979_1.jpeg',
    ),
    make(
      title: '스마트건설사이트',
      floor: '3층',
      durationMin: 25,
      aptType: '흥미유형 R',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '건설 기술자의 역할과 안전수칙을 배우고 스마트 건설 공정을 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304142345978_1.jpeg',
    ),
    make(
      title: '키즈미디어 스튜디오',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 A',
      joyReward: '5조이',
      ageRule: '4세 이상',
      description: '영상 콘텐츠 기획부터 촬영까지 미디어 제작 프로세스를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304141801976_1.jpeg',
    ),
    make(
      title: '소방서',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 R',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: '화재 진압 장비를 이해하고 긴급 상황 대응 훈련을 진행합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304141203969_1.jpeg',
    ),
    make(
      title: '전기안전센터',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 C',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '생활 속 전기 안전 점검과 감전 예방 수칙을 체험형으로 학습합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304140909971_1.jpeg',
    ),
    make(
      title: '마법사학교',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 A',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '공연형 스토리텔링을 통해 창의적 표현과 협동 미션을 수행하는 체험입니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304140050970_1.jpeg',
    ),
    make(
      title: '사회복지관',
      floor: '3층',
      durationMin: 25,
      aptType: '흥미유형 S',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description:
          '사회복지사의 역할을 이해하고 공감·소통 중심의 현장 시나리오를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304135552968_1.jpeg',
    ),
    make(
      title: '자동차정비소',
      floor: '3층',
      durationMin: 15,
      aptType: '흥미유형 R',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '정비 점검 루틴을 배우고 차량 안전 진단 절차를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304135147966_1.jpeg',
    ),
    make(
      title: '슈퍼마켓',
      floor: '3층',
      durationMin: 25,
      aptType: '흥미유형 C',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '매장 운영과 진열, 고객 응대를 체험하며 유통 서비스 업무를 익힙니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304132155961_1.jpeg',
    ),
    make(
      title: '과자가게',
      floor: '3층',
      durationMin: 40,
      aptType: '흥미유형 C',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '과자 제조 및 포장 과정을 통해 식품 생산 직무를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304131834963_1.jpeg',
    ),
    make(
      title: '택배회사',
      floor: '3층',
      durationMin: 30,
      aptType: '흥미유형 C',
      joyReward: '5조이',
      ageRule: '5세 이상',
      description: '물류 분류와 배송 동선을 이해하고 택배 프로세스를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304131312957_1.jpeg',
    ),
    make(
      title: '꽃집',
      floor: '3층',
      durationMin: 25,
      aptType: '흥미유형 A',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '플로리스트처럼 꽃다발 구성과 매장 응대 서비스를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304131036959_1.jpeg',
    ),
    make(
      title: '슈즈아틀리에',
      floor: 'M층',
      durationMin: 20,
      aptType: '흥미유형 R',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: '신발 제작 과정을 이해하고 디자인부터 마감까지 단계별 체험을 진행합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304130351958_1.jpeg',
    ),
    make(
      title: '피자가게',
      floor: '3층',
      durationMin: 40,
      aptType: '흥미유형 C',
      joyReward: '4조이',
      ageRule: '4세 이상',
      description: '피자 조리와 위생 수칙을 함께 익히는 조리 직무 체험입니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304125839955_1.jpeg',
    ),
    make(
      title: '신문사',
      floor: 'M층',
      durationMin: 20,
      aptType: '흥미유형 I',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: '취재와 기사 작성 과정을 통해 기자의 핵심 업무를 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304130351958_1.jpeg',
    ),
    make(
      title: '로봇공학연구소',
      floor: '3층',
      durationMin: 25,
      aptType: '흥미유형 R',
      joyReward: '6조이',
      ageRule: '6세 이상',
      description: '로봇 연구원이 되어 센서·동작 원리를 이해하고 제어 미션을 체험합니다.',
      imageUrl:
          'https://www.koreajobworld.or.kr/upload/exhp_img/resize_exhp_20250304145349981_1.jpeg',
    ),
  ];

  return {for (final spot in spots) spot.spotId: spot};
}

Map<String, UserTodayRootDoc> buildTodayRootCollection({
  required DateTime now,
  String uid = 'guest_demo',
}) {
  return {
    uid: UserTodayRootDoc(
      uid: uid,
      dayId: dayId(now),
      items: [
        TodayRootItem(
          spotId: toFacilityId('키즈미디어 스튜디오'),
          spotName: '키즈미디어 스튜디오',
          timeRange: '10:50 ~ 11:20',
          note: '촬영 체험 완료',
        ),
        TodayRootItem(
          spotId: toFacilityId('소방서'),
          spotName: '소방서',
          timeRange: '11:30 ~ 12:00',
          note: '화재 대응 미션 완료',
        ),
        TodayRootItem(
          spotId: toFacilityId('빵부장연구소'),
          spotName: '빵부장연구소',
          timeRange: '12:10 ~ 12:35',
          note: '쿠키 제작 체험',
        ),
      ],
    ),
  };
}

List<CommunityPost> buildPostsCollection({
  required Map<String, UserTodayRootDoc> todayRootCollection,
  String uid = 'guest_demo',
}) {
  final todayRoot = todayRootCollection[uid];
  final rootSummary = todayRoot == null
      ? ''
      : todayRoot.items.map((item) => '${item.spotName}(${item.timeRange})').join(' → ');

  return [
    CommunityPost(
      postId: 'p_1',
      uid: 'u_haribo',
      author: '사과맛하리보',
      timeAgo: '3시간 전',
      category: '자유',
      content: '오늘 소방서 대기 거의 없었어요. 10분 안에 바로 들어갔습니다.',
      spotId: toFacilityId('소방서'),
      facility: '소방서',
      likes: 3,
      comments: 1,
    ),
    CommunityPost(
      postId: 'p_2',
      uid: 'u_joy',
      author: '조이탐험가',
      timeAgo: '27분 전',
      category: '궁금해요',
      content: '키즈미디어 스튜디오가 6세 아이도 이해하기 쉬운 편인가요?',
      spotId: toFacilityId('키즈미디어 스튜디오'),
      facility: '키즈미디어 스튜디오',
      likes: 5,
      comments: 4,
    ),
    CommunityPost(
      postId: 'p_3',
      uid: uid,
      author: '빵부장',
      timeAgo: '12분 전',
      category: '오늘의 루트',
      content: rootSummary.isEmpty ? '오늘의 루트 기록이 없습니다.' : rootSummary,
      spotId: toFacilityId('키즈미디어 스튜디오'),
      facility: '오늘의 루트',
      likes: 9,
      comments: 2,
      routeItems: todayRoot?.items ?? const [],
    ),
    CommunityPost(
      postId: 'p_4',
      uid: 'u_tip',
      author: '현직자',
      timeAgo: '8분 전',
      category: '꿀팁',
      content: '체험 종료 직전 10분 전이 혼잡도가 제일 적은 편입니다. 예약 전후 동선 체크도 같이 해보세요.',
      spotId: toFacilityId('클라이밍아레나'),
      facility: '클라이밍아레나',
      likes: 2,
      comments: 0,
    ),

  ];
}

DayFacilitySlotsDoc buildTodaySlotsDoc({required DateTime now}) {
  final id = dayId(now);
  final docs = <String, FacilitySlotsDoc>{};

  void addTemplate({
    required List<String> facilities,
    required List<String> firstSessionStarts,
    required List<String> secondSessionStarts,
  }) {
    final mergedSlots = _mergeSessionStarts(firstSessionStarts, secondSessionStarts);
    for (final facility in facilities) {
      final facilityId = toFacilityId(facility);
      docs[facilityId] = FacilitySlotsDoc(
        facilityId: facilityId,
        facilityName: facility,
        floor: _floorOf(facility),
        slots: mergedSlots,
      );
    }
  }

  addTemplate(
    facilities: const ['자동차정비소'],
    firstSessionStarts: const ['09:35', '10:00', '10:25', '10:50', '11:15', '11:40', '12:05', '12:30', '12:55'],
    secondSessionStarts: const ['14:35', '15:00', '15:25', '15:50', '16:15', '16:40', '17:05', '17:30', '17:55'],
  );

  addTemplate(
    facilities: const ['슈즈아틀리에', '신문사', '메타버스월드', '업사이클링팩토리', '우주센터'],
    firstSessionStarts: const ['09:35', '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '12:55'],
    secondSessionStarts: const ['14:35', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '17:55'],
  );

  addTemplate(
    facilities: const ['달콤카페', '건설탐험대', 'VR게임스테이션'],
    firstSessionStarts: const ['09:40', '10:10', '10:40', '11:10', '11:40', '12:10', '12:40'],
    secondSessionStarts: const ['14:40', '15:10', '15:40', '16:10', '16:40', '17:10', '17:40'],
  );

  addTemplate(
    facilities: const ['클라이밍아레나'],
    firstSessionStarts: const ['09:45', '10:15', '10:45', '11:15', '11:45', '12:15', '12:45'],
    secondSessionStarts: const ['14:45', '15:15', '15:45', '16:15', '16:45', '17:15', '17:45'],
  );

  addTemplate(
    facilities: const ['AR신발패션실'],
    firstSessionStarts: const ['09:50', '10:20', '10:50', '11:20', '11:50', '12:20'],
    secondSessionStarts: const ['14:50', '15:20', '15:50', '16:20', '16:50', '17:20'],
  );

  addTemplate(
    facilities: const ['드론연구소', '꽃집', '로봇공학연구소', '사회복지관', '슈퍼마켓'],
    firstSessionStarts: const ['09:35', '10:10', '10:45', '11:20', '11:55', '12:30'],
    secondSessionStarts: const ['14:35', '15:10', '15:45', '16:20', '16:55', '17:30'],
  );

  addTemplate(
    facilities: const ['빵부장연구소', '스마트건설사이트', 'K-POP스테이지'],
    firstSessionStarts: const ['09:40', '10:15', '10:50', '11:25', '12:00', '12:35'],
    secondSessionStarts: const ['14:40', '15:15', '15:50', '16:25', '17:00', '17:35'],
  );

  addTemplate(
    facilities: const ['디지털갤러리', '히스토리TV'],
    firstSessionStarts: const ['09:45', '10:20', '10:55', '11:30', '12:05', '12:40'],
    secondSessionStarts: const ['14:45', '15:20', '15:55', '16:30', '17:05', '17:40'],
  );

  addTemplate(
    facilities: const [
      '동물병원',
      '레이싱경기장',
      '병원신생아실',
      '애니메이션스튜디오',
      '치과의원',
      '경찰서',
      '공룡캠프',
      '디자인센터',
      '마법사학교',
      '미용실',
      '소방서',
      '스마트해상교통관제센터',
      '전기안전센터',
      '키즈미디어 스튜디오',
      '택배회사',
      '해양경찰구조대',
    ],
    firstSessionStarts: const ['09:35', '10:10', '10:50', '11:30', '12:10', '12:45'],
    secondSessionStarts: const ['14:35', '15:10', '15:50', '16:30', '17:10', '17:45'],
  );

  addTemplate(
    facilities: const ['야구경기장', '외과수술실', '방송국'],
    firstSessionStarts: const ['09:40', '10:25', '11:10', '11:55', '12:40'],
    secondSessionStarts: const ['14:40', '15:25', '16:10', '16:55', '17:40'],
  );

  addTemplate(
    facilities: const ['과자가게', '피자가게'],
    firstSessionStarts: const ['09:45', '10:35', '11:25', '12:15'],
    secondSessionStarts: const ['14:45', '15:35', '16:25', '17:15'],
  );

  return DayFacilitySlotsDoc(
    dayId: id,
    facilitySlots: docs,
  );
}

List<FacilityMapNode> buildMapNodes() {
  return const [
    FacilityMapNode(name: '피자가게', floor: '3층', x: 0.09, y: 0.70),
    FacilityMapNode(name: '과자가게', floor: '3층', x: 0.31, y: 0.70),
    FacilityMapNode(name: '키즈미디어 스튜디오', floor: '3층', x: 0.50, y: 0.70),
    FacilityMapNode(name: '방송국', floor: '3층', x: 0.60, y: 0.70),
    FacilityMapNode(name: '사회복지관', floor: '3층', x: 0.69, y: 0.70),
    FacilityMapNode(name: '해양경찰구조대', floor: '3층', x: 0.79, y: 0.70),
    FacilityMapNode(name: '스마트해상교통관제센터', floor: '3층', x: 0.89, y: 0.70),
    FacilityMapNode(name: '우주센터', floor: '3층', x: 0.95, y: 0.75),
    FacilityMapNode(name: '마법사학교', floor: '3층', x: 0.93, y: 0.80),
    FacilityMapNode(name: '택배회사', floor: '3층', x: 0.38, y: 0.81),
    FacilityMapNode(name: '꽃집', floor: '3층', x: 0.45, y: 0.81),
    FacilityMapNode(name: '슈퍼마켓', floor: '3층', x: 0.52, y: 0.81),
    FacilityMapNode(name: '전기안전센터', floor: '3층', x: 0.58, y: 0.81),
    FacilityMapNode(name: '소방서', floor: '3층', x: 0.66, y: 0.81),
    FacilityMapNode(name: '스마트건설사이트', floor: '3층', x: 0.73, y: 0.81),
    FacilityMapNode(name: '클라이밍아레나', floor: '3층', x: 0.31, y: 0.85),
    FacilityMapNode(name: '경찰서', floor: '3층', x: 0.37, y: 0.85),
    FacilityMapNode(name: '메타버스월드', floor: '3층', x: 0.44, y: 0.83),
    FacilityMapNode(name: '디자인센터', floor: '3층', x: 0.47, y: 0.85),
    FacilityMapNode(name: 'VR게임스테이션', floor: '3층', x: 0.54, y: 0.84),
    FacilityMapNode(name: '자동차정비소', floor: '3층', x: 0.66, y: 0.85),
    FacilityMapNode(name: '미용실', floor: '3층', x: 0.08, y: 0.88),
    FacilityMapNode(name: '빵부장연구소', floor: '3층', x: 0.34, y: 0.94),
    FacilityMapNode(name: '로봇공학연구소', floor: '3층', x: 0.46, y: 0.94),
    FacilityMapNode(name: '업사이클링팩토리', floor: '3층', x: 0.55, y: 0.94),
    FacilityMapNode(name: '공룡캠프', floor: '3층', x: 0.69, y: 0.94),
    FacilityMapNode(name: '동물병원', floor: 'M층', x: 0.72, y: 0.41),
    FacilityMapNode(name: '레이싱경기장', floor: 'M층', x: 0.79, y: 0.41),
    FacilityMapNode(name: '병원신생아실', floor: 'M층', x: 0.29, y: 0.56),
    FacilityMapNode(name: '애니메이션스튜디오', floor: 'M층', x: 0.52, y: 0.42),
    FacilityMapNode(name: '치과의원', floor: 'M층', x: 0.29, y: 0.51),
    FacilityMapNode(name: '슈즈아틀리에', floor: 'M층', x: 0.75, y: 0.57),
    FacilityMapNode(name: '신문사', floor: 'M층', x: 0.56, y: 0.58),
    FacilityMapNode(name: 'AR신발패션실', floor: 'M층', x: 0.41, y: 0.62),
    FacilityMapNode(name: '드론연구소', floor: 'M층', x: 0.79, y: 0.57),
    FacilityMapNode(name: '달콤카페', floor: 'M층', x: 0.62, y: 0.62),
    FacilityMapNode(name: '야구경기장', floor: 'M층', x: 0.86, y: 0.42),
    FacilityMapNode(name: '외과수술실', floor: 'M층', x: 0.29, y: 0.61),
    FacilityMapNode(name: 'K-POP스테이지', floor: 'M층', x: 0.09, y: 0.77),
    FacilityMapNode(name: '히스토리TV', floor: 'M층', x: 0.09, y: 0.82),
    FacilityMapNode(name: '디지털갤러리', floor: 'M층', x: 0.53, y: 0.62),
  ];
}

List<TimeOfDay> _mergeSessionStarts(
  List<String> firstSession,
  List<String> secondSession,
) {
  return [...firstSession, ...secondSession].map(_parseTime).toList();
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}

String _floorOf(String facility) {
  const mFloorFacilities = {
    '동물병원',
    '레이싱경기장',
    '병원신생아실',
    '애니메이션스튜디오',
    '치과의원',
    '슈즈아틀리에',
    '신문사',
    'AR신발패션실',
    '야구경기장',
    '외과수술실',
    '디지털갤러리',
    '히스토리TV',
  };
  if (mFloorFacilities.contains(facility)) return 'M층';
  return '3층';
}
