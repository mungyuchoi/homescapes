import 'package:flutter/material.dart';

class AppTerms {
  const AppTerms._();

  static const version = '2026-05-11';
  static const title = '서비스 이용약관 및 커뮤니티 규칙';
  static const supportPath = '프로필 > 설정 > 고객센터';
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF121417) : const Color(0xFFF2F3F6);
    final cardBg = isDark ? const Color(0xFF1D222A) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFFF1F3F8)
        : const Color(0xFF171A21);
    final bodyColor = isDark
        ? const Color(0xFFD9E0ED)
        : const Color(0xFF424A59);
    final mutedColor = isDark
        ? const Color(0xFFA8B1C2)
        : const Color(0xFF7A8190);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor),
        ),
        title: Text(
          '이용약관',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Text(
              AppTerms.title,
              style: TextStyle(
                color: titleColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '버전 ${AppTerms.version}',
              style: TextStyle(color: mutedColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _TermsSection(
              cardBg: cardBg,
              titleColor: titleColor,
              bodyColor: bodyColor,
              title: '커뮤니티 안전 원칙',
              paragraphs: const [
                '꿈의카드는 이용자가 게시글, 댓글, 이미지, 문의를 작성할 수 있는 커뮤니티 서비스입니다.',
                '서비스에는 불쾌하거나 차별적인 표현, 괴롭힘, 위협, 성적 콘텐츠, 폭력적 콘텐츠, 스팸, 사칭, 불법 행위 안내 등 objectionable content와 abusive users에 대해 무관용 원칙을 적용합니다.',
                '운영자는 신고된 콘텐츠와 계정을 검토하고 필요한 경우 콘텐츠 숨김, 삭제, 이용 제한, 계정 차단 또는 탈퇴 조치를 할 수 있습니다.',
              ],
            ),
            const SizedBox(height: 12),
            _TermsSection(
              cardBg: cardBg,
              titleColor: titleColor,
              bodyColor: bodyColor,
              title: '사용자 의무',
              paragraphs: const [
                '다른 사용자를 존중하고, 개인 정보나 타인의 권리를 침해하는 내용을 게시하지 않아야 합니다.',
                '카드 교환, 정보 공유, 문의 기능을 악용하거나 허위 정보, 반복 광고, 자동화된 스팸을 등록해서는 안 됩니다.',
                '법령, App Store 정책, 본 약관과 커뮤니티 규칙을 위반하는 사용자는 사전 통지 없이 이용이 제한될 수 있습니다.',
              ],
            ),
            const SizedBox(height: 12),
            _TermsSection(
              cardBg: cardBg,
              titleColor: titleColor,
              bodyColor: bodyColor,
              title: '신고와 차단',
              paragraphs: const [
                '게시글이나 댓글의 더보기 메뉴에서 신고를 제출할 수 있으며, 신고 내용은 운영자가 검토합니다.',
                '사용자 프로필 또는 게시글/댓글 메뉴에서 abusive user를 차단할 수 있습니다. 차단하면 해당 사용자의 게시글과 댓글이 내 화면에서 가려집니다.',
                '차단 목록은 프로필 > 설정 > 차단 내역 관리에서 확인하고 해제할 수 있습니다.',
              ],
            ),
            const SizedBox(height: 12),
            _TermsSection(
              cardBg: cardBg,
              titleColor: titleColor,
              bodyColor: bodyColor,
              title: '지원 및 문의',
              paragraphs: const [
                '앱 사용 중 질문, 신고 처리 문의, 계정 제한 이의 제기, 지원 요청은 ${AppTerms.supportPath}에서 보낼 수 있습니다.',
                '문의에는 계정 정보, 문제 상황, 관련 게시글 또는 댓글 내용을 함께 적어 주시면 더 빠르게 확인할 수 있습니다.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.cardBg,
    required this.titleColor,
    required this.bodyColor,
    required this.title,
    required this.paragraphs,
  });

  final Color cardBg;
  final Color titleColor;
  final Color bodyColor;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F7A8190)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                paragraph,
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
