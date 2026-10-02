import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'package:valerion/core/providers/arc_provider.dart';
import 'package:valerion/core/domain/entities/user_entity.dart';
import 'package:valerion/features/home/models/arc_data.dart';

class TransmissionCommentsSheet extends ConsumerStatefulWidget {
  const TransmissionCommentsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransmissionCommentsSheet(),
    );
  }

  @override
  ConsumerState<TransmissionCommentsSheet> createState() => _TransmissionCommentsSheetState();
}

class _TransmissionCommentsSheetState extends ConsumerState<TransmissionCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;
  String? _replyingToCommentId;
  String? _replyingToPseudo;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(UserEntity user, String transmissionId, Map<String, dynamic> commentSession) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final comments = List<dynamic>.from(commentSession['comments'] ?? []);
      
      final newEntry = {
        'id': 'comm_${DateTime.now().millisecondsSinceEpoch}',
        'athleteId': user.id,
        'athletePseudo': user.username,
        'athleteAvatar': user.profileImageUrl ?? '',
        'athleteClan': user.clanIds.isNotEmpty ? user.clanIds.first : 'Sans Clan',
        'athleteLevel': 'Alpha',
        'content': text,
        'createdAt': 'À l\'instant',
        'likesCount': 0,
        'isPinned': false,
        'status': 'VISIBLE',
        'replies': [],
      };

      if (_replyingToCommentId != null) {
        // Find the comment and add reply
        final index = comments.indexWhere((c) => c['id'] == _replyingToCommentId);
        if (index != -1) {
          final targetComment = Map<String, dynamic>.from(comments[index]);
          final replies = List<dynamic>.from(targetComment['replies'] ?? []);
          replies.add(newEntry);
          targetComment['replies'] = replies;
          comments[index] = targetComment;
        }
        _replyingToCommentId = null;
        _replyingToPseudo = null;
      } else {
        comments.insert(0, newEntry);
      }

      await _firestore.collection('daily_transmissions').doc(transmissionId).update({
        'commentSession.comments': comments,
        'commentSession.totalComments': (commentSession['totalComments'] ?? 0) + 1,
      });

      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint("Erreur lors de l'envoi du commentaire : $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startReply(String commentId, String pseudo) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToPseudo = pseudo;
    });
    FocusScope.of(context).requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToPseudo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final userState = ref.watch(authStateProvider);
    final user = userState.valueOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: arc.arcType == AlphaArc.summer ? Colors.white : const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: arc.arcType == AlphaArc.summer ? Colors.black12 : Colors.white10),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: arc.arcType == AlphaArc.summer ? Colors.black12 : Colors.white10)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.forum_rounded, color: arc.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "DISCUSSIONS DE TRANSMISSION",
                        style: TextStyle(
                          color: arc.arcType == AlphaArc.summer ? Colors.black87 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: arc.arcType == AlphaArc.summer ? Colors.black54 : Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Comments Stream
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('daily_transmissions')
                      .where('status', isEqualTo: 'ACTIVE')
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Aucune transmission active trouvée.",
                          style: TextStyle(color: arc.arcType == AlphaArc.summer ? Colors.black54 : Colors.white54),
                        ),
                      );
                    }

                    final doc = snapshot.data!.docs.first;
                    final data = doc.data() as Map<String, dynamic>;
                    final commentSession = data['commentSession'] as Map<String, dynamic>?;

                    if (commentSession == null || commentSession['isOpen'] != true) {
                      return Center(
                        child: Text(
                          "Les commentaires sont fermés pour cette vidéo.",
                          style: TextStyle(color: arc.arcType == AlphaArc.summer ? Colors.black54 : Colors.white54),
                        ),
                      );
                    }

                    final prompt = commentSession['prompt'] as String?;
                    final comments = List<dynamic>.from(commentSession['comments'] ?? []);

                    return Column(
                      children: [
                        if (prompt != null && prompt.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: arc.primaryColor.withValues(alpha: 0.1),
                            child: Row(
                              children: [
                                Icon(Icons.psychology, color: arc.primaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    prompt,
                                    style: TextStyle(
                                      color: arc.arcType == AlphaArc.summer ? Colors.black87 : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: comments.isEmpty
                              ? Center(
                                  child: Text(
                                    "Soyez le premier à commenter !",
                                    style: TextStyle(color: arc.arcType == AlphaArc.summer ? Colors.black54 : Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = comments[index] as Map<String, dynamic>;
                                    return _buildCommentItem(comment, arc);
                                  },
                                ),
                        ),
                        
                        // Input Area
                        if (user != null)
                          Container(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                              left: 20,
                              right: 20,
                              top: 16,
                            ),
                            decoration: BoxDecoration(
                              color: arc.arcType == AlphaArc.summer ? Colors.grey.shade50 : const Color(0xFF1E293B),
                              border: Border(top: BorderSide(color: arc.arcType == AlphaArc.summer ? Colors.black12 : Colors.white10)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_replyingToPseudo != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "En réponse à $_replyingToPseudo",
                                          style: TextStyle(color: arc.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: _cancelReply,
                                          child: Icon(Icons.close, color: arc.primaryColor, size: 16),
                                        )
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _commentController,
                                        style: TextStyle(color: arc.arcType == AlphaArc.summer ? Colors.black87 : Colors.white),
                                        decoration: InputDecoration(
                                          hintText: _replyingToPseudo != null ? "Votre réponse..." : "Rédigez votre rapport...",
                                          hintStyle: TextStyle(color: arc.arcType == AlphaArc.summer ? Colors.black38 : Colors.white38),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: arc.arcType == AlphaArc.summer ? Colors.white : const Color(0xFF0F172A),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _isSubmitting
                                        ? const CircularProgressIndicator()
                                        : IconButton(
                                            icon: Icon(Icons.send_rounded, color: arc.primaryColor),
                                            onPressed: () => _submitComment(user, doc.id, commentSession),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, ArcData arc) {
    final bool isSummer = arc.arcType == AlphaArc.summer;
    final bool isPinned = comment['isPinned'] == true;
    final adminReply = comment['adminReply'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: (comment['athleteAvatar'] != null && comment['athleteAvatar'].toString().isNotEmpty)
                ? NetworkImage(comment['athleteAvatar'])
                : null,
            backgroundColor: arc.primaryColor.withValues(alpha: 0.2),
            child: (comment['athleteAvatar'] == null || comment['athleteAvatar'].toString().isEmpty)
                ? Icon(Icons.person, color: arc.primaryColor, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['athletePseudo'] ?? 'Alpha',
                      style: TextStyle(
                        color: isSummer ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment['createdAt'] ?? '',
                      style: TextStyle(
                        color: isSummer ? Colors.black45 : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    if (isPinned) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.push_pin, color: arc.primaryColor, size: 12),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['content'] ?? '',
                  style: TextStyle(
                    color: isSummer ? Colors.black87 : Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                // Actions (Reply)
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _startReply(comment['id'], comment['athletePseudo'] ?? 'Athlète'),
                  child: Text(
                    "Répondre",
                    style: TextStyle(
                      color: isSummer ? Colors.black54 : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Admin Reply
                if (adminReply != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.amber, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              adminReply['authorName'] ?? 'Admin',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminReply['content'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // User Replies
                if (comment['replies'] != null && (comment['replies'] as List).isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: arc.primaryColor.withValues(alpha: 0.3), width: 2)),
                    ),
                    child: Column(
                      children: (comment['replies'] as List).map<Widget>((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: (reply['athleteAvatar'] != null && reply['athleteAvatar'].toString().isNotEmpty)
                                    ? NetworkImage(reply['athleteAvatar'])
                                    : null,
                                backgroundColor: arc.primaryColor.withValues(alpha: 0.2),
                                child: (reply['athleteAvatar'] == null || reply['athleteAvatar'].toString().isEmpty)
                                    ? Icon(Icons.person, color: arc.primaryColor, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          reply['athletePseudo'] ?? 'Alpha',
                                          style: TextStyle(
                                            color: isSummer ? Colors.black87 : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          reply['createdAt'] ?? '',
                                          style: TextStyle(
                                            color: isSummer ? Colors.black45 : Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reply['content'] ?? '',
                                      style: TextStyle(
                                        color: isSummer ? Colors.black87 : Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
