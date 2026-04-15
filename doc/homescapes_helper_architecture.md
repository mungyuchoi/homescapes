# Homescapes Helper App 아키텍처 / 요구사항 정리

## 1. 프로젝트 개요

이 앱은 **꿈의 집(Homescapes) 유저를 위한 보조 커뮤니티 앱**이다.  
핵심 목적은 다음과 같다.

- 시즌별 카드 정보를 쉽게 관리할 수 있도록 지원
- 내가 **필요한 카드 / 남는 카드**를 쉽게 등록하고 공유
- 시즌 종료일, 이벤트 보상 타이머, 개인 기록 등을 한눈에 확인
- 커뮤니티 피드를 통해 자유글, 꿀팁, 시즌 정보를 소통
- 알림(FCM)을 통해 카드 요청, 시즌 종료 임박, 보상 수령 타이밍 등을 안내

앱은 **Flutter**로 개발하고, 백엔드는 **Firebase**를 중심으로 구성한다.

사용 예정 기술:
- Flutter
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging (FCM)
- Firebase Cloud Functions
- Firebase Analytics (선택)
- Firebase Crashlytics (선택)
- Firebase Remote Config (선택)

---

## 2. 제품 포지셔닝

이 앱은 단순 게시판이 아니라 아래 3가지를 동시에 수행하는 서비스다.

1. **카드 교환/공유 보조 도구**
2. **시즌 일정/이벤트 정보 관리 도구**
3. **Homescapes 유저 커뮤니티**

정의:

> 꿈의 집 유저들이 카드 교환, 시즌 일정, 개인 기록을 더 쉽게 관리할 수 있도록 도와주는 커뮤니티형 보조 앱

---

## 3. 핵심 탭 구조

앱의 메인 탭은 아래 4개로 구성한다.

### 3.1 피드 탭

커뮤니티 중심 탭

#### 목적
- 자유로운 소통
- 꿀팁 공유
- 시즌 정보 공유
- 카드 교환 후기 공유

#### 카테고리 예시
- 자유게시판
- 꿀팁
- 시즌 정보
- 카드 교환 후기
- 이벤트 공략

#### 주요 기능
- 글 작성
- 글 목록 조회
- 댓글 작성
- 좋아요
- 카테고리별 필터
- 인기글/최신글 정렬

---

### 3.2 카드 공유 탭

앱의 핵심 기능 탭

#### 목적
- 내가 필요한 카드 등록
- 내가 남는 카드 등록
- 다른 사용자와 카드 교환 연결

#### 내부 구조
카드 공유 탭 안에서 2개의 내부 페이지 또는 세그먼트로 구성

- 필요한 카드
- 남는 카드

#### 주요 기능
- 현재 시즌 카드 목록 조회
- 세트별 카드 보기
- 카드 검색
- 일반 카드 / 골드 카드 구분
- 내가 필요한 카드 다중 선택
- 내가 남는 카드 다중 선택
- 카드 공유 상태 저장
- 특정 카드가 필요한 사용자 찾기
- 특정 카드를 갖고 있는 사용자 찾기
- 추후 자동 매칭 확장 가능

#### UX 원칙
- 사용자가 카드명을 직접 입력하지 않음
- 사용자는 카드 목록에서 **선택만** 하도록 설계
- 시즌 변경 시 카드 목록도 자동으로 교체 가능해야 함

---

### 3.3 시즌 일정 탭

재방문율을 높이는 핵심 탭

#### 목적
- 현재 시즌 현황 확인
- 시즌 종료일까지 남은 날짜 확인
- 이벤트 보상 타이머 확인
- 카드팩 오픈 전략 및 공식 정보 요약 확인

#### 주요 기능
- 현재 시즌 제목 표시
- 시즌 종료 D-day 표시
- 시즌 시작일 / 종료일 표시
- 이벤트 보상 타이머 표시
- 카드 요청 가능 여부 표시
- 카드 전송 횟수 상태 표시
- 카드팩 전략 가이드
- Playrix 공식 정보 요약 카드
- 시즌 체크리스트

#### 화면 예시 구성
1. 상단 요약
   - 시즌명
   - 종료 D-day
   - 남은 일수
   - 오늘 해야 할 일

2. 중간 섹션
   - 이벤트 보상 카운트다운
   - 오늘 카드 요청 가능 여부
   - 전송 가능 횟수 정보
   - 시즌 진행 가이드

3. 하단 섹션
   - 카드팩 전략
   - 공식 정보 요약
   - 유저 팁 모음 링크

---

### 3.4 프로필 탭

개인 기록 및 설정 탭

#### 목적
- 내가 작성한 글 확인
- 내가 등록한 카드 상태 확인
- 개인 일정/보상 기록 관리
- 알림 설정 관리

#### 주요 기능
- 내 프로필 정보
- 내가 작성한 피드 글 목록
- 내가 등록한 필요 카드 / 남는 카드 조회
- 대리/보상 기록 관리
- 다음 보상 수령 예정일 카운트다운
- 알림 ON/OFF
- 푸시 토큰 등록 상태 확인
- 로그아웃

---

## 4. 인증 / 로그인 설계

### 4.1 로그인 필요 이유
이 앱은 커뮤니티, 카드 상태 저장, 알림 발송, 개인 기록 저장 기능이 있으므로 로그인 기능이 필요하다.

### 4.2 인증 방식 후보
- Google 로그인
- Apple 로그인
- 익명 로그인
- 이메일 로그인

### 4.3 MVP 추천
- Android: Google 로그인
- iOS: Apple 로그인 + Google 로그인
- 비회원 체험이 필요하면 익명 로그인 추가

### 4.4 사용자 계정으로 관리할 항목
- UID
- 닉네임
- 프로필 이미지
- 푸시 토큰
- 내가 등록한 카드 상태
- 내가 작성한 글
- 알림 설정
- 시즌별 개인 기록

---

## 5. 전체 기술 아키텍처

### 5.1 프론트엔드
- Flutter
- Riverpod 또는 Bloc 상태관리
- go_router 또는 auto_route
- freezed / json_serializable 모델 추천

### 5.2 백엔드
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Cloud Functions

### 5.3 선택 도구
- Crashlytics
- Analytics
- Remote Config

---

## 6. 권장 Flutter 아키텍처

권장 구조는 **Feature-first + Clean Architecture Lite** 방식이다.

### 디렉토리 예시

```text
lib/
  core/
    constants/
    utils/
    services/
    theme/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    feed/
      data/
      domain/
      presentation/
    card_share/
      data/
      domain/
      presentation/
    season/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      presentation/
  app/
    router/
    app.dart
  main.dart
```

### 레이어 설명
- **presentation**: 화면, 위젯, provider
- **domain**: entity, usecase, repository interface
- **data**: firebase datasource, dto, repository 구현체

### 장점
- 기능별 분리가 명확함
- 시즌/카드/피드 기능 확장에 유리
- 테스트 및 유지보수가 쉬움

---

## 7. Firestore 데이터 모델 설계

### 7.1 users

`users/{uid}`

```json
{
  "uid": "user_uid",
  "nickname": "문규",
  "photoUrl": "",
  "provider": "google",
  "fcmTokens": ["token1", "token2"],
  "notificationEnabled": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "lastLoginAt": "timestamp"
}
```

---

### 7.2 seasons

`seasons/{seasonId}`

```json
{
  "seasonId": "season_2026_04",
  "title": "Spring Collection",
  "startAt": "timestamp",
  "endAt": "timestamp",
  "totalCards": 150,
  "isActive": true,
  "createdAt": "timestamp"
}
```

#### 목적
- 현재 활성 시즌 조회
- 시즌 종료 D-day 계산
- 카드 공유 데이터와 연결

---

### 7.3 season cards

`seasons/{seasonId}/cards/{cardId}`

```json
{
  "cardId": "card_001",
  "seasonId": "season_2026_04",
  "name": "Golden Lamp",
  "setName": "Living Room",
  "setOrder": 1,
  "cardOrder": 1,
  "rarity": "normal",
  "imageUrl": "https://...",
  "thumbnailUrl": "https://...",
  "isActive": true,
  "createdAt": "timestamp"
}
```

#### 필드 설명
- `rarity`: `normal` 또는 `gold`
- `setName`: 카드 묶음 이름
- `cardOrder`: 세트 내 정렬 순서
- `imageUrl`: Storage 업로드 이미지 주소

#### 운영 원칙
- 시즌이 바뀔 때마다 새 시즌 카드 목록 생성
- 앱은 active 시즌 기준으로만 동작
- 사용자는 cardId만 선택하여 저장

---

### 7.4 card_posts

`card_posts/{postId}`

```json
{
  "postId": "post_001",
  "uid": "user_uid",
  "seasonId": "season_2026_04",
  "needCardIds": ["card_001", "card_002"],
  "haveCardIds": ["card_010", "card_020"],
  "memo": "일반 카드 위주로 교환 원해요",
  "status": "active",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 목적
- 카드 공유 탭의 공개 게시글 데이터
- 필요 카드 / 남는 카드 상태 저장
- 카드 교환 요청 기반 제공

---

### 7.5 user_card_status

`users/{uid}/card_status/{seasonId}`

```json
{
  "seasonId": "season_2026_04",
  "needCardIds": ["card_001", "card_005"],
  "haveCardIds": ["card_010", "card_021"],
  "updatedAt": "timestamp"
}
```

#### 목적
- 개인 최신 카드 상태 관리
- 프로필 탭에서 즉시 조회
- 추후 자동 매칭 기능에 활용

---

### 7.6 feed_posts

`feed_posts/{postId}`

```json
{
  "postId": "feed_001",
  "uid": "user_uid",
  "category": "tip",
  "title": "이번 시즌 카드팩 팁",
  "content": "내용",
  "likeCount": 10,
  "commentCount": 2,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "active"
}
```

#### category 예시
- `free`
- `tip`
- `season`
- `review`
- `event`

---

### 7.7 feed_comments

`feed_posts/{postId}/comments/{commentId}`

```json
{
  "commentId": "comment_001",
  "uid": "user_uid",
  "content": "좋은 정보 감사합니다",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

### 7.8 reward_logs

`users/{uid}/reward_logs/{rewardLogId}`

```json
{
  "type": "daily_reward",
  "title": "15분 보상 기록",
  "recordedAt": "timestamp",
  "nextAvailableAt": "timestamp",
  "memo": "오늘 3번째 보상까지 수령"
}
```

#### 목적
- 보상 기록 저장
- 다음 수령 예정 시각 계산
- 프로필 탭 카운트다운 연동
- 알림 기준 데이터 제공

---

### 7.9 notifications

`notifications/{notificationId}`

```json
{
  "uid": "user_uid",
  "type": "season_end",
  "title": "시즌 종료 임박",
  "body": "시즌 종료까지 3일 남았습니다.",
  "isRead": false,
  "createdAt": "timestamp"
}
```

---

## 8. Firebase Storage 구조

카드 이미지는 Firebase Storage에 저장한다.

### 경로 예시

```text
card_images/{seasonId}/{cardId}.png
```

예시:
- `card_images/season_2026_04/card_001.png`
- `card_images/season_2026_04/card_002.png`

### 운영 원칙
- 관리자가 시즌별 카드 이미지를 업로드
- 다운로드 URL을 Firestore 카드 마스터에 저장
- 사용자는 직접 업로드하지 않고 선택만 수행

---

## 9. 카드 공유 기능 상세 설계

### 9.1 사용자 흐름
1. 카드 공유 탭 진입
2. 현재 활성 시즌 조회
3. 시즌 카드 목록 불러오기
4. 필요한 카드 / 남는 카드 선택
5. 메모 입력
6. 저장
7. 공개 리스트 및 내 상태 반영

### 9.2 카드 선택 UI
추천 UI:
- 세트별 섹션 표시
- 카드 이미지 + 카드명 표시
- 일반/골드 뱃지 표시
- 선택 시 강조
- 검색 기능 제공

### 9.3 저장 방식
실제 저장은 카드명 전체가 아니라 `cardId` 배열로 저장

예:
- `needCardIds`
- `haveCardIds`

### 9.4 장점
- 텍스트 오입력 방지
- 시즌 교체 대응 쉬움
- 데이터 중복 감소
- 자동 매칭 확장 용이

---

## 10. 시즌 정보 운영 구조

### 10.1 시즌 교체 절차
1. 새 시즌 문서 생성
2. 새 시즌 카드 150장 이미지 업로드
3. 카드 메타데이터 Firestore 등록
4. 기존 시즌 비활성화
5. 새 시즌 활성화

### 10.2 운영 방식
초기에는 수동 업로드 가능  
추후에는 CSV 또는 관리자 페이지로 자동화 가능

### 10.3 권장 운영 방식
- CSV 메타데이터 파일 준비
- 이미지 파일명 규칙 통일
- 업로드 스크립트 또는 관리자 페이지로 일괄 등록

---

## 11. 알림(FCM) 구조

### 11.1 알림 목적
- 시즌 종료 임박 알림
- 보상 수령 가능 시간 알림
- 카드 공유 관련 알림
- 공지사항 알림
- 댓글/좋아요 알림

### 11.2 토큰 관리
각 사용자 문서에 `fcmTokens` 저장

### 11.3 발송 방식
#### 로컬 알림
- 개인 보상 타이머
- 다음 기록 시점 알림

#### 서버 발송(FCM)
- 시즌 종료 임박
- 공지사항
- 카드 반응 알림
- 댓글/좋아요 알림

### 11.4 추천 전략
- 개인 카운트다운: 로컬 알림 우선
- 커뮤니티/운영성 알림: FCM 사용

---

## 12. Cloud Functions 활용 포인트

Cloud Functions는 아래 기능에 특히 유용하다.

### 12.1 사용자 반응 알림
- 게시글 댓글 작성 시 작성자에게 FCM 발송
- 좋아요 발생 시 FCM 발송

### 12.2 카드 공유 반응 알림
- 특정 카드가 필요한 사용자에게 새 게시글 등장 시 알림
- 추후 자동 매칭 시 매칭 결과 알림

### 12.3 시즌 종료 임박 알림
- 종료 7일 전
- 종료 3일 전
- 종료 1일 전

### 12.4 관리자 공지 발송
- 공지 게시 시 전체 사용자 또는 특정 사용자군에게 알림 발송

### 12.5 데이터 정리
- 오래된 inactive 카드 게시글 정리
- 중복 알림 정리
- 비정상 데이터 보정

---

## 13. 기능별 상세 요구사항

### 13.1 피드
- 카테고리별 글 조회
- 최신순/인기순 정렬
- 댓글 작성
- 좋아요
- 신고 기능(추후)

### 13.2 카드 공유
- 시즌 기준 카드 선택
- 필요/남는 카드 동시 등록
- 공개/비공개 옵션(추후)
- 카드별 사용자 조회
- 매칭 기능(추후)

### 13.3 시즌 일정
- 현재 시즌 D-day
- 이벤트 보상 타이머
- 카드팩 전략 텍스트
- 공식 정보 요약
- 오늘 해야 할 일 요약

### 13.4 프로필
- 내 글
- 내 카드 상태
- 보상 기록
- 알림 설정
- 로그아웃

### 13.5 운영 기능
- 시즌 카드 데이터 등록
- 공지사항 등록
- 카드 이미지 업로드
- 시즌 활성화 전환

---

## 14. 보안 / 권한 설계

### 14.1 Firestore 보안 규칙 원칙
- 사용자 본인 문서만 수정 가능
- 공개 게시글은 읽기 허용
- 작성자만 자기 글 수정/삭제 가능
- 관리자만 시즌/카드 마스터 수정 가능

### 14.2 관리자 권한
사용자 문서에 `role: admin` 또는 커스텀 클레임 사용

예:
```json
{
  "role": "admin"
}
```

---

## 15. MVP 우선순위

### 1차 MVP
- 로그인
- 피드 탭
- 카드 공유 탭
- 시즌 일정 탭
- 프로필 탭
- 시즌 카드 마스터 조회
- 필요/남는 카드 저장
- 보상 기록 저장
- 기본 푸시 알림

### 2차
- 댓글 알림
- 좋아요 알림
- 카드별 사용자 찾기 최적화
- 관리자 업로드 페이지
- 신고/차단 기능

### 3차
- 자동 매칭
- 인기 카드 통계
- 시즌별 랭킹
- 추천 피드
- 팀/그룹 기능

---

## 16. 추천 개발 순서

1. Firebase 프로젝트 생성
2. Auth 설정
3. Firestore 기본 컬렉션 생성
4. 시즌/카드 마스터 구조 구축
5. 카드 공유 UI 구현
6. 피드 구현
7. 프로필 및 보상 기록 구현
8. 로컬 알림 구현
9. FCM 연동
10. Cloud Functions로 서버 알림 자동화

---

## 17. 이름 후보 방향 메모

앱 이름은 가능하면 아래 느낌이 좋다.

- 명사 + 명사
- 꿈의 집 분위기와 맞는 이름
- 카드 / 시즌 / 교환 / 커뮤니티 느낌 반영
- 너무 길지 않고 발음 쉬운 이름

예시 방향:
- 카드보드형
- 시즌보드형
- 홈카드형
- 드림노트형

---

## 18. 결론

이 앱은 단순한 팬 커뮤니티가 아니라,  
**카드 공유 + 시즌 관리 + 개인 기록 + 커뮤니티 소통**을 함께 제공하는 보조 앱으로 설계하는 것이 맞다.

기술적으로는 Flutter + Firebase 조합이 적합하며, 다음 구조가 핵심이다.

- Authentication으로 사용자 식별
- Firestore로 시즌/카드/피드/개인기록 저장
- Storage로 카드 이미지 관리
- FCM + Cloud Functions로 알림 자동화
- 카드 데이터는 시즌별 마스터 방식으로 운영
- 사용자는 카드명을 입력하지 않고 선택만 수행

이 구조로 가면 MVP부터 시작해서 추후 자동 매칭, 랭킹, 통계, 운영 도구까지 자연스럽게 확장할 수 있다.
