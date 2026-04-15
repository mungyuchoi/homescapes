import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/community/data/repositories/community_post_repository.dart';
import '../models/app_models.dart';
import '../utils/user_access_utils.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({
    super.key,
    required this.initialCategory,
    required this.categories,
    required this.spotOptions,
    required this.todaySlotsDoc,
    this.editingPost,
  });

  final String initialCategory;
  final List<String> categories;
  final List<SpotDoc> spotOptions;
  final DayFacilitySlotsDoc todaySlotsDoc;
  final CommunityPost? editingPost;

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  static const _maxImages = 10;

  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final CommunityPostRepository _postRepository = CommunityPostRepository();

  late String _selectedCategory;
  final List<XFile> _selectedImages = <XFile>[];
  final List<String> _existingImageUrls = <String>[];
  final List<_RouteDraftItem> _routeDraftItems = <_RouteDraftItem>[];

  bool _isPickingImages = false;
  bool _isSubmitting = false;
  String _authorName = '';
  String _authorPhotoUrl = '';

  bool get _isEditMode => widget.editingPost != null;
  bool get _isRouteCategory => _selectedCategory == '오늘의 루트';
  Future<void> _loadAuthorProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final fallbackName = (authUser?.displayName ?? '').trim();
    final fallbackPhoto = (authUser?.photoURL ?? '').trim();
    String nextName = fallbackName;
    String nextPhoto = fallbackPhoto;

    if (nextName.isEmpty) {
      final emailPrefix = (authUser?.email ?? '').trim().split('@').first.trim();
      if (emailPrefix.isNotEmpty) nextName = emailPrefix;
    }
    if (nextName.isEmpty) nextName = '익명';

    try {
      final uid = authUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = snapshot.data();
        if (data != null) {
          final firestoreName = (data['displayName'] as String? ?? '').trim();
          final firestorePhotoUrl = (data['photoURL'] as String? ?? '').trim();
          final firestorePhotoUrlLegacy = (data['photoUrl'] as String? ?? '').trim();
          if (firestoreName.isNotEmpty) nextName = firestoreName;
          if (firestorePhotoUrl.isNotEmpty) {
            nextPhoto = firestorePhotoUrl;
          } else if (firestorePhotoUrlLegacy.isNotEmpty) {
            nextPhoto = firestorePhotoUrlLegacy;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _authorName = nextName;
      _authorPhotoUrl = nextPhoto;
    });
  }

  @override
  void initState() {
    super.initState();
    final editingPost = widget.editingPost;
    _selectedCategory = editingPost?.category ?? widget.initialCategory;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      final name = (authUser.displayName ?? '').trim();
      final emailPrefix = (authUser.email ?? '').trim().split('@').first.trim();
      _authorName = name.isNotEmpty
          ? name
          : emailPrefix.isNotEmpty
          ? emailPrefix
          : '익명';
      _authorPhotoUrl = (authUser.photoURL ?? '').trim();
    } else {
      _authorName = '익명';
      _authorPhotoUrl = '';
    }
    if (editingPost != null) {
      _contentController.text = editingPost.content;
      _existingImageUrls.addAll(editingPost.imageUrls);
      if (editingPost.routeItems.isNotEmpty) {
        _routeDraftItems.addAll(
          editingPost.routeItems.map(
            (item) => _RouteDraftItem(
              spotId: item.spotId,
              spotName: item.spotName,
              timeRange: item.timeRange,
              noteController: TextEditingController(text: item.note),
            ),
          ),
        );
      }
    }
    if (_isRouteCategory && _routeDraftItems.isEmpty) {
      _routeDraftItems.add(_RouteDraftItem.empty());
    }
    _loadAuthorProfile();
  }

  @override
  void dispose() {
    _contentController.dispose();
    for (final item in _routeDraftItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _openCategorySheet() async {
    final category = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final categories = widget.categories;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F5F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9CDD6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 14),
                ...categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(category),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedCategory == category
                                ? const Color(0xFFED9A3A)
                                : const Color(0xFFE2E5EC),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _categoryIcon(category),
                              color: const Color(0xFF4D5360),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Color(0xFF1F2430),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (category == null || !mounted) return;
    setState(() {
      _selectedCategory = category;
      if (_isRouteCategory && _routeDraftItems.isEmpty) {
        _routeDraftItems.add(_RouteDraftItem.empty());
      }
    });
  }

  Future<void> _pickImages() async {
    if (_isPickingImages || _isSubmitting) return;
    final attachedCount = _selectedImages.length + _existingImageUrls.length;
    if (attachedCount >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지는 최대 10개까지 첨부할 수 있습니다.')),
      );
      return;
    }

    setState(() => _isPickingImages = true);
    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 78,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked.isEmpty || !mounted) return;
      final remain =
          _maxImages - (_selectedImages.length + _existingImageUrls.length);
      setState(() {
        _selectedImages.addAll(picked.take(remain));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addRouteItem() {
    setState(() {
      _routeDraftItems.add(_RouteDraftItem.empty());
    });
  }

  void _removeRouteItem(int index) {
    if (index < 0 || index >= _routeDraftItems.length) return;
    final target = _routeDraftItems[index];
    target.dispose();
    setState(() {
      _routeDraftItems.removeAt(index);
      if (_routeDraftItems.isEmpty) {
        _routeDraftItems.add(_RouteDraftItem.empty());
      }
    });
  }

  List<SpotDoc> get _routeSpotOptions {
    final uniqueById = <String, SpotDoc>{};
    for (final spot in widget.spotOptions) {
      final id = spot.spotId.trim();
      if (id.isEmpty) continue;
      uniqueById.putIfAbsent(id, () => spot);
    }
    final options = uniqueById.values.toList();
    options.sort((a, b) {
      final floorCompare = _floorOrder(a.floor).compareTo(_floorOrder(b.floor));
      if (floorCompare != 0) return floorCompare;
      return a.title.compareTo(b.title);
    });
    return options;
  }

  int _floorOrder(String floor) {
    if (floor == '3층') return 0;
    if (floor == 'M층') return 1;
    return 2;
  }

  String _spotFloorById(String spotId) {
    final normalized = spotId.trim();
    if (normalized.isEmpty) return '';
    for (final spot in _routeSpotOptions) {
      if (spot.spotId == normalized) return spot.floor;
    }
    return '';
  }

  Future<SpotDoc?> _openSpotPicker({required String selectedSpotId}) async {
    final options = _routeSpotOptions;
    if (options.isEmpty) return null;

    return showModalBottomSheet<SpotDoc>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.84,
          minChildSize: 0.6,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 54,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9CDD6),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '체험관 선택',
                          style: TextStyle(
                            color: Color(0xFF1F2533),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '카드를 눌러 루트에 추가할 체험관을 선택하세요',
                          style: TextStyle(
                            color: Color(0xFF687183),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.45,
                          ),
                      itemBuilder: (context, index) {
                        final spot = options[index];
                        final selected = spot.spotId == selectedSpotId;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(spot),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFF3E3)
                                  : const Color(0xFFF7F8FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFED9A3A)
                                    : const Color(0xFFE8ECF4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  spot.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1F28),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  spot.floor,
                                  style: const TextStyle(
                                    color: Color(0xFF707889),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _openTimePicker({
    required List<String> options,
    required String selectedTime,
    required String spotName,
  }) async {
    if (options.isEmpty) return null;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 54,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9CDD6),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '운영시간 선택',
                          style: TextStyle(
                            color: Color(0xFF1F2533),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${spotName.trim().isEmpty ? '체험관' : spotName} 회차를 선택하세요',
                            style: const TextStyle(
                              color: Color(0xFF687183),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.9,
                          ),
                      itemBuilder: (context, index) {
                        final timeLabel = options[index];
                        final selected = timeLabel == selectedTime;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(timeLabel),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFF3E3)
                                  : const Color(0xFFF7F8FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFED9A3A)
                                    : const Color(0xFFE8ECF4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 17,
                                  color: selected
                                      ? const Color(0xFFED9A3A)
                                      : const Color(0xFF7E8798),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    timeLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F28),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _resolveTimeOptions({
    required String selectedSpotId,
    required String selectedSpotName,
  }) {
    final normalizedSpotId = selectedSpotId.trim();
    final normalizedName = _normalize(selectedSpotName);
    final options = <String>{};
    for (final doc in widget.todaySlotsDoc.facilitySlots.values) {
      final byId =
          normalizedSpotId.isNotEmpty && doc.facilityId.trim() == normalizedSpotId;
      final byName =
          normalizedName.isNotEmpty &&
          _normalize(doc.facilityName) == normalizedName;
      if (!byId && !byName) continue;
      options.addAll(
        doc.slots
            .map((slot) => _formatTime(slot))
            .where((label) => label.isNotEmpty),
      );
    }
    final sorted = options.toList()..sort();
    return sorted;
  }

  List<TodayRootItem> _collectRouteItems({required bool requireComplete}) {
    final items = <TodayRootItem>[];
    for (final draft in _routeDraftItems) {
      final spotId = draft.spotId.trim();
      final spotName = draft.spotName.trim();
      final timeRange = draft.timeRange.trim();
      if (!requireComplete &&
          spotId.isEmpty &&
          spotName.isEmpty &&
          timeRange.isEmpty &&
          draft.noteController.text.trim().isEmpty) {
        continue;
      }
      if (requireComplete &&
          (spotId.isEmpty || spotName.isEmpty || timeRange.isEmpty)) {
        continue;
      }
      items.add(
        TodayRootItem(
          spotId: spotId,
          spotName: spotName,
          timeRange: timeRange,
          note: draft.noteController.text.trim(),
        ),
      );
    }
    return items;
  }

  Future<void> _submitPost() async {
    if (_isSubmitting) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
      return;
    }
    final isRestricted = await UserAccessUtils.isCurrentUserRestricted();
    if (isRestricted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용금지된 회원입니다. 관리자에게 문의하세요.')),
      );
      return;
    }

    final content = _contentController.text.trim();
    final routeItems = _isRouteCategory
        ? _collectRouteItems(requireComplete: true)
        : const <TodayRootItem>[];

    if (_isRouteCategory && routeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘의 루트는 체험관과 시간대를 1개 이상 입력해 주세요.')),
      );
      return;
    }
    if (content.isEmpty && _selectedImages.isEmpty && routeItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용 또는 이미지를 추가해 주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final localImages = _selectedImages
          .map((xfile) => File(xfile.path))
          .toList();
      final created = _isEditMode
          ? await _postRepository.updatePost(
              postId: widget.editingPost!.postId,
              category: _selectedCategory,
              contentText: content,
              existingImageUrls: List<String>.from(_existingImageUrls),
              localImages: localImages,
              routeItems: routeItems,
            )
          : await _postRepository.createPost(
              category: _selectedCategory,
              contentText: content,
              localImages: localImages,
              routeItems: routeItems,
            );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(_isEditMode ? '게시글 수정 실패: $e' : '게시글 작성 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case '자유':
        return Icons.chat_bubble_outline_rounded;
      case '궁금해요':
        return Icons.help_outline_rounded;
      case '오늘의 루트':
        return Icons.route_rounded;
      case '꿀팁':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F1F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          _isEditMode ? '게시글 수정' : '새 게시물',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              _isEditMode ? '수정' : '게시',
              style: const TextStyle(
                color: Color(0xFFED9A3A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE6E8EE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFD9E2F0),
                      backgroundImage: _authorPhotoUrl.isNotEmpty
                          ? NetworkImage(_authorPhotoUrl)
                          : null,
                      child: _authorPhotoUrl.isEmpty
                          ? const Icon(
                              Icons.smart_toy_rounded,
                              color: Color(0xFF5C88A7),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _authorName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2533),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _openCategorySheet,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFED9A3A),
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcon(_selectedCategory),
                          color: const Color(0xFF5B616F),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: Color(0xFF404552),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more_rounded,
                          color: Color(0xFF737A89),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  minLines: 7,
                  maxLines: 12,
                  style: const TextStyle(
                    color: Color(0xFF2A2F3C),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  decoration: const InputDecoration(
                    hintText: '새로운 소식이 있나요?',
                    hintStyle: TextStyle(
                      color: Color(0xFF9BA2B0),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                if (_isRouteCategory) ...[
                  const Divider(height: 24, color: Color(0xFFE3E7EE)),
                  const Text(
                    '오늘의 루트',
                    style: TextStyle(
                      color: Color(0xFF1F2533),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._routeDraftItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final spotFloor = _spotFloorById(item.spotId);
                    final timeOptions = _resolveTimeOptions(
                      selectedSpotId: item.spotId,
                      selectedSpotName: item.spotName,
                    );

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '루트 ${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF343B4A),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              if (_routeDraftItems.length > 1)
                                IconButton(
                                  onPressed: () => _removeRouteItem(index),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: Color(0xFF8A91A1),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final selected = await _openSpotPicker(
                                selectedSpotId: item.spotId,
                              );
                              if (selected == null || !mounted) return;
                              setState(() {
                                item.spotId = selected.spotId;
                                item.spotName = selected.title;
                                final options = _resolveTimeOptions(
                                  selectedSpotId: item.spotId,
                                  selectedSpotName: item.spotName,
                                );
                                if (!options.contains(item.timeRange)) {
                                  item.timeRange = '';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE0E5EE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFF7B8497),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: item.spotName.trim().isEmpty
                                        ? const Text(
                                            '체험관 선택',
                                            style: TextStyle(
                                              color: Color(0xFF8F97A8),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.spotName,
                                                style: const TextStyle(
                                                  color: Color(0xFF1F2533),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              if (spotFloor.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  spotFloor,
                                                  style: const TextStyle(
                                                    color: Color(0xFF7A8294),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF7B8497),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              if (item.spotId.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('먼저 체험관을 선택해 주세요.'),
                                  ),
                                );
                                return;
                              }
                              if (timeOptions.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('선택 가능한 운영시간이 없습니다.'),
                                  ),
                                );
                                return;
                              }
                              final selectedTime = await _openTimePicker(
                                options: timeOptions,
                                selectedTime: item.timeRange,
                                spotName: item.spotName,
                              );
                              if (selectedTime == null || !mounted) return;
                              setState(() => item.timeRange = selectedTime);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE0E5EE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: Color(0xFF7B8497),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: item.timeRange.trim().isEmpty
                                        ? Text(
                                            item.spotId.trim().isEmpty
                                                ? '먼저 체험관을 선택해 주세요.'
                                                : (timeOptions.isEmpty
                                                      ? '선택 가능한 운영시간이 없습니다.'
                                                      : '운영시간(회차) 선택'),
                                            style: const TextStyle(
                                              color: Color(0xFF8F97A8),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : Text(
                                            item.timeRange,
                                            style: const TextStyle(
                                              color: Color(0xFF1F2533),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF7B8497),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.noteController,
                            maxLength: 30,
                            decoration: InputDecoration(
                              hintText: '메모 (선택)',
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: _addRouteItem,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCFD4DF)),
                    ),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      '루트 추가',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isPickingImages ? null : _pickImages,
                      icon: _isPickingImages
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                      label: Text(
                        '이미지 첨부 (${_selectedImages.length + _existingImageUrls.length}/$_maxImages)',
                      ),
                    ),
                  ],
                ),
                if (_existingImageUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingImageUrls.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final imageUrl = _existingImageUrls[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _existingImageUrls.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = File(_selectedImages[index].path);
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () => _removeImageAt(index),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                ],
              ),
            ),
          ),
          ),
          if (_isSubmitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFED9A3A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteDraftItem {
  _RouteDraftItem({
    required this.spotId,
    required this.spotName,
    required this.timeRange,
    required this.noteController,
  });

  factory _RouteDraftItem.empty() {
    return _RouteDraftItem(
      spotId: '',
      spotName: '',
      timeRange: '',
      noteController: TextEditingController(),
    );
  }

  String spotId;
  String spotName;
  String timeRange;
  final TextEditingController noteController;

  void dispose() {
    noteController.dispose();
  }
}
