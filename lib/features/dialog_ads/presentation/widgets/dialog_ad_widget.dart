import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/dialog_ad_model.dart';

class DialogAdResult {
  const DialogAdResult._({required this.hideToday, required this.openLink});

  const DialogAdResult.close() : this._(hideToday: false, openLink: false);

  const DialogAdResult.hideToday() : this._(hideToday: true, openLink: false);

  const DialogAdResult.openLink() : this._(hideToday: false, openLink: true);

  final bool hideToday;
  final bool openLink;
}

class DialogAdWidget extends StatelessWidget {
  const DialogAdWidget({super.key, required this.ad});

  final DialogAdModel ad;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(screenSize.width - 40, 420.0);
    final imageHeight = (dialogWidth * 1.65).clamp(
      320.0,
      screenSize.height * 0.72,
    );
    final hasPrimaryAction =
        ad.linkType != DialogAdLinkType.none && ad.linkValue.trim().isNotEmpty;
    final hasImage = ad.imageUrl.trim().isNotEmpty;
    final hasTitle = ad.title.trim().isNotEmpty;
    final hasMessage = ad.message.trim().isNotEmpty;
    final closeVisible = ad.showCloseButton || !ad.allowHideToday;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasImage)
                SizedBox(
                  height: imageHeight,
                  child: Image.network(
                    ad.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF2F4F8),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 42,
                        ),
                      );
                    },
                  ),
                ),
              if (hasTitle || hasMessage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTitle)
                        Text(
                          ad.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF161A24),
                          ),
                        ),
                      if (hasTitle && hasMessage) const SizedBox(height: 10),
                      if (hasMessage)
                        Text(
                          ad.message,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF454D61),
                          ),
                        ),
                    ],
                  ),
                ),
              if (hasPrimaryAction)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const DialogAdResult.openLink()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED9A3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(
                      ad.ctaText.trim().isEmpty ? '자세히 보기' : ad.ctaText,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                child: Row(
                  children: [
                    if (closeVisible)
                      IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const DialogAdResult.close()),
                        icon: const Icon(Icons.close, color: Color(0xFF2E3342)),
                      )
                    else
                      const SizedBox(width: 46),
                    const Spacer(),
                    if (ad.allowHideToday)
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const DialogAdResult.hideToday()),
                        child: const Text('오늘 하루 보지 않기'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
