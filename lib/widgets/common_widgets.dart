import 'package:flutter/material.dart';

import '../models/app_models.dart';

class AppTopHeader extends StatelessWidget {
  const AppTopHeader({
    super.key,
    required this.title,
    this.onTicketTap,
    this.onNotificationTap,
    this.onSearchTap,
  });

  final String title;
  final VoidCallback? onTicketTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: isDark ? const Color(0xFFF0F3F8) : const Color(0xFF181A21),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeaderActionButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationTap ?? () {},
              ),
              const SizedBox(width: 8),
              HeaderActionButton(
                icon: Icons.search_rounded,
                onTap: onSearchTap ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF252B36) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: isDark ? const Color(0xFFE8EDF7) : const Color(0xFF1C1C22),
          ),
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onFollow,
    this.showFollowButton = true,
    this.isFollowing = false,
    this.isLiked = false,
    this.onLike,
    this.onTap,
    this.onAuthorTap,
    this.onRouteItemTap,
    this.onImageTap,
    this.commentCountOverride,
    this.likeCountOverride,
    this.imageUrls = const [],
  });

  final CommunityPost post;
  final VoidCallback? onFollow;
  final bool showFollowButton;
  final bool isFollowing;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final ValueChanged<TodayRootItem>? onRouteItemTap;
  final ValueChanged<int>? onImageTap;
  final int? commentCountOverride;
  final int? likeCountOverride;
  final List<String> imageUrls;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardChild = Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C212A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x15000000),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onAuthorTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFD7EDFF),
                          backgroundImage:
                              (post.photoURL?.trim().isNotEmpty ?? false)
                              ? NetworkImage(post.photoURL!.trim())
                              : null,
                          child: (post.photoURL?.trim().isNotEmpty ?? false)
                              ? null
                              : const Icon(
                                  Icons.android,
                                  color: Color(0xFF5C88A7),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFECF1F9)
                                      : const Color(0xFF1C1F28),
                                ),
                              ),
                              Text(
                                post.timeAgo,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFAEB7C8)
                                      : const Color(0xFF7B7B86),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showFollowButton) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor: isFollowing
                        ? const Color(0xFFE1E6EE)
                        : const Color(0xFFED9A3A),
                    foregroundColor: isFollowing
                        ? const Color(0xFF646D7C)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: Text(isFollowing ? '팔로잉' : '팔로우'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A313D)
                      : const Color(0xFFF0F1F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(post.category),
                      size: 14,
                      color: const Color(0xFF8A909D),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      post.category,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFDCE3F0)
                            : const Color(0xFF4C4C56),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFECF1F9) : const Color(0xFF1C1F28),
            ),
          ),
          if (post.routeItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.routeItems.map((item) {
                final routeLabel =
                    '${item.spotName} ${item.timeRange}'.trim().isNotEmpty
                    ? '${item.spotName} ${item.timeRange}'.trim()
                    : '루트';
                final note = item.note.trim();
                final chip = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeLabel,
                        style: const TextStyle(
                          color: Color(0xFF4C6287),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFB8C8E6)
                                : const Color(0xFF6B7EA3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
                if (onRouteItemTap == null) return chip;
                return InkWell(
                  onTap: () => onRouteItemTap!(item),
                  borderRadius: BorderRadius.circular(8),
                  child: chip,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final imageUrl = imageUrls[index];
                  final image = ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      imageUrl,
                      width: 170,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 170,
                          height: 170,
                          color: isDark
                              ? const Color(0xFF2A313D)
                              : const Color(0xFFE5E6EA),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        );
                      },
                    ),
                  );
                  if (onImageTap == null) return image;
                  return GestureDetector(
                    onTap: () => onImageTap!(index),
                    child: image,
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: GestureDetector(
                  onTap: onLike,
                  behavior: HitTestBehavior.translucent,
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked
                        ? const Color(0xFFFF4E66)
                        : const Color(0xFF8D929D),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${likeCountOverride ?? post.likes}',
                style: const TextStyle(
                  color: Color(0xFF8D929D),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF8D929D),
              ),
              const SizedBox(width: 4),
              Text(
                '${commentCountOverride ?? post.comments}',
                style: const TextStyle(
                  color: Color(0xFF8D929D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return cardChild;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: cardChild,
      ),
    );
  }
}

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    (
      label: '커뮤니티',
      outlinedIcon: Icons.forum_outlined,
      filledIcon: Icons.forum_rounded,
    ),
    (
      label: '체험관',
      outlinedIcon: Icons.location_on_outlined,
      filledIcon: Icons.location_on,
    ),
    (
      label: '조이',
      outlinedIcon: Icons.shopping_bag_outlined,
      filledIcon: Icons.shopping_bag_rounded,
    ),
    (
      label: 'MY',
      outlinedIcon: Icons.person_outline_rounded,
      filledIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF202734).withValues(alpha: 0.88),
                  const Color(0xFF151A24).withValues(alpha: 0.82),
                ]
              : [
                  Colors.white.withValues(alpha: 0.90),
                  const Color(0xFFF5F8FE).withValues(alpha: 0.74),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.92),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x44000000) : const Color(0x25000000),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final selected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: isDark ? 0.16 : 0.98)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x55000000)
                                : const Color(0x12000000),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.filledIcon : item.outlinedIcon,
                      size: 22,
                      color: selected
                          ? (isDark
                                ? const Color(0xFFF2F5FB)
                                : const Color(0xFF15161A))
                          : (isDark
                                ? const Color(0xFF9BA3B3)
                                : const Color(0xFF8A8A94)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? (isDark
                                  ? const Color(0xFFF2F5FB)
                                  : const Color(0xFF15161A))
                            : (isDark
                                  ? const Color(0xFF9BA3B3)
                                  : const Color(0xFF8A8A94)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MyTopIcon extends StatelessWidget {
  const MyTopIcon({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
      splashRadius: 20,
    );
  }
}

class SpotInfoDot extends StatelessWidget {
  const SpotInfoDot({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFED9A3A),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF505560),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class LoginImageButton extends StatelessWidget {
  const LoginImageButton({
    super.key,
    required this.onTap,
    required this.assetPath,
    this.width = 280,
    this.height = 44,
    this.borderRadius = 8,
    this.imageFit = BoxFit.contain,
  });

  final VoidCallback? onTap;
  final String assetPath;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              assetPath,
              fit: imageFit,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE6E9EF),
                  alignment: Alignment.center,
                  child: Text(
                    assetPath.split('/').last,
                    style: const TextStyle(
                      color: Color(0xFF656B79),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class LegendBadge extends StatelessWidget {
  const LegendBadge({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF333344),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleStatCard extends StatelessWidget {
  const SimpleStatCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF666A77),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF232635),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1D2130),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF666A77),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
