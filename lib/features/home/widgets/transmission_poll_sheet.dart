import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'package:valerion/core/providers/arc_provider.dart';
import 'package:valerion/core/domain/entities/user_entity.dart';
import 'package:valerion/features/home/models/arc_data.dart';

class TransmissionPollSheet extends ConsumerStatefulWidget {
  const TransmissionPollSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransmissionPollSheet(),
    );
  }

  @override
  ConsumerState<TransmissionPollSheet> createState() => _TransmissionPollSheetState();
}

class _TransmissionPollSheetState extends ConsumerState<TransmissionPollSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  Future<void> _submitVote(UserEntity user, String transmissionId, Map<String, dynamic> poll, String selectedOptionId) async {
    setState(() => _isSubmitting = true);

    try {
      final List<dynamic> options = List<dynamic>.from(poll['options'] ?? []);
      bool updated = false;

      for (var i = 0; i < options.length; i++) {
        var opt = Map<String, dynamic>.from(options[i] as Map<String, dynamic>);
        if (opt['id'] == selectedOptionId) {
          final voters = List<String>.from(opt['voters'] ?? []);
          if (!voters.contains(user.id)) {
            voters.add(user.id);
            opt['voters'] = voters;
            opt['votesCount'] = (opt['votesCount'] ?? 0) + 1;
            options[i] = opt;
            updated = true;
          }
        }
      }

      if (updated) {
        await _firestore.collection('daily_transmissions').doc(transmissionId).update({
          'poll.options': options,
          'poll.totalVotes': (poll['totalVotes'] ?? 0) + 1,
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de l'envoi du vote : $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final userState = ref.watch(authStateProvider);
    final user = userState.valueOrNull;
    final bool isSummer = arc.arcType == AlphaArc.summer;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isSummer ? Colors.white : const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: isSummer ? Colors.black12 : Colors.white10),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isSummer ? Colors.black12 : Colors.white10)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.poll_rounded, color: arc.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "SONDAGE ALPHA",
                        style: TextStyle(
                          color: isSummer ? Colors.black87 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isSummer ? Colors.black54 : Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Poll Stream
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
                          style: TextStyle(color: isSummer ? Colors.black54 : Colors.white54),
                        ),
                      );
                    }

                    final doc = snapshot.data!.docs.first;
                    final data = doc.data() as Map<String, dynamic>;
                    final poll = data['poll'] as Map<String, dynamic>?;

                    if (poll == null) {
                      return Center(
                        child: Text(
                          "Aucun sondage pour cette transmission.",
                          style: TextStyle(color: isSummer ? Colors.black54 : Colors.white54),
                        ),
                      );
                    }

                    final String question = poll['question'] ?? '';
                    final int totalVotes = poll['totalVotes'] ?? 0;
                    final List<dynamic> options = List<dynamic>.from(poll['options'] ?? []);
                    final bool isClosed = poll['isClosed'] == true;

                    // Vérifier si l'utilisateur a déjà voté
                    bool hasVoted = false;
                    String? votedOptionId;
                    if (user != null) {
                      for (var opt in options) {
                        final voters = List<String>.from((opt as Map<String, dynamic>)['voters'] ?? []);
                        if (voters.contains(user.id)) {
                          hasVoted = true;
                          votedOptionId = opt['id'];
                          break;
                        }
                      }
                    }

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Question
                        Text(
                          question,
                          style: TextStyle(
                            color: isSummer ? Colors.black87 : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$totalVotes vote(s)",
                          style: TextStyle(
                            color: isSummer ? Colors.black45 : Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Options
                        ...options.map((optData) {
                          final opt = optData as Map<String, dynamic>;
                          final String optId = opt['id'];
                          final String optText = opt['text'];
                          final int optVotes = opt['votesCount'] ?? 0;
                          final double percentage = totalVotes > 0 ? (optVotes / totalVotes) : 0.0;
                          
                          final bool isThisOptionVoted = votedOptionId == optId;

                          return GestureDetector(
                            onTap: () {
                              if (!hasVoted && !isClosed && user != null && !_isSubmitting) {
                                _submitVote(user, doc.id, poll, optId);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: isSummer ? Colors.grey.shade50 : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isThisOptionVoted 
                                      ? arc.primaryColor 
                                      : (isSummer ? Colors.black12 : Colors.white10),
                                  width: isThisOptionVoted ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Barre de progression (si voté ou fermé)
                                  if (hasVoted || isClosed)
                                    Positioned.fill(
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: percentage,
                                        child: Container(
                                          color: isThisOptionVoted
                                              ? arc.primaryColor.withValues(alpha: 0.2)
                                              : (isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05)),
                                        ),
                                      ),
                                    ),
                                    
                                  // Contenu
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    child: Row(
                                      children: [
                                        if (isThisOptionVoted) ...[
                                          Icon(Icons.check_circle, color: arc.primaryColor, size: 20),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          child: Text(
                                            optText,
                                            style: TextStyle(
                                              color: isSummer ? Colors.black87 : Colors.white,
                                              fontWeight: isThisOptionVoted ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (hasVoted || isClosed) ...[
                                          const SizedBox(width: 12),
                                          Text(
                                            "${(percentage * 100).toStringAsFixed(1)}%",
                                            style: TextStyle(
                                              color: isThisOptionVoted ? arc.primaryColor : (isSummer ? Colors.black54 : Colors.white54),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        if (isClosed) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Le sondage est clôturé.",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
}
