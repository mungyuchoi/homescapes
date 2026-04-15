import 'package:flutter/material.dart';

import '../features/profile/data/repositories/follow_repository.dart';

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    super.key,
    required this.uid,
    required this.initialTabIndex,
  });

  final String uid;
  final int initialTabIndex;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FollowRepository _followRepository = FollowRepository();

  late int _selectedTabIndex;
  List<FollowUserItem> _followers = const <FollowUserItem>[];
  List<FollowUserItem> _following = const <FollowUserItem>[];
  bool _isLoading = true;
  String? _error;

  String? get _myUid => _followRepository.currentUid;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final followers = await _followRepository.getFollowers(widget.uid);
      final following = await _followRepository.getFollowing(widget.uid);
      if (!mounted) return;
      setState(() {
        _followers = followers;
        _following = following;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabBg = isDark ? const Color(0xFF262D39) : const Color(0xFFDCE1E8);
    final activeTabBg = isDark ? const Color(0xFF394255) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1D222A) : const Color(0xFFF8FAFD);
    final list = _selectedTabIndex == 0 ? _followers : _following;
    final followerCount = _followers.length;
    final followingCount = _following.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tabBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: '팔로워 $followerCount',
                        selected: _selectedTabIndex == 0,
                        activeColor: activeTabBg,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: '팔로잉 $followingCount',
                        selected: _selectedTabIndex == 1,
                        activeColor: activeTabBg,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    '목록을 불러오지 못했습니다.\n$_error',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (list.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _selectedTabIndex == 0
                        ? '팔로워가 없습니다.'
                        : '팔로잉이 없습니다.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8C1D1)
                          : const Color(0xFF7D8698),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _FollowAvatar(photoUrl: user.photoUrl),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFFE8EDF8)
                                        : const Color(0xFF232836),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.bio.isNotEmpty ? user.bio : user.uid,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFFAAB3C4)
                                        : const Color(0xFF8A92A2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_myUid != null && _myUid != user.uid)
                            StreamBuilder<bool>(
                              stream: _followRepository.watchIsFollowing(
                                myUid: _myUid!,
                                targetUid: user.uid,
                              ),
                              builder: (context, snapshot) {
                                final isFollowing = snapshot.data ?? false;
                                return FilledButton(
                                  onPressed: () async {
                                    await _followRepository.toggleFollow(
                                      myUid: _myUid!,
                                      targetUid: user.uid,
                                    );
                                    await _load();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE1E6EE),
                                    foregroundColor: const Color(0xFF636D7D),
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: Text(
                                    isFollowing ? '팔로잉' : '팔로우',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF242834) : const Color(0xFF8D95A3),
          ),
        ),
      ),
    );
  }
}

class _FollowAvatar extends StatelessWidget {
  const _FollowAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFDCE2EC),
      backgroundImage: photoUrl.startsWith('http') ? NetworkImage(photoUrl) : null,
      child: photoUrl.startsWith('http')
          ? null
          : const Icon(Icons.smart_toy_rounded, color: Color(0xFF8C96AA)),
    );
  }
}
