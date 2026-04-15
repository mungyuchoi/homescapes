import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/ads/data/models/bottom_sheet_ad_model.dart';
import '../features/ads/data/repositories/bottom_sheet_ad_repository.dart';
import '../features/ads/utils/bottom_sheet_ad_storage.dart';

class BottomSheetAdManagementScreen extends StatefulWidget {
  const BottomSheetAdManagementScreen({super.key});

  @override
  State<BottomSheetAdManagementScreen> createState() =>
      _BottomSheetAdManagementScreenState();
}

class _BottomSheetAdManagementScreenState
    extends State<BottomSheetAdManagementScreen> {
  final BottomSheetAdRepository _repository = BottomSheetAdRepository();
  final ImagePicker _imagePicker = ImagePicker();

  List<BottomSheetAdModel> _ads = const [];
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
      ).showSnackBar(SnackBar(content: Text('광고 목록을 불러오지 못했습니다: $e')));
    }
  }

  Future<void> _showAddEditDialog({BottomSheetAdModel? ad}) async {
    final titleController = TextEditingController(text: ad?.title ?? '');
    final linkValueController = TextEditingController(
      text: ad?.linkValue ?? '',
    );
    final priorityController = TextEditingController(
      text: (ad?.priority ?? 0).toString(),
    );

    BottomSheetAdLinkType selectedLinkType =
        ad?.linkType ?? BottomSheetAdLinkType.web;
    DateTime? startDate = ad?.startAt;
    DateTime? endDate = ad?.endAt;
    bool isActive = ad?.isActive ?? true;
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
                (imageUrl?.trim().isNotEmpty ?? false) || selectedImage != null;
            final dialogContentWidth =
                (MediaQuery.of(dialogContext).size.width * 0.78)
                    .clamp(260.0, 420.0)
                    .toDouble();
            return AlertDialog(
              title: Text(ad == null ? '광고 추가' : '광고 수정'),
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
                      DropdownButtonFormField<BottomSheetAdLinkType>(
                        initialValue: selectedLinkType,
                        decoration: const InputDecoration(
                          labelText: '링크 타입',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: BottomSheetAdLinkType.web,
                            child: Text('웹 링크'),
                          ),
                          DropdownMenuItem(
                            value: BottomSheetAdLinkType.deeplink,
                            child: Text('딥링크'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedLinkType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: linkValueController,
                        decoration: InputDecoration(
                          labelText:
                              selectedLinkType == BottomSheetAdLinkType.web
                              ? '웹 URL'
                              : '딥링크 값',
                          border: const OutlineInputBorder(),
                          hintText:
                              selectedLinkType == BottomSheetAdLinkType.web
                              ? 'https://www.example.com'
                              : 'spot:SPOT_ID',
                        ),
                      ),
                      if (selectedLinkType ==
                          BottomSheetAdLinkType.deeplink) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.search),
                            label: const Text('가게 선택으로 딥링크 채우기'),
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
                          ),
                        ),
                        if (selectedSpot != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '선택: ${selectedSpot!.name} (${selectedSpot!.spotId})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF646D7F),
                              ),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('활성화'),
                          const Spacer(),
                          Switch(
                            value: isActive,
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    setDialogState(() => isActive = value);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasImage ? '이미지 선택됨' : '이미지를 선택해주세요',
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
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('이미지 선택'),
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
                          var linkValue = linkValueController.text.trim();
                          final priority =
                              int.tryParse(priorityController.text) ?? 0;
                          if (title.isEmpty) {
                            _showDialogSnackBar(dialogContext, '제목을 입력해주세요');
                            return;
                          }
                          if (linkValue.isEmpty) {
                            _showDialogSnackBar(dialogContext, '링크 값을 입력해주세요');
                            return;
                          }
                          if (selectedLinkType == BottomSheetAdLinkType.web &&
                              !linkValue.startsWith('http://') &&
                              !linkValue.startsWith('https://')) {
                            linkValue = 'https://$linkValue';
                          }
                          if (selectedLinkType ==
                              BottomSheetAdLinkType.deeplink) {
                            if (!linkValue.startsWith('spot:')) {
                              linkValue = 'spot:$linkValue';
                            }
                            final targetSpotId = linkValue.replaceFirst(
                              'spot:',
                              '',
                            );
                            if (targetSpotId.trim().isEmpty) {
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
                          final hasExistingImage =
                              imageUrl != null && imageUrl.trim().isNotEmpty;
                          if (!hasExistingImage && selectedImage == null) {
                            _showDialogSnackBar(dialogContext, '이미지를 선택해주세요');
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          Navigator.of(dialogContext).pop();
                          await _saveAd(
                            ad: ad,
                            title: title,
                            linkType: selectedLinkType,
                            linkValue: linkValue,
                            startDate: startDate!,
                            endDate: endDate!,
                            priority: priority,
                            isActive: isActive,
                            imageFile: selectedImage,
                            existingImageUrl: imageUrl?.trim(),
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
          String query = '';
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final normalizedQuery = query.trim().toLowerCase();
              final filtered = normalizedQuery.isEmpty
                  ? options
                  : options
                        .where(
                          (spot) =>
                              spot.name.toLowerCase().contains(
                                normalizedQuery,
                              ) ||
                              spot.spotId.toLowerCase().contains(
                                normalizedQuery,
                              ),
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
    final fallbackName = _asString(data['title']).isNotEmpty
        ? _asString(data['title'])
        : (_asString(data['name']).isNotEmpty
              ? _asString(data['name'])
              : (_asString(data['facilityName']).isNotEmpty
                    ? _asString(data['facilityName'])
                    : spotId));
    final imageUrl = _firstImage(data);
    return _SpotOption(spotId: spotId, name: fallbackName, imageUrl: imageUrl);
  }

  String _firstImage(Map<String, dynamic> data) {
    final direct = _asString(data['imageUrl']);
    if (direct.isNotEmpty) return direct;
    final list = data['imageUrls'];
    if (list is List) {
      for (final item in list) {
        final text = _asString(item);
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  String _asString(Object? value) => value is String ? value.trim() : '';

  Future<void> _saveAd({
    BottomSheetAdModel? ad,
    required String title,
    required BottomSheetAdLinkType linkType,
    required String linkValue,
    required DateTime startDate,
    required DateTime endDate,
    required int priority,
    required bool isActive,
    File? imageFile,
    String? existingImageUrl,
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
          'bottom_sheet_ads/$targetAdId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        finalImageUrl = await ref.getDownloadURL();
      }

      final now = DateTime.now();
      final model = BottomSheetAdModel(
        adId: ad?.adId ?? '',
        title: title,
        imageUrl: finalImageUrl,
        linkType: linkType,
        linkValue: linkValue,
        startAt: startDate,
        endAt: endDate,
        priority: priority,
        isActive: isActive,
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
        SnackBar(content: Text(ad == null ? '광고가 추가되었습니다' : '광고가 수정되었습니다')),
      );
      await _loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('광고 저장 실패: $e')));
    }
  }

  Future<void> _deleteAd(BottomSheetAdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 삭제'),
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
      ).showSnackBar(const SnackBar(content: Text('광고가 삭제되었습니다')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('광고 삭제 실패: $e')));
    }
  }

  Future<void> _toggleActive(BottomSheetAdModel ad) async {
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

  String _formatLinkType(BottomSheetAdLinkType type) {
    switch (type) {
      case BottomSheetAdLinkType.web:
        return 'web';
      case BottomSheetAdLinkType.deeplink:
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
          '광고 관리',
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
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('현재 계정의 광고 숨김 상태 초기화'),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('광고 숨김 상태 초기화'),
                            content: const Text(
                              '모든 광고의 "오늘 하루 보지 않기" 상태를 초기화하시겠습니까?',
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
                        await BottomSheetAdStorage.resetAllHiddenAds();
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('광고 숨김 상태가 초기화되었습니다')),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _ads.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 광고가 없습니다.',
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
                                            Icons.image_outlined,
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
                                    ad.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_formatLinkType(ad.linkType)} / ${ad.linkValue}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${_formatDate(ad.startAt)} ~ ${_formatDate(ad.endAt)}',
                                      ),
                                      Text('우선순위: ${ad.priority}'),
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
