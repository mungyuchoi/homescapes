import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../utils/ad_utils.dart';
import '../widgets/app_banner_ad.dart';
import '../widgets/common_widgets.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.posts,
    required this.onLikeTap,
    required this.isLikedByMe,
    required this.likeCountByPostId,
    required this.onCategorySelected,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.onPostTap,
    required this.onAuthorTap,
    required this.onRouteItemTap,
  });

  final List<String> categories;
  final String selectedCategory;
  final List<CommunityPost> posts;
  final ValueChanged<CommunityPost> onLikeTap;
  final bool Function(String postId) isLikedByMe;
  final int Function(String postId, int fallback) likeCountByPostId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final ValueChanged<CommunityPost> onPostTap;
  final ValueChanged<CommunityPost> onAuthorTap;
  final ValueChanged<TodayRootItem> onRouteItemTap;

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
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AppTopHeader(
          title: '커뮤니티',
          onSearchTap: onSearchTap,
          onNotificationTap: onNotificationTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final selected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    side: BorderSide.none,
                    backgroundColor: isDark
                        ? const Color(0xFF2A313D)
                        : const Color(0xFFE5E6EA),
                    selectedColor: const Color(0xFFED9A3A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcon(category),
                          size: 16,
                          color: isDark
                              ? const Color(0xFF97A0B0)
                              : const Color(0xFF8A909D),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : (isDark
                                      ? const Color(0xFFDCE3F0)
                                      : const Color(0xFF44444F)),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (_) => onCategorySelected(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Column(
            children: [
              for (var index = 0; index < posts.length; index++) ...[
                PostCard(
                  post: posts[index],
                  showFollowButton: false,
                  onLike: () => onLikeTap(posts[index]),
                  isLiked: isLikedByMe(posts[index].postId),
                  onTap: () => onPostTap(posts[index]),
                  onAuthorTap: () => onAuthorTap(posts[index]),
                  onRouteItemTap: onRouteItemTap,
                  likeCountOverride: likeCountByPostId(
                    posts[index].postId,
                    posts[index].likes,
                  ),
                  imageUrls: posts[index].imageUrls,
                ),
                if ((posts.length == 1 && index == 0) || index == 1) ...[
                  const SizedBox(height: 10),
                  AppBannerAd(
                    adUnitId: AdUtils.communityFeedInlineBannerAdUnitId,
                    type: AppBannerAdType.inline,
                    margin: EdgeInsets.zero,
                    debugLabel: 'communityFeedInline',
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 170),
      ],
    );
  }
}
