import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_models.dart';
import '../utils/facility_helpers.dart';
import '../utils/user_access_utils.dart';
import '../widgets/common_widgets.dart';

const _spotPrimaryColor = Color(0xFFED9A3A);
const _spotPrimarySoftColor = Color(0xFFFFF1E0);
const _spotPrimaryBorderColor = Color(0xFFFFD7A5);

Future<void> showSpotDetailBottomSheet({
  required BuildContext context,
  required SpotDoc spot,
  required FacilitySlot slot,
  required FacilityStatus status,
  required List<TimeOfDay> remaining,
  required DateTime now,
  required String dayId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final bottomSystemInset = MediaQuery.of(context).viewPadding.bottom;
      return FractionallySizedBox(
        heightFactor: 0.93,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSystemInset),
          child: DefaultTabController(
            length: 3,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    color: _spotPrimaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            spot.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (spot.galleryImages.isNotEmpty)
                    _SpotImageCarousel(images: spot.galleryImages)
                  else
                    Container(
                      height: 170,
                      width: double.infinity,
                      color: const Color(0xFFF0F3F8),
                      alignment: Alignment.center,
                      child: const Text(
                        '이미지 없음',
                        style: TextStyle(
                          color: Color(0xFF7A8190),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SpotInfoDot(
                            icon: Icons.schedule_rounded,
                            label: '${spot.durationMin}분',
                          ),
                          const SizedBox(width: 10),
                          SpotInfoDot(
                            icon: Icons.psychology_alt_outlined,
                            label: spot.aptType,
                          ),
                          const SizedBox(width: 10),
                          SpotInfoDot(
                            icon: Icons.savings_outlined,
                            label: spot.joyReward,
                          ),
                          const SizedBox(width: 10),
                          SpotInfoDot(
                            icon: Icons.person_outline_rounded,
                            label: spot.ageRule,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const TabBar(
                    labelColor: Color(0xFFED9A3A),
                    unselectedLabelColor: Color(0xFF8B90A0),
                    indicatorColor: Color(0xFFED9A3A),
                    tabs: [
                      Tab(text: '체험관 정보'),
                      Tab(text: '체험관 대화'),
                      Tab(text: '운영 시간'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _SpotInfoTab(
                          spot: spot,
                          slot: slot,
                          status: status,
                          remaining: remaining,
                          now: now,
                        ),
                        _SpotChatTab(spot: spot),
                        _SpotScheduleTab(
                          slot: slot,
                          status: status,
                          remaining: remaining,
                          now: now,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SpotImageCarousel extends StatefulWidget {
  const _SpotImageCarousel({required this.images});

  final List<String> images;

  @override
  State<_SpotImageCarousel> createState() => _SpotImageCarouselState();
}

class _SpotImageCarouselState extends State<_SpotImageCarousel> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _pageIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE8EDF4),
                    alignment: Alignment.center,
                    child: const Text('이미지를 불러올 수 없습니다.'),
                  );
                },
              );
            },
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  final selected = index == _pageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: selected ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotInfoTab extends StatelessWidget {
  const _SpotInfoTab({
    required this.spot,
    required this.slot,
    required this.status,
    required this.remaining,
    required this.now,
  });

  final SpotDoc spot;
  final FacilitySlot slot;
  final FacilityStatus status;
  final List<TimeOfDay> remaining;
  final DateTime now;

  Future<void> _openJobLink(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty || url == '#') {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final jobs = spot.jobs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Row(
          children: [
            StatChip(
              color: _spotPrimaryColor,
              label: FacilityHelpers.statusLabel(
                slot: slot,
                status: status,
                now: now,
              ),
            ),
            const SizedBox(width: 8),
            StatChip(
              color: const Color(0xFF4E5D7F),
              label: '남은 회차 ${remaining.length}개',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            spot.description,
            style: const TextStyle(
              color: Color(0xFF474B57),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '체험직종',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (jobs.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              spot.jobDescription,
              style: const TextStyle(
                color: Color(0xFF495062),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...jobs.map((job) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E8F1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.name,
                    style: const TextStyle(
                      color: Color(0xFF212534),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    style: const TextStyle(
                      color: Color(0xFF4A5164),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (job.detailUrl.isNotEmpty &&
                      job.detailUrl.trim() != '#') ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _openJobLink(job.detailUrl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF556C95),
                        side: const BorderSide(color: Color(0xFFCAD3E5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('직업 링크'),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _spotPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotChatTab extends StatefulWidget {
  const _SpotChatTab({required this.spot});

  final SpotDoc spot;

  @override
  State<_SpotChatTab> createState() => _SpotChatTabState();
}

class _SpotChatTabState extends State<_SpotChatTab> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSending = false;

  CollectionReference<Map<String, dynamic>> get _messageRef {
    return _firestore
        .collection('spots')
        .doc(widget.spot.spotId)
        .collection('messages');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _ensureCanWrite() async {
    if (_auth.currentUser == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 먼저 해주세요.')));
      return false;
    }
    final isRestricted = await UserAccessUtils.isCurrentUserRestricted();
    if (!isRestricted) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이용금지된 회원입니다. 관리자에게 문의하세요.')),
    );
    return false;
  }

  Future<void> _sendMessage() async {
    if (!await _ensureCanWrite()) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isSending = false);
      return;
    }
    final uid = user.uid;
    final userName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : '게스트';

    try {
      await _messageRef.add({
        'text': text,
        'uid': uid,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': DateTime.now().millisecondsSinceEpoch,
      });
      _controller.clear();
      await _trimMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('대화 전송에 실패했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _trimMessages() async {
    final snapshot = await _messageRef
        .orderBy('createdAt', descending: true)
        .get();
    if (snapshot.docs.length <= 50) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs.skip(50)) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _auth.currentUser?.uid;
    final isSignedIn = myUid != null;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messageRef
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    '대화 목록을 불러오지 못했습니다.',
                    style: TextStyle(
                      color: Color(0xFF767C8D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    '아직 대화가 없어요.\n첫 메시지를 남겨보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF767C8D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final senderUid = _string(data['uid']);
                  final isMine = myUid != null && senderUid == myUid;
                  final name = _string(data['userName'], fallback: '게스트');
                  final message = _string(data['text']);
                  final when =
                      _toDateTime(data['createdAt']) ??
                      _toDateTime(data['createdAtClient']);

                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? _spotPrimarySoftColor
                              : const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMine
                                ? _spotPrimaryBorderColor
                                : const Color(0xFFE1E6F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Color(0xFF4E5669),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xFF1E2230),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(context, when),
                              style: const TextStyle(
                                color: Color(0xFF8A90A0),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE7EBF2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  readOnly: !isSignedIn,
                  onTap: () async {
                    if (!isSignedIn) {
                      await _ensureCanWrite();
                      return;
                    }
                    final allowed = await _ensureCanWrite();
                    if (!allowed && mounted) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '체험관 대화를 입력하세요',
                    filled: true,
                    fillColor: const Color(0xFFF4F6FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 44,
                child: FilledButton(
                  onPressed: _isSending ? null : _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: _spotPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final parsed = value.toString().trim();
    if (parsed.isEmpty) return fallback;
    return parsed;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final asString = value?.toString();
    if (asString == null || asString.isEmpty) return null;
    return DateTime.tryParse(asString);
  }

  String _formatTime(BuildContext context, DateTime? value) {
    if (value == null) return '방금 전';
    final local = value.toLocal();
    final tod = TimeOfDay(hour: local.hour, minute: local.minute);
    final timeLabel = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(tod, alwaysUse24HourFormat: false);
    return '${local.month}/${local.day} $timeLabel';
  }
}

class _SpotScheduleTab extends StatelessWidget {
  const _SpotScheduleTab({
    required this.slot,
    required this.status,
    required this.remaining,
    required this.now,
  });

  final FacilitySlot slot;
  final FacilityStatus status;
  final List<TimeOfDay> remaining;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final allSlots = slot.daySlots;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        Row(
          children: [
            StatChip(
              color: _spotPrimaryColor,
              label: FacilityHelpers.statusLabel(
                slot: slot,
                status: status,
                now: now,
              ),
            ),
            const SizedBox(width: 8),
            StatChip(
              color: const Color(0xFF4E5D7F),
              label: '전체 회차 ${allSlots.length}개',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          '남은 회차',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (remaining.isEmpty)
          const _EmptyScheduleCard(label: '오늘 남은 회차가 없습니다.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: remaining.map((slotTime) {
              return _SlotChip(
                timeLabel: FacilityHelpers.formatTimeOfDay(slotTime),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        const Text(
          '오늘 전체 회차',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (allSlots.isEmpty)
          const _EmptyScheduleCard(label: '회차 정보가 없습니다.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSlots.map((slotTime) {
              return _SlotChip(
                timeLabel: FacilityHelpers.formatTimeOfDay(slotTime),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.timeLabel});

  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE6F5)),
      ),
      child: Text(
        timeLabel,
        style: const TextStyle(
          color: Color(0xFF2D3444),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF495062),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
