import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

class ShareSelectionDialog extends ConsumerStatefulWidget {
  final String reportText;
  final List<int>? imageData; // Support for sharing the performance card image

  const ShareSelectionDialog({
    super.key,
    required this.reportText,
    this.imageData,
  });

  @override
  ConsumerState<ShareSelectionDialog> createState() => _ShareSelectionDialogState();
}

class _ShareSelectionDialogState extends ConsumerState<ShareSelectionDialog> {
  final Set<String> _selectedFriendIds = {};
  final Set<String> _selectedClanIds = {};
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(userFriendsProvider);
    final clansAsync = ref.watch(userClansProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.cyanAccent, width: 1),
      ),
      title: Row(
        children: [
          const Icon(Icons.share, color: Colors.cyanAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(AppLocalizations.of(context)!.arenaPartageDePerformance,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              if (widget.imageData != null) ...[
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    Uint8List.fromList(widget.imageData!),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                "DESTINATAIRES",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),

              // Friends Section
              _SectionHeader(title: AppLocalizations.of(context)!.arenaRSeauAthlTes),
              friendsAsync.when(
                data: (friends) => friends.isEmpty
                    ? _EmptyList(message: AppLocalizations.of(context)!.arenaAucunDiscipleTrouve)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return _SelectionTile(
                            title: friend.username,
                            subtitle: "Niv. ${friend.level}",
                            isSelected: _selectedFriendIds.contains(friend.id),
                            onChanged: (val) {
                              setState(() {
                                if (val!) {
                                  _selectedFriendIds.add(friend.id);
                                } else {
                                  _selectedFriendIds.remove(friend.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
                error: (e, _) => Text("${AppLocalizations.of(context)!.commonErrorSimple} $e", style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 16),

              // Clans Section
              _SectionHeader(title: AppLocalizations.of(context)!.arenaQuipesClubs),
              clansAsync.when(
                data: (clans) => clans.isEmpty
                    ? _EmptyList(message: AppLocalizations.of(context)!.arenaAucuneFactionRejointe)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: clans.length,
                        itemBuilder: (context, index) {
                          final clan = clans[index];
                          return _SelectionTile(
                            title: clan.name,
                            subtitle: "${clan.membersCount} membres",
                            isSelected: _selectedClanIds.contains(clan.id),
                            onChanged: (val) {
                              setState(() {
                                if (val!) {
                                  _selectedClanIds.add(clan.id);
                                } else {
                                  _selectedClanIds.remove(clan.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
                error: (e, _) => Text("Erreur: $e", style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isSending || (_selectedFriendIds.isEmpty && _selectedClanIds.isEmpty && widget.imageData == null)
              ? null
              : _handleSend,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(AppLocalizations.of(context)!.commonShare, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        // Global Share Button (External)
        if (widget.imageData != null)
           IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.cyanAccent),
            onPressed: () => _handleExternalShare(),
          ),
      ],
    );
  }

  Future<void> _handleExternalShare() async {
    if (widget.imageData == null) return;
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/performance_card.png').create();
    await file.writeAsBytes(widget.imageData!);
    
    await Share.shareXFiles([XFile(file.path)], text: widget.reportText);
  }

  Future<void> _handleSend() async {
    setState(() => _isSending = true);

    try {
      final user = ref.read(userProfileProvider).valueOrNull;
      if (user == null) return;

      String? uploadedImageUrl;

      // 1. Upload de l'image si présente
      if (widget.imageData != null) {
        final storage = ref.read(storageServiceProvider);
        final fileName = 'performance_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // SÉCURITÉ : Le chemin DOIT contenir l'ID utilisateur pour passer les Storage Rules
        uploadedImageUrl = await storage.uploadGenericFile(
          'shared_performances/${user.id}/$fileName',
          Uint8List.fromList(widget.imageData!),
          metadata: SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final valerionRepo = ref.read(valerionRepositoryProvider);
      final clanRepo = ref.read(clanRepositoryProvider);

      // 2. Envoi aux amis
      for (final friendId in _selectedFriendIds) {
        await valerionRepo.sendPrivateMessage(
          fromId: user.id,
          toId: friendId,
          senderName: user.username,
          text: widget.reportText,
          imageUrl: uploadedImageUrl,
          type: uploadedImageUrl != null ? 'image' : 'text',
        );
      }

      // 3. Envoi aux clans
      for (final clanId in _selectedClanIds) {
        await clanRepo.sendClanMessage(
          clanId: clanId,
          senderId: user.id,
          senderName: user.username,
          text: widget.reportText,
          imageUrl: uploadedImageUrl,
          type: uploadedImageUrl != null ? 'image' : 'text',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.arenaPerformancePartagEAvec),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppLocalizations.of(context)!.commonErrorSimple} $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final String message;
  const _EmptyList({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.cyanAccent : Colors.transparent,
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        activeColor: Colors.cyanAccent,
        checkColor: Colors.black,
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
