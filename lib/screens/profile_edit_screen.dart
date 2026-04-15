import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const List<String> _presetPhotoUrls = [
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fblue_icon.png?alt=media&token=75bb29df-3779-4e07-8352-600911555f2f',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fgreen_icon.png?alt=media&token=e15b38e6-931e-4a5f-b165-d6a4cfa3be5f',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fnavy_icon.png?alt=media&token=2082a62e-a2a4-4692-a9d1-f72236f72169',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Forange_icon.png?alt=media&token=2157e85e-c5e9-483c-b88f-45fd056ca91d',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fpurple_icon.png?alt=media&token=2aa260ef-7d66-40a4-baf7-9bea7156f90b',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fred_icon.png?alt=media&token=c3cb763c-0004-4591-a3e5-afd8ec05f0c8',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fyellow_icon.png?alt=media&token=bec70c50-efbc-4171-9205-5269f14370de',
  ];

  final TextEditingController _profileIdController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _loadError;
  String? _selectedPhotoUrl;

  bool get _isCustomPhotoSelected =>
      _selectedPhotoUrl != null &&
      !_presetPhotoUrls.contains(_selectedPhotoUrl);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _profileIdController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _loadError = '로그인이 필요합니다.';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      final firestoreName = _asString(data?['displayName']);
      final firestoreBio = _asString(data?['bio']);
      final firestorePhoto = _asString(data?['photoURL']);
      final authName = (user.displayName ?? '').trim();
      final authPhoto = (user.photoURL ?? '').trim();

      final resolvedName = firestoreName.isNotEmpty
          ? firestoreName
          : (authName.isNotEmpty ? authName : '');
      final resolvedPhoto = firestorePhoto.isNotEmpty
          ? firestorePhoto
          : (authPhoto.isNotEmpty ? authPhoto : _presetPhotoUrls.first);

      if (!mounted) return;
      setState(() {
        _profileIdController.text = resolvedName;
        _bioController.text = firestoreBio;
        _selectedPhotoUrl = resolvedPhoto;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '프로필을 불러오지 못했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isPickingImage || _isSaving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 88,
      );
      if (file == null) return;

      if (!mounted) return;
      setState(() => _isPickingImage = true);

      final bytes = await file.readAsBytes();
      final now = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/${user.uid}/profile/profile_$now.jpg',
      );
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      if (!mounted) return;
      setState(() => _selectedPhotoUrl = downloadUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택/업로드 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || _isLoading) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final profileId = _profileIdController.text.trim();
    if (profileId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 아이디를 입력해 주세요.')));
      return;
    }

    final photoUrl = (_selectedPhotoUrl ?? '').trim().isNotEmpty
        ? (_selectedPhotoUrl ?? '').trim()
        : _presetPhotoUrls.first;
    final bio = _bioController.text.trim();

    setState(() => _isSaving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': profileId,
        'profileId': profileId,
        'bio': bio,
        'photoURL': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _trySyncAuthProfile(
        user: user,
        displayName: profileId,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 저장 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _trySyncAuthProfile({
    required User user,
    required String displayName,
    required String photoUrl,
  }) async {
    try {
      if ((user.displayName ?? '').trim() != displayName) {
        await user.updateDisplayName(displayName);
      }
    } catch (e) {
      if (!_isPigeonCastError(e)) {
        debugPrint('[PROFILE_EDIT] updateDisplayName failed: $e');
      }
    }

    try {
      if ((user.photoURL ?? '').trim() != photoUrl) {
        await user.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      if (!_isPigeonCastError(e)) {
        debugPrint('[PROFILE_EDIT] updatePhotoURL failed: $e');
      }
    }

    try {
      await user.reload();
    } catch (e) {
      if (!_isPigeonCastError(e)) {
        debugPrint('[PROFILE_EDIT] user.reload failed: $e');
      }
    }
  }

  bool _isPigeonCastError(Object error) {
    final message = error.toString();
    return message.contains('PigeonUserInfo') &&
        message.contains('List<Object?>');
  }

  String _asString(Object? value) {
    if (value is String) return value.trim();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = (_selectedPhotoUrl ?? '').trim();
    final topName = _profileIdController.text.trim().isNotEmpty
        ? _profileIdController.text.trim()
        : '프로필 이름';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F1F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          '프로필 편집',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      color: Color(0xFFED9A3A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6E7482),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 340,
                    color: const Color(0xFF8EA7C4),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 270,
                            height: 270,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.28),
                                  Colors.white.withValues(alpha: 0.10),
                                ],
                              ),
                            ),
                            child: Center(
                              child: _ProfileImageAvatar(
                                photoUrl: selectedPhoto,
                                size: 150,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7E8795,
                              ).withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                _ProfileImageAvatar(
                                  photoUrl: selectedPhoto,
                                  size: 58,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    topName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '프로필 아이디',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20232D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _profileIdController,
                          maxLength: 30,
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFE7EBF0),
                            hintText: '프로필 아이디를 입력하세요',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '소개',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20232D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _bioController,
                          maxLength: 30,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE7EBF0),
                            hintText: '한 줄 소개를 입력하세요',
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '프로필 이미지',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20232D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _PhotoChoiceTile(
                              selected: _isCustomPhotoSelected,
                              onTap: _pickImageFromGallery,
                              child: _isPickingImage
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF7F8795),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Color(0xFFA4ABB8),
                                      size: 30,
                                    ),
                            ),
                            ..._presetPhotoUrls.map(
                              (url) => _PhotoChoiceTile(
                                selected: selectedPhoto == url,
                                onTap: () =>
                                    setState(() => _selectedPhotoUrl = url),
                                child: ClipOval(
                                  child: Image.network(
                                    url,
                                    width: 74,
                                    height: 74,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PhotoChoiceTile extends StatelessWidget {
  const _PhotoChoiceTile({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 82,
        height: 82,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFFED9A3A) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFDAE0E8),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ProfileImageAvatar extends StatelessWidget {
  const _ProfileImageAvatar({required this.photoUrl, required this.size});

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFCFD6E0),
      ),
      child: ClipOval(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    if (photoUrl.startsWith('assets/')) {
      return Image.asset(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const Icon(
      Icons.smart_toy_rounded,
      color: Color(0xFF9AA3B2),
      size: 34,
    );
  }
}
