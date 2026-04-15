import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/dialog_ads/data/models/dialog_ad_model.dart';
import '../features/dialog_ads/data/repositories/dialog_ad_repository.dart';
import '../features/dialog_ads/utils/dialog_ad_storage.dart';

class DialogAdManagementScreen extends StatefulWidget {
  const DialogAdManagementScreen({super.key});

  @override
  State<DialogAdManagementScreen> createState() =>
      _DialogAdManagementScreenState();
}

class _DialogAdManagementScreenState extends State<DialogAdManagementScreen> {
  final DialogAdRepository _repository = DialogAdRepository();
  final ImagePicker _imagePicker = ImagePicker();

  List<DialogAdModel> _ads = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final ads = await _repository.getAllAds();
      if (!mounted) return;
      setState(() {
        _ads = ads;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('다이얼로그 목록을 불러오지 못했습니다: $e')));
    }
  }

  Future<void> _showAddEditDialog({DialogAdModel? ad}) async {
    final titleController = TextEditingController(text: ad?.title ?? '');
    final messageController = TextEditingController(text: ad?.message ?? '');
    final linkValueController = TextEditingController(
      text: ad?.linkValue ?? '',
    );
    final ctaTextController = TextEditingController(
      text: ad?.ctaText ?? '자세히 보기',
    );
    final priorityController = TextEditingController(
      text: '${ad?.priority ?? 0}',
    );

    DialogAdLinkType selectedLinkType = ad?.linkType ?? DialogAdLinkType.none;
    DateTime? startDate = ad?.startAt;
    DateTime? endDate = ad?.endAt;
    bool isActive = ad?.isActive ?? true;
    bool showCloseButton = ad?.showCloseButton ?? true;
    bool allowHideToday = ad?.allowHideToday ?? true;
    File? selectedImage;
    String? imageUrl = ad?.imageUrl;
    bool isSaving = false;
    _SpotOption? selectedSpot;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasImage =
                selectedImage != null || (imageUrl?.trim().isNotEmpty ?? false);
            final dialogContentWidth =
                (MediaQuery.of(dialogContext).size.width * 0.78)
                    .clamp(260.0, 420.0)
                    .toDouble();

            return AlertDialog(
              title: Text(ad == null ? '다이얼로그 추가' : '다이얼로그 수정'),
              content: SizedBox(
                width: dialogContentWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '제목',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '본문',
                          hintText: '텍스트만으로 안내하려면 여기에 내용을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<DialogAdLinkType>(
                        initialValue: selectedLinkType,
                        decoration: const InputDecoration(
                          labelText: '링크 타입',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DialogAdLinkType.none,
                            child: Text('링크 없음'),
                          ),
                          DropdownMenuItem(
                            value: DialogAdLinkType.web,
                            child: Text('웹 링크'),
                          ),
                          DropdownMenuItem(
                            value: DialogAdLinkType.deeplink,
                            child: Text('딥링크'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedLinkType = value);
                        },
                      ),
                      if (selectedLinkType != DialogAdLinkType.none) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: linkValueController,
                          decoration: InputDecoration(
                            labelText: selectedLinkType == DialogAdLinkType.web
                                ? '웹 URL'
                                : '딥링크 값',
                            hintText: selectedLinkType == DialogAdLinkType.web
                                ? 'https://www.example.com'
                                : 'spot:SPOT_ID',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (selectedLinkType == DialogAdLinkType.deeplink) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final pickedSpot = await _pickSpot();
                                      if (pickedSpot == null) return;
                                      setDialogState(() {
                                        selectedSpot = pickedSpot;
                                        linkValueController.text =
                                            'spot:${pickedSpot.spotId}';
                                      });
                                    },
                              icon: const Icon(Icons.search),
                              label: const Text('가게 선택으로 딥링크 채우기'),
                            ),
                          ),
                          if (selectedSpot != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '선택: ${selectedSpot!.name} (${selectedSpot!.spotId})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF687286),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: ctaTextController,
                          decoration: const InputDecoration(
                            labelText: 'CTA 버튼 텍스트',
                            hintText: '예: 자세히 보기',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                startDate == null
                                    ? '시작일 선택'
                                    : _formatDate(startDate!),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            startDate ?? DateTime.now(),
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 3650),
                                        ),
                                      );
                                      if (picked == null) return;
                                      setDialogState(() {
                                        startDate = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                        );
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                endDate == null
                                    ? '종료일 선택'
                                    : _formatDate(endDate!),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: endDate ?? DateTime.now(),
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 3650),
                                        ),
                                      );
                                      if (picked == null) return;
                                      setDialogState(() {
                                        endDate = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          23,
                                          59,
                                          59,
                                        );
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priorityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '우선순위 (작을수록 먼저 노출)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('활성화'),
                        value: isActive,
                        onChanged: isSaving
                            ? null
                            : (value) => setDialogState(() => isActive = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('닫기 버튼 표시'),
                        value: showCloseButton,
                        onChanged: isSaving
                            ? null
                            : (value) =>
                                  setDialogState(() => showCloseButton = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('"오늘 하루 보지 않기" 표시'),
                        value: allowHideToday,
                        onChanged: isSaving
                            ? null
                            : (value) =>
                                  setDialogState(() => allowHideToday = value),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasImage ? '이미지 선택됨' : '이미지는 선택사항입니다 (텍스트만 가능)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedImage != null)
                        SizedBox(
                          height: 110,
                          child: Image.file(selectedImage!, fit: BoxFit.cover),
                        )
                      else if (imageUrl != null && imageUrl.trim().isNotEmpty)
                        SizedBox(
                          height: 110,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF0F1F5),
                                alignment: Alignment.center,
                                child: const Text('이미지를 불러올 수 없습니다'),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1440,
                                    maxHeight: 1440,
                                    imageQuality: 90,
                                  );
                                  if (picked == null) return;
                                  if (!dialogContext.mounted) return;
                                  setDialogState(() {
                                    selectedImage = File(picked.path);
                                  });
                                },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('이미지 선택'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final message = messageController.text.trim();
                          var linkValue = linkValueController.text.trim();
                          final ctaText = ctaTextController.text.trim().isEmpty
                              ? '자세히 보기'
                              : ctaTextController.text.trim();
                          final priority =
                              int.tryParse(priorityController.text.trim()) ?? 0;
                          final hasImage =
                              selectedImage != null ||
                              (imageUrl?.trim().isNotEmpty ?? false);
                          if (title.isEmpty && message.isEmpty && !hasImage) {
                            _showDialogSnackBar(
                              dialogContext,
                              '제목/본문/이미지 중 하나는 입력해주세요',
                            );
                            return;
                          }
                          if (selectedLinkType != DialogAdLinkType.none &&
                              linkValue.isEmpty) {
                            _showDialogSnackBar(dialogContext, '링크 값을 입력해주세요');
                            return;
                          }
                          if (selectedLinkType == DialogAdLinkType.web &&
                              linkValue.isNotEmpty) {
                            if (!linkValue.startsWith('http://') &&
                                !linkValue.startsWith('https://')) {
                              linkValue = 'https://$linkValue';
                            }
                          }
                          if (selectedLinkType == DialogAdLinkType.deeplink &&
                              linkValue.isNotEmpty) {
                            if (!linkValue.startsWith('spot:')) {
                              linkValue = 'spot:$linkValue';
                            }
                            final targetSpotId = linkValue
                                .replaceFirst('spot:', '')
                                .trim();
                            if (targetSpotId.isEmpty) {
                              _showDialogSnackBar(
                                dialogContext,
                                '딥링크 값을 확인해주세요',
                              );
                              return;
                            }
                          }
                          if (startDate == null || endDate == null) {
                            _showDialogSnackBar(
                              dialogContext,
                              '시작일과 종료일을 선택해주세요',
                            );
                            return;
                          }
                          if (startDate!.isAfter(endDate!)) {
                            _showDialogSnackBar(
                              dialogContext,
                              '시작일은 종료일보다 앞서야 합니다',
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          Navigator.of(dialogContext).pop();
                          await _saveAd(
                            ad: ad,
                            title: title,
                            message: message,
                            imageFile: selectedImage,
                            existingImageUrl: imageUrl?.trim(),
                            linkType: selectedLinkType,
                            linkValue: linkValue,
                            ctaText: ctaText,
                            startDate: startDate!,
                            endDate: endDate!,
                            priority: priority,
                            isActive: isActive,
                            showCloseButton: showCloseButton,
                            allowHideToday: allowHideToday,
                          );
                        },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDialogSnackBar(BuildContext dialogContext, String message) {
    ScaffoldMessenger.of(
      dialogContext,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_SpotOption?> _pickSpot() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('spots')
          .limit(400)
          .get();
      final options = snapshot.docs.map(_spotFromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return null;

      return showDialog<_SpotOption>(
        context: context,
        builder: (dialogContext) {
          var query = '';
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final normalized = query.trim().toLowerCase();
              final filtered = normalized.isEmpty
                  ? options
                  : options
                        .where(
                          (spot) =>
                              spot.name.toLowerCase().contains(normalized) ||
                              spot.spotId.toLowerCase().contains(normalized),
                        )
                        .toList();

              return AlertDialog(
                title: const Text('가게 선택'),
                content: SizedBox(
                  width: 420,
                  height: 420,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: '이름 또는 ID 검색',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setDialogState(() => query = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('검색 결과가 없습니다.'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final spot = filtered[index];
                                  return ListTile(
                                    dense: true,
                                    leading: spot.imageUrl.isEmpty
                                        ? const CircleAvatar(
                                            child: Icon(
                                              Icons.store_mall_directory,
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              spot.imageUrl,
                                            ),
                                          ),
                                    title: Text(spot.name),
                                    subtitle: Text(spot.spotId),
                                    onTap: () =>
                                        Navigator.of(dialogContext).pop(spot),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('가게 목록을 불러오지 못했습니다: $e')));
      }
      return null;
    }
  }

  _SpotOption _spotFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final spotId = _asString(data['spotId']).isNotEmpty
        ? _asString(data['spotId'])
        : doc.id;
    final name = _asString(data['title']).isNotEmpty
        ? _asString(data['title'])
        : (_asString(data['name']).isNotEmpty
              ? _asString(data['name'])
              : spotId);
    final imageUrl = _firstImage(data);
    return _SpotOption(spotId: spotId, name: name, imageUrl: imageUrl);
  }

  String _asString(Object? value) => value is String ? value.trim() : '';

  String _firstImage(Map<String, dynamic> data) {
    final direct = _asString(data['imageUrl']);
    if (direct.isNotEmpty) return direct;
    final imageUrls = data['imageUrls'];
    if (imageUrls is List) {
      for (final entry in imageUrls) {
        final url = _asString(entry);
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  Future<void> _saveAd({
    DialogAdModel? ad,
    required String title,
    required String message,
    required File? imageFile,
    required String? existingImageUrl,
    required DialogAdLinkType linkType,
    required String linkValue,
    required String ctaText,
    required DateTime startDate,
    required DateTime endDate,
    required int priority,
    required bool isActive,
    required bool showCloseButton,
    required bool allowHideToday,
  }) async {
    try {
      var finalImageUrl = existingImageUrl ?? '';
      if (imageFile != null) {
        if (existingImageUrl != null &&
            existingImageUrl.isNotEmpty &&
            existingImageUrl.contains('firebasestorage')) {
          try {
            await FirebaseStorage.instance
                .refFromURL(existingImageUrl)
                .delete();
          } catch (_) {}
        }
        final targetAdId = ad?.adId.isNotEmpty == true
            ? ad!.adId
            : DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child(
          'dialog_ads/$targetAdId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        finalImageUrl = await ref.getDownloadURL();
      }

      final now = DateTime.now();
      final model = DialogAdModel(
        adId: ad?.adId ?? '',
        title: title,
        message: message,
        imageUrl: finalImageUrl,
        linkType: linkType,
        linkValue: linkValue,
        ctaText: ctaText,
        startAt: startDate,
        endAt: endDate,
        priority: priority,
        isActive: isActive,
        showCloseButton: showCloseButton,
        allowHideToday: allowHideToday,
        createdAt: ad?.createdAt ?? now,
        updatedAt: now,
      );
      if (ad == null) {
        await _repository.createAd(model);
      } else {
        await _repository.updateAd(ad.adId, model);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ad == null ? '다이얼로그가 추가되었습니다' : '다이얼로그가 수정되었습니다'),
        ),
      );
      await _loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  Future<void> _deleteAd(DialogAdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다이얼로그 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (ad.imageUrl.trim().isNotEmpty &&
          ad.imageUrl.contains('firebasestorage')) {
        try {
          await FirebaseStorage.instance.refFromURL(ad.imageUrl).delete();
        } catch (_) {}
      }
      await _repository.deleteAd(ad.adId);
      await _loadAds();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('다이얼로그가 삭제되었습니다')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  Future<void> _toggleActive(DialogAdModel ad) async {
    try {
      await _repository.toggleAdActive(ad.adId, !ad.isActive);
      await _loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('상태 변경 실패: $e')));
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${date.year}.${_twoDigits(date.month)}.${_twoDigits(date.day)}';
  }

  String _formatLinkType(DialogAdLinkType type) {
    switch (type) {
      case DialogAdLinkType.none:
        return 'none';
      case DialogAdLinkType.web:
        return 'web';
      case DialogAdLinkType.deeplink:
        return 'deeplink';
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          '앱 시작 팝업 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _loadAds,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            )
          : RefreshIndicator(
              onRefresh: _loadAds,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('팝업 숨김 상태 초기화'),
                            content: const Text(
                              '모든 팝업의 "오늘 하루 보지 않기" 상태를 초기화하시겠습니까?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('초기화'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        await DialogAdStorage.resetAllHiddenAds();
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('팝업 숨김 상태가 초기화되었습니다')),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('현재 계정의 팝업 숨김 상태 초기화'),
                    ),
                  ),
                  Expanded(
                    child: _ads.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 팝업이 없습니다.',
                              style: TextStyle(
                                color: Color(0xFF6E7482),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _ads.length,
                            itemBuilder: (context, index) {
                              final ad = _ads[index];
                              final title = ad.title.trim().isEmpty
                                  ? '(제목 없음)'
                                  : ad.title;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    10,
                                    8,
                                  ),
                                  leading: ad.imageUrl.trim().isEmpty
                                      ? Container(
                                          width: 62,
                                          height: 62,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F3F8),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.message_outlined,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            ad.imageUrl,
                                            width: 62,
                                            height: 62,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 62,
                                                    height: 62,
                                                    color: const Color(
                                                      0xFFF1F3F8,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                  title: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (ad.message.trim().isNotEmpty)
                                        Text(
                                          ad.message,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        '${_formatLinkType(ad.linkType)} / ${ad.linkValue}',
                                      ),
                                      Text(
                                        '${_formatDate(ad.startAt)} ~ ${_formatDate(ad.endAt)}',
                                      ),
                                      Text(
                                        '우선순위: ${ad.priority} / 닫기:${ad.showCloseButton ? 'ON' : 'OFF'} / 하루숨김:${ad.allowHideToday ? 'ON' : 'OFF'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  trailing: SizedBox(
                                    width: 92,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Switch(
                                          value: ad.isActive,
                                          onChanged: (_) => _toggleActive(ad),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showAddEditDialog(ad: ad);
                                            } else if (value == 'delete') {
                                              _deleteAd(ad);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('수정'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                '삭제',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFFED9A3A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SpotOption {
  const _SpotOption({
    required this.spotId,
    required this.name,
    required this.imageUrl,
  });

  final String spotId;
  final String name;
  final String imageUrl;
}
