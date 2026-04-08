import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _ContactPalette {
  static const pageTop = Color(0xFFF9FBFF);
  static const pageBottom = Color(0xFFECEFF8);
  static const card = Color(0xFFFFFFFF);
  static const heading = Color(0xFF181E33);
  static const subHeading = Color(0xFF6C7894);
  static const softBorder = Color(0xFFE8EDF4);
  static const muted = Color(0xFFF4F7FC);
  static const accent = Color(0xFF6A4DFF);
  static const accentDeep = Color(0xFF4D2FC2);
}

class ContactAdminPage extends StatefulWidget {
  const ContactAdminPage({super.key});

  @override
  State<ContactAdminPage> createState() => _ContactAdminPageState();
}

class _ContactAdminPageState extends State<ContactAdminPage> {
  final TextEditingController _msgController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final chatRef = FirebaseFirestore.instance.collection('admin_chats').doc(_user.uid);
    final msgRef = chatRef.collection('messages').doc();

    batch.set(chatRef, {
      'studentUid': _user.uid,
      'studentName': _user.displayName ?? 'Student',
      'studentEmail': _user.email,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(msgRef, {
      'text': text,
      'senderId': _user.uid,
      'senderName': _user.displayName ?? 'Student',
      'timestamp': FieldValue.serverTimestamp(),
      'isUser': true,
    });

    try {
      await batch.commit();
      _msgController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ContactPalette.pageBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_ContactPalette.pageTop, _ContactPalette.pageBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _ContactPalette.muted,
                          shape: BoxShape.circle,
                          border: Border.all(color: _ContactPalette.softBorder),
                        ),
                        child: const Icon(
                          LucideIcons.arrowLeft,
                          size: 20,
                          color: _ContactPalette.accentDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Administrator',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _ContactPalette.heading,
                            ),
                          ),
                          Text(
                            'Send issues and requests directly',
                            style: TextStyle(
                              color: _ContactPalette.subHeading,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('admin_chats')
                      .doc(_user?.uid)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageSquare, size: 48, color: _ContactPalette.subHeading.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'Start a conversation with admin',
                              style: TextStyle(color: _ContactPalette.subHeading, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final isUser = data['isUser'] == true;
                        final timestamp = data['timestamp'] as Timestamp?;
                        final timeStr = timestamp != null
                            ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
                            : 'Just now';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? _ContactPalette.accent
                                  : _ContactPalette.card,
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isUser
                                    ? Radius.zero
                                    : const Radius.circular(16),
                                bottomLeft: isUser
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                              ),
                              border: isUser
                                  ? null
                                  : Border.all(color: _ContactPalette.softBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : _ContactPalette.heading,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white.withValues(alpha: 0.78)
                                        : _ContactPalette.subHeading,
                                    fontSize: 11,
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _ContactPalette.card,
                  border: Border(
                    top: BorderSide(color: _ContactPalette.softBorder),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: _ContactPalette.subHeading,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: _ContactPalette.muted,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: _ContactPalette.heading,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: _ContactPalette.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 20,
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
      ),
    );
  }
}
