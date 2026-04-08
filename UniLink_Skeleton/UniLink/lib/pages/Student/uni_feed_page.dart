import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/admin_bottom_nav_bar.dart';
import '../../widgets/custom_card.dart';

class UniFeedPage extends StatefulWidget {
  final bool isAdmin;
  const UniFeedPage({super.key, this.isAdmin = false});

  @override
  State<UniFeedPage> createState() => _UniFeedPageState();
}

class _UniFeedPageState extends State<UniFeedPage> {
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      final diff = DateTime.now().difference(timestamp.toDate());
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
      if (diff.inHours < 24) return "${diff.inHours} hours ago";
      return "${diff.inDays} days ago";
    }
    return timestamp.toString();
  }

  void _toggleLike(String docId, List currentLikes, String currentUserEmail) {
    if (currentLikes.contains(currentUserEmail)) {
      FirebaseFirestore.instance.collection('unifeed_posts').doc(docId).update({
        'likes': FieldValue.arrayRemove([currentUserEmail]),
      });
    } else {
      FirebaseFirestore.instance.collection('unifeed_posts').doc(docId).update({
        'likes': FieldValue.arrayUnion([currentUserEmail]),
      });
    }
  }

  void _deletePost(String docId) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('unifeed_posts')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: colors.destructive)),
          ),
        ],
      ),
    );
  }

  void _editPost(String docId, String currentContent) {
    final TextEditingController editController = TextEditingController(
      text: currentContent,
    );
    final colors = AppColors.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Post"),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "What's on your mind?",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('unifeed_posts')
                    .doc(docId)
                    .update({
                      'content': editController.text.trim(),
                      'status': 'pending',
                    });

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Post edited and sent for Admin Re-Approval! 🕒',
                    ),
                    backgroundColor: colors.campusAmber,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.primaryForeground,
            ),
            child: const Text("Save & Submit"),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(
    BuildContext context,
    String docId,
    String currentContent,
  ) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.edit2),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(docId, currentContent);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.trash2, color: colors.destructive),
                title: Text(
                  'Delete Post',
                  style: TextStyle(color: colors.destructive),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(docId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createNewPost() {
    final TextEditingController newPostController = TextEditingController();
    final colors = AppColors.of(context);
    String? localImagePath;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create Post"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPostController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: isUploading
                      ? null
                      : () async {
                          ImageSource? source = await showDialog<ImageSource>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Add Photo'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(LucideIcons.camera),
                                      title: const Text('Take a photo'),
                                      onTap: () => Navigator.pop(
                                        context,
                                        ImageSource.camera,
                                      ),
                                    ),
                                    ListTile(
                                      leading: const Icon(LucideIcons.image),
                                      title: const Text('Choose from gallery'),
                                      onTap: () => Navigator.pop(
                                        context,
                                        ImageSource.gallery,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );

                          if (source != null) {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: source,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              setDialogState(() => localImagePath = image.path);
                            }
                          }
                        },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: localImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(localImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.image,
                                color: colors.mutedForeground,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap to Add Photo",
                                style: TextStyle(color: colors.mutedForeground),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!isUploading)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (newPostController.text.trim().isNotEmpty ||
                          localImagePath != null) {
                        setDialogState(() => isUploading = true);

                        try {
                          String? downloadUrl;

                          if (localImagePath != null) {
                            final fileName =
                                'post_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
                            final ref = FirebaseStorage.instance.ref().child(
                              fileName,
                            );

                            await ref.putFile(File(localImagePath!));
                            downloadUrl = await ref.getDownloadURL();
                          }

                          final currentUser = FirebaseAuth.instance.currentUser;
                          await FirebaseFirestore.instance
                              .collection('unifeed_posts')
                              .add({
                                'type': 'post',
                                'authorName':
                                    currentUser?.email?.split('@')[0] ??
                                    "Student",
                                'authorEmail':
                                    currentUser?.email ?? 'student@unilink.com',
                                'content': newPostController.text.trim(),
                                'imageUrl': downloadUrl,
                                'status': 'pending',
                                'timestamp': FieldValue.serverTimestamp(),
                                'likes': [],
                                'commentsList': [],
                                'shares': 0,
                              });

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Post sent to Admin for approval! 🕒',
                              ),
                              backgroundColor: colors.campusAmber,
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            setDialogState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error uploading: $e'),
                                backgroundColor: colors.destructive,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.primaryForeground,
              ),
              child: isUploading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: colors.primaryForeground,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(
    BuildContext context,
    String docId,
    List currentComments,
  ) {
    final TextEditingController commentController = TextEditingController();
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "Comments",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                    ),
                  ),
                  const Divider(),

                  Expanded(
                    child: currentComments.isEmpty
                        ? Center(
                            child: Text(
                              "No comments yet. Be the first!",
                              style: TextStyle(color: colors.mutedForeground),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: currentComments.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: colors.primary
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        LucideIcons.user,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colors.muted.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Student",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: colors.foreground,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              currentComments[index],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colors.foreground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background,
                      border: Border(top: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: TextStyle(color: colors.foreground),
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: TextStyle(
                                color: colors.mutedForeground,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colors.muted.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(LucideIcons.send, color: colors.primary),
                          onPressed: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('unifeed_posts')
                                  .doc(docId)
                                  .update({
                                    'commentsList': FieldValue.arrayUnion([
                                      commentController.text.trim(),
                                    ]),
                                  });
                              setSheetState(() {
                                currentComments.add(
                                  commentController.text.trim(),
                                );
                              });
                              commentController.clear();
                            }
                          },
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.campusTeal.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: colors.background.withValues(alpha: 0.26),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.96),
                      colors.campusIndigo.withValues(alpha: 0.90),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryForeground.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.arrowLeft,
                          color: colors.primaryForeground,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UniFeed',
                            style: TextStyle(
                              color: colors.primaryForeground,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Campus community hub',
                            style: TextStyle(
                              color: colors.primaryForeground.withValues(
                                alpha: 0.78,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: colors.primaryForeground.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.user,
                          color: colors.primaryForeground,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UniFeedProfilePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryForeground.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.penTool,
                          color: colors.primaryForeground,
                          size: 20,
                        ),
                        onPressed: _createNewPost,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('unifeed_posts')
                      .where('status', isEqualTo: 'approved')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No posts yet. Be the first to post!",
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final doc = posts[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final docId = doc.id;
                        final isAnnouncement = data['type'] == "announcement";
                        final bool isMine =
                            data['authorEmail'] == currentUserEmail;
                        final List likesArray = data['likes'] ?? [];
                        final bool isLiked = likesArray.contains(
                          currentUserEmail,
                        );
                        final List commentsArray = data['commentsList'] ?? [];
                        final String content = data['content'] ?? "";
                        
                        // Support multiple image keys for better data resilience
                        final String? imageUrl = data['imageUrl'] ?? 
                                                 data['image'] ?? 
                                                 data['url'] ?? 
                                                 data['photoUrl'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomCard(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isAnnouncement
                                              ? colors.campusAmber.withValues(
                                                  alpha: 0.1,
                                                )
                                              : colors.muted,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isAnnouncement
                                              ? LucideIcons.megaphone
                                              : LucideIcons.user,
                                          color: isAnnouncement
                                              ? colors.campusAmber
                                              : colors.mutedForeground,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['authorName'] ?? "Unknown",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: colors.foreground,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(
                                                data['timestamp'],
                                              ),
                                              style: TextStyle(
                                                color: colors.mutedForeground,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMine)
                                        IconButton(
                                          icon: Icon(
                                            LucideIcons.moreHorizontal,
                                            color: colors.mutedForeground,
                                            size: 20,
                                          ),
                                          onPressed: () => _showPostOptions(
                                            context,
                                            docId,
                                            content,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (content.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      content,
                                      style: TextStyle(
                                        color: colors.foreground,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                if (imageUrl != null && imageUrl.toString().trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        imageUrl.toString(),
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: colors.muted.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: colors.muted.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(LucideIcons.imageOff, color: colors.mutedForeground),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Image failed to load",
                                                  style: TextStyle(color: colors.mutedForeground, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      _buildInteractionButton(
                                        isLiked
                                            ? LucideIcons.heart
                                            : LucideIcons.heart,
                                        "${likesArray.length}",
                                        isLiked
                                            ? colors.campusRose
                                            : colors.mutedForeground,
                                        () => _toggleLike(
                                          docId,
                                          likesArray,
                                          currentUserEmail,
                                        ),
                                        isLiked: isLiked,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildInteractionButton(
                                        LucideIcons.messageCircle,
                                        "${commentsArray.length}",
                                        colors.mutedForeground,
                                        () => _showCommentsBottomSheet(
                                          context,
                                          docId,
                                          List.from(commentsArray),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/unifeed'),
    );
  }

  Widget _buildInteractionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool isLiked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLiked ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UniFeedProfilePage extends StatelessWidget {
  const UniFeedProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "My Posts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('unifeed_posts')
            .where('authorEmail', isEqualTo: user?.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "You haven't posted anything yet.",
                style: TextStyle(color: colors.mutedForeground),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              return Card(
                color: colors.card,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    data['content'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.foreground),
                  ),
                  subtitle: Text(
                    "Status: ${status.toUpperCase()}",
                    style: TextStyle(
                      color: status == 'approved'
                          ? colors.campusEmerald
                          : colors.campusAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: colors.mutedForeground,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
