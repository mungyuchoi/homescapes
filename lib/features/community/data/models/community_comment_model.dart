import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentAuthor {
  const CommunityCommentAuthor({
    required this.uid,
    required this.displayName,
    this.photoURL,
  });

  final String uid;
  final String displayName;
  final String? photoURL;

  factory CommunityCommentAuthor.fromMap(Map<String, dynamic> data) {
    return CommunityCommentAuthor(
      uid: (data['uid'] as String? ?? '').trim(),
      displayName: (data['displayName'] as String? ?? '').trim(),
      photoURL: (data['photoURL'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'displayName': displayName, 'photoURL': photoURL};
  }
}

class CommunityComment {
  const CommunityComment({
    required this.commentId,
    required this.postId,
    required this.author,
    required this.contentText,
    required this.contentHtml,
    this.imageUrls = const [],
    this.parentCommentId,
    this.depth = 0,
    this.likesCount = 0,
    this.reportsCount = 0,
    this.isDeleted = false,
    this.isHidden = false,
    this.createdAt,
    this.updatedAt,
  });

  final String commentId;
  final String postId;
  final CommunityCommentAuthor author;
  final String contentText;
  final String contentHtml;
  final List<String> imageUrls;
  final String? parentCommentId;
  final int depth;
  final int likesCount;
  final int reportsCount;
  final bool isDeleted;
  final bool isHidden;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CommunityComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final html = (data['contentHtml'] as String? ?? '').trim();
    final urls = (data['imageUrls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final extractedUrls = urls.isNotEmpty
        ? urls
        : _extractImageUrlsFromHtml(html);

    return CommunityComment(
      commentId: (data['commentId'] as String? ?? doc.id).trim(),
      postId: (data['postId'] as String? ?? '').trim(),
      author: CommunityCommentAuthor.fromMap(
        (data['author'] as Map<String, dynamic>? ?? const {}),
      ),
      contentText: (data['contentText'] as String? ?? '').trim(),
      contentHtml: html,
      imageUrls: extractedUrls,
      parentCommentId: (data['parentCommentId'] as String?)?.trim(),
      depth: (data['depth'] as int?) ?? 0,
      likesCount: (data['likesCount'] as int?) ?? 0,
      reportsCount: (data['reportsCount'] as int?) ?? 0,
      isDeleted: (data['isDeleted'] as bool?) ?? false,
      isHidden: (data['isHidden'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static List<String> _extractImageUrlsFromHtml(String html) {
    final regex = RegExp(
      '<img[^>]+src=["\\\']([^"\\\']+)["\\\'][^>]*>',
      caseSensitive: false,
    );
    return regex
        .allMatches(html)
        .map((match) => (match.group(1) ?? '').trim())
        .where((url) => url.isNotEmpty && !url.startsWith('file://'))
        .toList();
  }
}
