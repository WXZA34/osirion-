// OSIRION - PANTHEON ALPHA MODULE
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/domain/entities/user_entity.dart';
import '../../core/domain/entities/clan_entity.dart';
import '../../core/domain/entities/clan_message_entity.dart';
import '../../core/widgets/avatar_viewer.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';
import '../../core/widgets/clickable_text.dart';
import '../arsenal/models/relic.dart';
import 'widgets/audio_message_bubble.dart';
import 'widgets/video_message_bubble.dart';
import 'package:gal/gal.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/video_service.dart';
import 'screens/alpha_camera_screen.dart';
import 'package:camera/camera.dart'; 
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PantheonScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const PantheonScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<PantheonScreen> createState() => _PantheonScreenState();
}

class _PantheonScreenState extends ConsumerState<PantheonScreen> {
  late int _selectedTabIndex; // 0: Connect, 1: Clans, 2: Leaderboards, 3: Domination

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

  String _currentSortBy = 'xp'; // Variable pour le Leaderboard
  String _clanSearchQuery = ''; // Recherche de clans

  bool _isPickingImage = false;

  Future<void> _updateClanLogo(ClanEntity clan, bool isLeader) async {
    if (!isLeader) return;
    if (_isPickingImage) return;

    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload du logo en cours...')),
      );

      final bytes = await pickedFile.readAsBytes();
      final storageService = ref.read(storageServiceProvider);
      final clanRepo = ref.read(clanRepositoryProvider);

      final downloadUrl = await storageService.uploadClanLogo(clan.id, bytes);
      await clanRepo.updateClanLogo(clan.id, downloadUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo du clan mis à jour !'),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final bool isSummer = arc.arcType == AlphaArc.summer;

    // Theme colors for Pantheon
    final Color accentColor = isSummer ? arc.primaryColor : const Color(0xFFFFD700);
    final Color surfaceColor = arc.surfaceColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "LE PANTHÉON",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w900,
            fontFamily: 'Noto Serif',
            letterSpacing: 3,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTopNavigationBar(surfaceColor, accentColor, arc, isSummer),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: _buildCurrentTabContent(surfaceColor, accentColor, arc, isSummer, arc.onSurfaceColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isSummer ? Colors.black12 : accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavTab(0, "Connect", Icons.forum, accentColor, arc, isSummer),
          _buildNavTab(1, "Clans", Icons.shield, accentColor, arc, isSummer),
          _buildNavTab(2, "Classements", Icons.emoji_events, accentColor, arc, isSummer),
          _buildNavTab(3, "Domination", Icons.location_on, accentColor, arc, isSummer),
        ],
      ),
    );
  }

  Widget _buildNavTab(
    int index,
    String label,
    IconData icon,
    Color accentColor,
    ArcData arc,
    bool isSummer,
  ) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? accentColor 
                  : (isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? accentColor 
                    : (isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildConnectTab(surfaceColor, accentColor, arc, isSummer, onSurfaceColor);
      case 1:
        return _buildClans(surfaceColor, accentColor, arc, isSummer, onSurfaceColor); // Sera revu plus tard
      case 2:
        return _buildLeaderboards(
          surfaceColor,
          accentColor,
          arc,
          isSummer,
          onSurfaceColor,
        ); // Sera revu plus tard
      case 3:
        return _buildDominationSpots(
          surfaceColor,
          accentColor,
          arc,
          isSummer,
          onSurfaceColor,
        ); // Trophées -> Domination
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Tab 0: Alpha Connect (Messagerie) ---
  Widget _buildConnectTab(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Statut Personnel Actuel
        _buildAlphaStatusPanel(surfaceColor, accentColor, arc, isSummer, onSurfaceColor),
        const SizedBox(height: 24),

        // 2. Gestion des Demandes d'Amis
        _buildFriendRequestsSection(accentColor),

        // Cercle de Confiance (Amis)
        _buildSectionTitle("CERCLE DE CONFIANCE", Icons.group, accentColor),
        const SizedBox(height: 16),
        _buildHorizontalFriendsList(accentColor),
        const SizedBox(height: 24),

        // Discussions Actives
        _buildSectionTitle("TRANSMISSIONS", Icons.forum, accentColor),
        const SizedBox(height: 16),
        _buildChatList(surfaceColor, accentColor, arc, isSummer, onSurfaceColor),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendRequestsSection(Color accentColor) {
    return ref
        .watch(userFriendRequestsProvider)
        .when(
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  "DEMANDES ALPHA",
                  Icons.person_add,
                  Colors.cyanAccent,
                ),
                const SizedBox(height: 16),
                ...requests.map(
                  (req) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        AvatarViewer(
                          imageUrl: req.profileImageUrl,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            req.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: Colors.greenAccent,
                          ),
                          onPressed: () async {
                            final currentUser =
                                ref.read(userProfileProvider).value;
                            if (currentUser != null) {
                              await ref
                                  .read(valerionRepositoryProvider)
                                  .acceptFriendRequest(currentUser.id, req.id);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final currentUser =
                                ref.read(userProfileProvider).value;
                            if (currentUser != null) {
                              await ref
                                  .read(valerionRepositoryProvider)
                                  .declineFriendRequest(currentUser.id, req.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }

  Widget _buildAlphaStatusPanel(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    Color statusColor;
    String statusText = user.status ?? "online";

    switch (statusText.toLowerCase()) {
      case 'online':
      case 'disponible':
        statusColor = Colors.greenAccent;
        statusText = "DISPONIBLE";
        break;
      case 'in_dojo':
      case 'in_arena':
      case 'en plein effort':
        statusColor = Colors.orangeAccent;
        statusText = "EN PLEIN EFFORT";
        break;
      case 'offline':
      case 'hors ligne':
        statusColor = Colors.grey;
        statusText = "HORS LIGNE";
        break;
      case 'ne pas déranger':
        statusColor = Colors.redAccent;
        statusText = "NE PAS DÉRANGER";
        break;
      default:
        statusColor = Colors.cyanAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSummer ? Colors.black12 : Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: statusColor, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  color: isSummer ? arc.onSurfaceColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed:
                () => _showStatusPicker(context, user.status ?? "online"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.1) : Colors.white10,
              foregroundColor: isSummer ? arc.onSurfaceColor : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("MODIFIER", style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, String currentStatus) {
    final statuses = [
      {"label": "DISPONIBLE", "value": "online", "color": Colors.greenAccent},
      {
        "label": "EN PLEIN EFFORT",
        "value": "in_dojo",
        "color": Colors.orangeAccent,
      },
      {"label": "EN REPOS", "value": "offline", "color": Colors.grey},
      {
        "label": "NE PAS DÉRANGER",
        "value": "ne pas déranger",
        "color": Colors.redAccent,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111115),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "CHANGER VOTRE STATUT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ...statuses.map(
                (s) => ListTile(
                  leading: CircleAvatar(
                    radius: 6,
                    backgroundColor: s['color'] as Color,
                  ),
                  title: Text(
                    s['label'] as String,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing:
                      currentStatus == s['value']
                          ? const Icon(Icons.check, color: Colors.cyanAccent)
                          : null,
                  onTap: () {
                    ref
                        .read(valerionRepositoryProvider)
                        .updateUserStatus(
                          ref.read(userProfileProvider).value!.id,
                          s['value'] as String,
                        );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalFriendsList(Color accentColor) {
    return ref
        .watch(userFriendsProvider)
        .when(
          data: (friends) {
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length + 1,
                itemBuilder: (context, index) {
                  if (index == friends.length) {
                    return _buildAddFriendCircle(accentColor);
                  }

                  final friend = friends[index];
                  final currentUser = ref.read(userProfileProvider).value;
                  String chatId = "";
                  if (currentUser != null) {
                    final ids = [currentUser.id, friend.id];
                    ids.sort();
                    chatId = ids.join('_');
                  }

                  // Recalcul de la couleur de statut
                  Color statusColor;
                  switch ((friend.status ?? "online").toLowerCase()) {
                    case 'online':
                    case 'disponible':
                      statusColor = Colors.greenAccent;
                      break;
                    case 'in_dojo':
                    case 'in_arena':
                    case 'en plein effort':
                      statusColor = Colors.orangeAccent;
                      break;
                    case 'ne pas déranger':
                      statusColor = Colors.redAccent;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PantheonChatScreen(
                                  chatName: friend.username,
                                  friendId: friend.id,
                                  surfaceColor: const Color(
                                    0xFF1E293B,
                                  ), // Couleur sombre
                                  accentColor: accentColor,
                                ),
                          ),
                        );
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => PublicProfileDialog(
                            user: friend,
                            accentColor: accentColor,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              AvatarViewer(
                                imageUrl: friend.profileImageUrl,
                                radius: 30,
                                enableFullScreen: true,
                              ),
                              // Badge de Statut
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF111115),
                                    width: 3,
                                  ),
                                ),
                              ),
                              // Badge de Message Non Lu (Nouveau)
                              if (chatId.isNotEmpty)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final metadata = ref.watch(privateChatMetadataProvider(chatId)).valueOrNull;
                                    final unreadMap = metadata?['unreadCount'] as Map<String, dynamic>?;
                                    final score = unreadMap?[currentUser?.id] ?? 0;
                                    
                                    if (score == 0) return const SizedBox.shrink();
                                    
                                    return Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF111115), width: 2),
                                        ),
                                        child: Text(
                                          score.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            friend.username,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading:
              () => const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white10),
                ),
              ),
          error:
              (e, s) => SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    "Erreur: $e",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
        );
  }

  Widget _buildAddFriendCircle(Color accentColor) {
    return GestureDetector(
      onTap: () => _showAddFriendDialog(context, accentColor),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: accentColor.withValues(alpha: 0.2),
            child: Icon(Icons.person_add, color: accentColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajouter",
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    final clansAsync = ref.watch(userClansProvider);
    final friendsAsync = ref.watch(userFriendsProvider);

    final announcements = ref.watch(systemAnnouncementsProvider).valueOrNull ?? [];
    final currentUser = ref.watch(userProfileProvider).valueOrNull;
    
    int systemUnreadCount = 0;
    if (currentUser != null && announcements.isNotEmpty) {
      final lastRead = currentUser.lastReadSystemTimestamp;
      if (lastRead == null) {
        systemUnreadCount = announcements.length;
      } else {
        systemUnreadCount = announcements.where((m) => m.timestamp.isAfter(lastRead)).length;
      }
    }

    return Column(
      children: [
        // TRANSMISSION SYSTÈME (Statique)
        _buildChatTile(
          name: "SYSTÈME OSIRION",
          message: "Transmissions Officielles Alpha",
          time: "DIRECT",
          isAudio: false,
          unreadScore: systemUnreadCount,
          surfaceColor: surfaceColor,
          accentColor: Colors.redAccent,
          imageUrl: null, 
          arc: arc,
          isSummer: isSummer,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PantheonChatScreen(
                      chatName: "SYSTÈME OSIRION",
                      isSystem: true,
                      surfaceColor: surfaceColor,
                      accentColor: Colors.redAccent,
                    ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Section Clans
        clansAsync.when(
          data: (clans) {
            if (clans.isEmpty) return const SizedBox.shrink();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clans.length,
              itemBuilder: (context, index) {
                final clan = clans[index];
                final currentUser = ref.read(userProfileProvider).valueOrNull;
                // Sécurisation contre les objets anciens en mémoire après Hot Reload
                final Map<String, int> unreads = (clan as dynamic).unreadCounts ?? const <String, int>{};
                final unreadScore = unreads[currentUser?.id] ?? 0;
                
                return _buildChatTile(
                  name: clan.name.toUpperCase(),
                  message: "Canal de Faction Alpha",
                  time: "ACTIF",
                  isAudio: false,
                  unreadScore: unreadScore,
                  surfaceColor: surfaceColor,
                  accentColor: accentColor,
                  imageUrl: clan.logoUrl,
                  arc: arc,
                  isSummer: isSummer,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PantheonChatScreen(
                              chatName: clan.name,
                              clanId: clan.id,
                              surfaceColor: surfaceColor,
                              accentColor: accentColor,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),

        // Section Amis
        friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) return const SizedBox.shrink();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final currentUser = ref.read(userProfileProvider).value;
                String chatId = "";
                if (currentUser != null) {
                  final ids = [currentUser.id, friend.id];
                  ids.sort();
                  chatId = ids.join('_');
                }

                return Consumer(
                  builder: (context, ref, child) {
                    int score = 0;
                    if (chatId.isNotEmpty) {
                      final metadata = ref.watch(privateChatMetadataProvider(chatId)).valueOrNull;
                      final unreadMap = metadata?['unreadCount'] as Map<String, dynamic>?;
                      final rawScore = unreadMap?[currentUser?.id] ?? 0;
                      score = rawScore is int ? rawScore : (int.tryParse(rawScore.toString()) ?? 0);
                    }

                    return _buildChatTile(
                      name: friend.username,
                      message: "Transmission Privée Alpha",
                      time: friend.status ?? "online",
                      isAudio: false,
                      unreadScore: score,
                      surfaceColor: surfaceColor,
                      accentColor: accentColor,
                      imageUrl: friend.profileImageUrl,
                      arc: arc,
                      isSummer: isSummer,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PantheonChatScreen(
                                  chatName: friend.username,
                                  friendId: friend.id,
                                  surfaceColor: surfaceColor,
                                  accentColor: accentColor,
                                ),
                          ),
                        ).then((_) {
                           // Optionnel: On peut aussi forcer un refresh ici si besoin
                        });
                      },
                    );
                  },
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),

        // Message si rien
        if (clansAsync.valueOrNull?.isEmpty == true &&
            friendsAsync.valueOrNull?.isEmpty == true)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "AUCUN CANAL ACTIF.\nREJOIGNEZ UN CLAN OU AJOUTEZ DES AMIS.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatTile({
    required String name,
    required String message,
    required String time,
    required bool isAudio,
    required int unreadScore,
    required Color surfaceColor,
    required Color accentColor,
    required ArcData arc,
    required bool isSummer,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    bool hasUnread = unreadScore > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasUnread 
              ? accentColor.withValues(alpha: isSummer ? 0.1 : 0.05) 
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread 
                ? accentColor.withValues(alpha: 0.3) 
                : (isSummer ? Colors.black12 : Colors.white10),
          ),
        ),
        child: Row(
          children: [
            AvatarViewer(
              imageUrl: imageUrl,
              radius: 20,
              enableFullScreen: true,
              fallbackIcon: name.startsWith("Groupe") ? Icons.group : Icons.person,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSummer ? arc.onSurfaceColor : Colors.white,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isAudio) ...[
                        const Icon(Icons.mic, color: Colors.cyan, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                          child: Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread 
                                  ? (isSummer ? arc.onSurfaceColor : Colors.white) 
                                  : (isSummer ? arc.onSurfaceColor.withValues(alpha: 0.6) : Colors.white54),
                              fontSize: 12,
                            ),
                          ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: hasUnread ? accentColor : Colors.white38,
                    fontSize: 10,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadScore.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, Color accentColor) {
    String searchQuery = "";
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111115),
              title: const Text(
                "RECHERCHER UN ALPHA",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val.trim();
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Pseudo...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: () => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (searchQuery.length >= 3)
                    SizedBox(
                      height: 200,
                      width: double.maxFinite,
                      child: ref
                          .watch(userSearchProvider(searchQuery))
                          .when(
                            data: (users) {
                              if (users.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "Aucun Alpha trouvé",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final currentUser =
                                      ref.read(userProfileProvider).value;
                                  if (user.id == currentUser?.id) {
                                    return const SizedBox.shrink();
                                  }

                                  bool isAlreadyFriend =
                                      currentUser?.friendIds.contains(
                                        user.id,
                                      ) ??
                                      false;
                                  bool isPending =
                                      currentUser?.outgoingRequestIds.contains(
                                        user.id,
                                      ) ??
                                      false;

                                  return ListTile(
                                    leading: AvatarViewer(
                                      imageUrl: user.profileImageUrl,
                                      radius: 20,
                                      fallbackIcon: Icons.person,
                                    ),
                                    title: Text(
                                      user.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Niveau ${user.level}",
                                      style: const TextStyle(
                                        color: Colors.white38,
                                      ),
                                    ),
                                    trailing:
                                        isAlreadyFriend
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.greenAccent,
                                            )
                                            : isPending
                                            ? const Text(
                                              "EN ATTENTE",
                                              style: TextStyle(
                                                color: Colors.white24,
                                                fontSize: 10,
                                              ),
                                            )
                                            : IconButton(
                                              icon: const Icon(
                                                Icons.person_add,
                                                color: Colors.cyanAccent,
                                              ),
                                              onPressed: () async {
                                                await ref
                                                    .read(
                                                      valerionRepositoryProvider,
                                                    )
                                                    .sendFriendRequest(
                                                      currentUser!.id,
                                                      user.id,
                                                    );
                                                if (!context.mounted) return;
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Demande envoyée à ${user.username} !",
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                  );
                                },
                              );
                            },
                            loading:
                                () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error: (e, s) => Text("Erreur: $e"),
                          ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "FERMER",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Tab 3: Domination Urbaine (Spots) ---
  Widget _buildDominationSpots(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return Column(
      key: const ValueKey(3),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        Icon(Icons.construction, color: accentColor, size: 64),
        const SizedBox(height: 24),
        Text(
          "MODULE EN COURS DE DÉVELOPPEMENT",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accentColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Le centre de commandement stratégique OSIRION arrive bientôt. Préparez vos clans pour la conquête territoriale.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurfaceColor.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- Tab 2: Le Panthéon (Classements) ---
  Widget _buildLeaderboards(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête Filtres
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              "LES IMMORTELS",
              Icons.emoji_events,
              accentColor,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: isSummer ? onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Mondial",
                    style: TextStyle(
                      color: isSummer ? onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: isSummer ? onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Clan Search Bar (Only for Clans Tab)
        if (_currentSortBy == 'clans') ...[
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "RECHERCHER UNE FACTION...",
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _clanSearchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Category Selector (Les 3 Piliers)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  {'label': 'Alpha Suprême (Harmonie)', 'value': 'xp'},
                  {'label': 'Maîtres du Dojo (Force)', 'value': 'forceXp'},
                  {
                    'label': 'Sages de l\'Arène (Sagesse)',
                    'value': 'wisdomXp',
                  },
                  {'label': 'Factions (Top Clans)', 'value': 'clans'},
                ].map((cat) {
                  bool isSelected = _currentSortBy == cat['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentSortBy = cat['value']!;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? accentColor.withValues(alpha: 0.2)
                                : surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.white10,
                        ),
                      ),
                      child: Text(
                        cat['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? accentColor
                              : (isSummer
                                  ? onSurfaceColor.withValues(alpha: 0.4)
                                  : Colors.white70),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Podiums & Leaderboard List via Riverpod
        if (_currentSortBy == 'clans')
          _buildClansLeaderboardView(surfaceColor, accentColor, arc, isSummer, onSurfaceColor)
        else
          ref
              .watch(leaderboardProvider(_currentSortBy))
              .when(
                data: (users) {
                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          "Aucun immortel trouvé...",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }
                  final currentUser = ref.watch(userProfileProvider).valueOrNull;
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children:
                              users.asMap().entries.map((entry) {
                                int index = entry.key;
                                UserEntity user = entry.value;
                                return _buildLeaderboardRow(
                                  user: user,
                                  rank: index + 1,
                                  isUser: currentUser?.id == user.id,
                                  accentColor: accentColor,
                                  isSummer: isSummer,
                                  onSurfaceColor: onSurfaceColor,
                                );
                              }).toList(),
                        ),
                      ),
                      
                      // Phase 22 : Affichage du rang personnel (Hors Top 50)
                      if (currentUser != null && !users.any((u) => u.id == currentUser.id)) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle("VOTRE POSITION", Icons.person_pin_circle, accentColor),
                        const SizedBox(height: 12),
                        ref.watch(userRankProvider(_currentSortBy)).when(
                          data: (rank) => Container(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                            ),
                            child: _buildLeaderboardRow(
                              user: currentUser,
                              rank: rank,
                              isUser: true,
                              accentColor: accentColor,
                              isSummer: isSummer,
                              onSurfaceColor: onSurfaceColor,
                            ),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  );
                },
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    ),
                error:
                    (err, stack) => Center(
                      child: Text(
                        "Erreur de connexion aux archives: $err",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
              ),
      ],
    );
  }

  Widget _buildLeaderboardRow({
    required UserEntity user,
    required int rank,
    required bool isUser,
    required Color accentColor,
    required bool isSummer,
    required Color onSurfaceColor,
  }) {
    Color rankColor =
        rank == 1
            ? accentColor
            : (rank == 2
                ? (isSummer ? Colors.blueGrey[400]! : Colors.grey[300]!)
                : (rank == 3
                    ? (isSummer ? Colors.brown[400]! : Colors.brown[300]!)
                    : (isSummer ? onSurfaceColor.withValues(alpha: 0.4) : Colors.white54)));

    String scoreStr =
        _currentSortBy == 'xp'
            ? user.xp.toString()
            : (_currentSortBy == 'forceXp'
                ? user.forceXp.toString()
                : user.wisdomXp.toString());

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) =>
                  PublicProfileDialog(user: user, accentColor: accentColor),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isUser ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                "#$rank",
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFamily: 'Noto Serif',
                ),
              ),
            ),
            const SizedBox(width: 12),
            AvatarViewer(
              imageUrl: user.profileImageUrl,
              radius: 16,
              enableFullScreen: true,
              fallbackIcon: Icons.person,
              borderColor: isUser ? accentColor.withValues(alpha: 0.5) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      color: isUser
                          ? accentColor
                          : (isSummer ? onSurfaceColor : Colors.white),
                      fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (user.activeTitle != null)
                    Text(
                      Relic.findById(user.activeTitle)?.name ?? "",
                      style: TextStyle(
                        color: Relic.findById(user.activeTitle)?.color.withValues(alpha: 0.7) ?? Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              scoreStr,
              style: const TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 2: Clans (Coopération) ---
  // --- Tab 1: Groupes de Dépassement & Mur du Clan ---
  // --- Tab 1: Clans (Factions) ---
  Widget _buildClans(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return ref
        .watch(userProfileProvider)
        .when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();

            return Column(
              key: const ValueKey("ClansTab"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildClanInvitationsSection(surfaceColor, accentColor),
                _buildUserClansSection(user, surfaceColor, accentColor, arc, isSummer),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_moderator),
                  label: const Text(
                    "FONDER UN NOUVEAU CLAN",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _showCreateClanDialog(accentColor),
                ),
              ],
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
          error:
              (e, s) => Center(
                child: Text(
                  "Erreur: $e",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
        );
  }

  // --- SECTION: INVITATIONS REÇUES ---
  Widget _buildClanInvitationsSection(Color surfaceColor, Color accentColor) {
    return ref
        .watch(userClanRequestsProvider)
        .when(
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  "INVITATIONS REÇUES",
                  Icons.mail,
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                ...requests
                    .map(
                      (req) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Rejoindre ${req.clanName}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                              ),
                              onPressed: () {
                                ref
                                    .read(clanRepositoryProvider)
                                    .acceptClanRequest(req);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                ref
                                    .read(clanRepositoryProvider)
                                    .rejectClanRequest(req.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 32),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error:
              (e, s) => Text(
                "Erreur invitations: $e",
                style: const TextStyle(color: Colors.red),
              ),
        );
  }

  // --- VUE: LEADERBOARD DES CLANS (CLASSEMENTS) ---
  Widget _buildClansLeaderboardView(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    final clansAsync = _clanSearchQuery.isEmpty
        ? ref.watch(clansLeaderboardProvider)
        : ref.watch(clanSearchProvider(_clanSearchQuery));

    return Column(
      key: const ValueKey("ClansLeaderboard"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clansAsync.when(
              data: (clans) {
                if (clans.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        "Aucun clan n'existe encore...",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children:
                        clans.asMap().entries.map((entry) {
                          final clan = entry.value;
                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "#${entry.key + 1}",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: accentColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: ClipOval(
                                    child: clan.logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: clan.logoUrl!,
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Opacity(opacity: 0.5, child: Icon(Icons.shield, size: 20)),
                                            errorWidget: (ctx, url, error) => Icon(
                                              Icons.shield,
                                              size: 20,
                                              color: accentColor,
                                            ),
                                          )
                                        : Icon(
                                            Icons.shield,
                                            size: 20,
                                            color: accentColor,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              clan.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${clan.membersCount} membres",
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Text(
                              "${clan.totalXp} XP",
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                             onTap: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => ClanDetailsDialog(
                                   clan: clan,
                                   accentColor: accentColor,
                                 ),
                               );
                             },
                          );
                        }).toList(),
                  ),
                );
              },
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
              error:
                  (e, s) => Text(
                    "Erreur: $e",
                    style: const TextStyle(color: Colors.red),
                  ),
            ),
      ],
    );
  }

  // --- SECTION: MES CLANS ---
  Widget _buildUserClansSection(
    UserEntity user,
    Color surfaceColor,
    Color accentColor,
    ArcData arc,
    bool isSummer,
  ) {
    return ref
        .watch(userClansProvider)
        .when(
          data: (clans) {
            if (clans.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    "Vous ne faites partie d'aucun clan.\nRejoignez-en un via les classements ou fondez le vôtre !",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, height: 1.5),
                  ),
                ),
              );
            }

            return Column(
              key: const ValueKey("MyClansList"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("MES FACTIONS", Icons.shield, accentColor),
                const SizedBox(height: 16),
                ...clans.map((clan) {
                  final isLeader = clan.leaderId == user.id;
                  final isLight = ThemeData.estimateBrightnessForColor(surfaceColor) == Brightness.light;
                  final textColor = isLight ? Colors.black87 : Colors.white;
                  final textDimColor = isLight ? Colors.black54 : Colors.white70;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header: Clan Name & Stats
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.3),
                                surfaceColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => _updateClanLogo(clan, isLeader),
                                borderRadius: BorderRadius.circular(
                                  40,
                                ), // Effet visuel circulaire
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        isLeader
                                            ? Border.all(
                                              color: accentColor.withValues(
                                                alpha: 0.8,
                                              ),
                                              width: 2,
                                            )
                                            : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: const Color(0xFF111111),
                                  child: ClipOval(
                                    child: clan.logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: clan.logoUrl!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(strokeWidth: 2)),
                                            errorWidget: (ctx, url, error) => Icon(
                                              Icons.shield,
                                              color: accentColor,
                                              size: 40,
                                            ),
                                          )
                                        : Icon(
                                            Icons.shield,
                                            color: accentColor,
                                            size: 40,
                                          ),
                                  ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                clan.name.toUpperCase(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                clan.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textDimColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildClanStat(
                                    "XP TOTAL",
                                    clan.totalXp.toString(),
                                    isLight ? Colors.indigo : Colors.cyanAccent,
                                    labelColor: textDimColor,
                                  ),
                                  _buildClanStat(
                                    "MEMBRES",
                                    clan.membersCount.toString(),
                                    textColor,
                                    labelColor: textDimColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Boutons d'Action Rapide pour ce Clan
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.forum, size: 18),
                                label: const Text(
                                  "TRANSMISSION",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: surfaceColor,
                                  foregroundColor: textColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: accentColor),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PantheonChatScreen(
                                            chatName: clan.name.toUpperCase(),
                                            clanId: clan.id,
                                            surfaceColor: surfaceColor,
                                            accentColor: accentColor,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ClanMembersScreen(
                                          clan: clan,
                                          currentUserId: user.id,
                                          surfaceColor: surfaceColor,
                                          accentColor: accentColor,
                                        ),
                                  ),
                                );
                              },
                              child: const Icon(Icons.people_alt),
                            ),
                            if (!isLeader) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                ),
                                onPressed: () => _confirmLeaveClan(context, clan),
                                child: const Icon(Icons.exit_to_app),
                              ),
                            ],
                            if (isLeader) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                onPressed:
                                    () => _confirmDeleteClan(context, clan),
                                child: const Icon(Icons.delete_forever),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
          error:
              (e, s) =>
                  Text("Erreur: $e", style: const TextStyle(color: Colors.red)),
        );
  }

  Widget _buildClanStat(String label, String value, Color color, {Color labelColor = Colors.white54}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // --- LOGIQUE METIER & DIALOGUES ---
  void _showCreateClanDialog(Color accentColor) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B), // slate-800
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: accentColor, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "FORGER UN NOUVEAU CLAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Nom du Clan",
                    labelStyle: const TextStyle(color: Colors.white54),
                    hintText: "Ex : Les Spartiates du Parc",
                    hintStyle: const TextStyle(color: Colors.white24),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Devise / Description",
                    labelStyle: const TextStyle(color: Colors.white54),
                    hintText: "Optionnel",
                    hintStyle: const TextStyle(color: Colors.white24),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final desc = descController.text.trim();
                      if (name.isNotEmpty) {
                        try {
                          final user = ref.read(userProfileProvider).value;
                          if (user != null) {
                            await ref
                                .read(clanRepositoryProvider)
                                .createClan(
                                  name: name,
                                  description: desc,
                                  leaderId: user.id,
                                  initialXp: user.xp,
                                );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "CRÉER LE CLAN",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "ANNULER",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _confirmDeleteClan(BuildContext context, ClanEntity clan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "Dissoudre le Clan",
              style: TextStyle(color: Colors.redAccent),
            ),
            content: Text(
              "Êtes-vous sûr de vouloir dissoudre définitivement ${clan.name} ? Cette action est irréversible et retirera le clan de tous ses membres.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Annuler",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Dissoudre",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ref.read(clanRepositoryProvider).deleteClan(clan.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Le clan a été dissous avec succès."),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmLeaveClan(BuildContext context, ClanEntity clan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "Quitter le Clan",
              style: TextStyle(color: Colors.orangeAccent),
            ),
            content: Text(
              "Voulez-vous vraiment quitter le clan ${clan.name} ? Vous perdrez l'accès au chat et aux bonus de faction.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Annuler",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Quitter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ref.read(clanRepositoryProvider).leaveClan(
          clanId: clan.id,
          userId: ref.read(userProfileProvider).value!.id,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Vous avez quitté ${clan.name}."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

class PantheonChatScreen extends ConsumerStatefulWidget {
  final String chatName;
  final String? clanId;
  final String? friendId;
  final Color surfaceColor;
  final Color accentColor;
  final bool isSystem;

  const PantheonChatScreen({
    super.key,
    required this.chatName,
    this.clanId,
    this.friendId,
    required this.surfaceColor,
    required this.accentColor,
    this.isSystem = false,
  });

  @override
  ConsumerState<PantheonChatScreen> createState() => _PantheonChatScreenState();
}

class _PantheonChatScreenState extends ConsumerState<PantheonChatScreen> {
  final List<ClanMessageEntity> _localOptimisticQueue = [];
  final TextEditingController _msgController = TextEditingController();
  AudioRecorder? _recorder;
  bool _isRecording = false;
  bool _isUploadingMedia = false;
  final SmartVideoService _smartVideoService = SmartVideoService();
  double _compressionProgress = 0;
  bool _isCompressing = false;
  final ImagePicker _picker = ImagePicker();
  bool _chatInitialized = false; // Initialisation du chat faite UNE SEULE FOIS à l'ouverture

  @override
  void initState() {
    super.initState();
    _markRead();
    _initChatIfNeeded(); // Pré-initialise le canal de discussion dès l'ouverture
  }

  void _markRead() {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;
    
    if (widget.friendId != null) {
      final ids = [user.id, widget.friendId!];
      ids.sort();
      final chatId = ids.join('_');
      ref.read(valerionRepositoryProvider).markPrivateChatAsRead(chatId, user.id);
    } else if (widget.clanId != null) {
      ref.read(clanRepositoryProvider).markClanAsRead(widget.clanId!, user.id);
    } else if (widget.isSystem) {
      ref.read(valerionRepositoryProvider).markSystemAnnouncementsAsRead(user.id);
    }
  }

  /// Initialise le canal privé UNE SEULE FOIS à l'ouverture de l'écran
  /// pour éviter l'appel Cloud Function bloquant à chaque envoi de message.
  Future<void> _initChatIfNeeded() async {
    if (widget.friendId == null) return;
    if (_chatInitialized) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('initializePrivateChat')
          .call({'targetUid': widget.friendId});
      _chatInitialized = true;
    } on FirebaseFunctionsException catch (fe) {
      debugPrint('⚠️ [Chat] initializePrivateChat: ${fe.message}');
    } catch (e) {
      debugPrint('⚠️ [Chat] initializePrivateChat erreur: $e');
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    if (widget.clanId == null && widget.friendId == null) return;

    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    // 1. Créer le message optimiste avec un ID unique temporaire
    final optimisticId = "opt_${DateTime.now().millisecondsSinceEpoch}";
    final optimisticMsg = ClanMessageEntity(
      id: optimisticId,
      clanId: widget.clanId ?? "private",
      senderId: user.id,
      senderName: user.username,
      text: text,
      type: 'text',
      timestamp: DateTime.now(),
      isOptimistic: true,
    );

    // 2. Mise à jour instantanée de l'interface
    setState(() {
      _localOptimisticQueue.add(optimisticMsg);
      _msgController.clear();
    });

    try {
      if (widget.clanId != null) {
        // Transmission asynchrone réelle
        await ref
            .read(clanRepositoryProvider)
            .sendClanMessage(
              clanId: widget.clanId!,
              senderId: user.id,
              senderName: user.username,
              text: text,
            );
      } else if (widget.friendId != null) {
        await ref
            .read(valerionRepositoryProvider)
            .sendPrivateMessage(
              fromId: user.id,
              toId: widget.friendId!,
              senderName: user.username,
              text: text,
            );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains("BLOCK_DELETED")) {
          final cleanMsg = errorStr.split("BLOCK_DELETED:").last.replaceAll("Exception: ", "").trim();
          _showDeletedBlockDialog(cleanMsg);
        } else {
          final cleanMsg = errorStr.replaceAll("Exception:", "").replaceAll("error_envoi:", "").trim();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Oups, erreur d'envoi : $cleanMsg")));
        }
      }
    } finally {
      // 3. Purge du message local (il sera bientôt remplacé par le vrai flux Firestore)
      if (mounted) {
        setState(() {
          _localOptimisticQueue.removeWhere((m) => m.id == optimisticId);
        });
      }
    }
  }

  void _showDeletedBlockDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text("Action Requise", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("FERMER", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUser = ref.read(userProfileProvider).valueOrNull;
              if (currentUser != null && widget.friendId != null) {
                try {
                  await ref.read(valerionRepositoryProvider).sendFriendRequest(currentUser.id, widget.friendId!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Nouvelle demande lancée !")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur : $e")),
                    );
                  }
                }
              }
            },
            child: const Text("RÉ-INVITER", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _smartVideoService.dispose(); 
    try {
      _recorder?.dispose();
    } catch (e) {
      debugPrint("⚠️ Erreur lors du dispose du recorder: $e");
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    debugPrint("🎤 [_startRecording] Début de la procédure...");
    try {
      debugPrint("🎤 [_startRecording] Demande de permission microphone...");
      final status = await Permission.microphone.request();
      debugPrint("🎤 [_startRecording] Statut permission: $status");
      
      if (status.isPermanentlyDenied) {
        debugPrint("🎤 [_startRecording] Permission refusée en permanence");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("L'accès au micro est requis dans les paramètres de votre téléphone.")),
          );
        }
        return;
      }

      if (status.isGranted) {
        debugPrint("🎤 [_startRecording] Permission accordée, préparation du fichier...");
        final directory = await getTemporaryDirectory();
        final path = p.join(directory.path, 'voice_message.m4a');
        
        // Supprimer l'ancien fichier s'il existe
        final file = File(path);
        if (await file.exists()) {
          debugPrint("🎤 [_startRecording] Suppression de l'ancien fichier temporaire");
          await file.delete();
        }

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100, // Retour au standard 44.1kHz
          numChannels: 1,
        );
        
        debugPrint("🎤 [_startRecording] Démarrage de l'enregistrement réel (AudioRecorder.start)...");
        _recorder ??= AudioRecorder();
        await _recorder!.start(config, path: path);
        debugPrint("🎤 [_startRecording] Enregistrement démarré avec succès");
        setState(() => _isRecording = true);
      } else {
        debugPrint("🎤 [_startRecording] Permission refusée");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permission micro refusée.")),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ [_startRecording] ERREUR FATALE: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur micro: $e")),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    debugPrint("🎤 [_stopAndSendRecording] Fin de l'enregistrement demandée...");
    if (_recorder == null) {
      debugPrint("🎤 [_stopAndSendRecording] ANNULÉ: Recorder non initialisé");
      setState(() => _isRecording = false);
      return;
    }
    try {
      final path = await _recorder!.stop();
      debugPrint("🎤 [_stopAndSendRecording] Enregistrement stoppé. Chemin: $path");
      setState(() => _isRecording = false);
      
      if (path != null) {
        debugPrint("🎤 [_stopAndSendRecording] Lancement de l'upload...");
        await _uploadAndSendVoiceMessage(path);
        debugPrint("🎤 [_stopAndSendRecording] Procédure complète terminée.");
      }
    } catch (e) {
      debugPrint("❌ [_stopAndSendRecording] ERREUR: $e");
      setState(() => _isRecording = false);
    }
  }

  Future<void> _uploadAndSendVoiceMessage(String filePath) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    // 1. Créer le message optimiste avec le chemin local pour lecture immédiate
    final optimisticId = "opt_voice_${DateTime.now().millisecondsSinceEpoch}";
    final optimisticMsg = ClanMessageEntity(
      id: optimisticId,
      clanId: widget.clanId ?? "private",
      senderId: user.id,
      senderName: user.username,
      audioUrl: filePath, // Utilise le chemin local temporairement
      type: 'audio',
      timestamp: DateTime.now(),
      isOptimistic: true,
    );

    // 2. Affichage instantané
    setState(() {
      _localOptimisticQueue.add(optimisticMsg);
    });

    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      final storageService = ref.read(storageServiceProvider);
      
      String storeId = widget.clanId ?? "";
      if (widget.friendId != null) {
        final ids = [user.id, widget.friendId!];
        ids.sort();
        storeId = ids.join('_');
      }

      final fileName = "${DateTime.now().millisecondsSinceEpoch}.m4a";
      final destination = "chat_voices/$storeId/$fileName";
      
      final audioUrl = await storageService.uploadGenericFile(
        destination, 
        bytes,
        metadata: SettableMetadata(contentType: 'audio/m4a'),
      );

      if (widget.clanId != null) {
        await ref.read(clanRepositoryProvider).sendClanMessage(
              clanId: widget.clanId!,
              senderId: user.id,
              senderName: user.username,
              audioUrl: audioUrl,
              type: 'audio',
            );
      } else if (widget.friendId != null) {
        await ref.read(valerionRepositoryProvider).sendPrivateMessage(
              fromId: user.id,
              toId: widget.friendId!,
              senderName: user.username,
              audioUrl: audioUrl,
              type: 'audio',
            );
      }
    } catch (e) {
      debugPrint("❌ [_uploadAndSendVoiceMessage] Erreur: $e");
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains("BLOCK_DELETED")) {
          final cleanMsg = errorStr.split("BLOCK_DELETED:").last.replaceAll("Exception: ", "").trim();
          _showDeletedBlockDialog(cleanMsg);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Oups, erreur d'envoi vocal : $e")),
          );
        }
      }
    } finally {
      // 3. Purge du message optimiste
      if (mounted) {
        setState(() {
          _localOptimisticQueue.removeWhere((m) => m.id == optimisticId);
        });
      }
    }
  }

  // ==========================================
  // EXTENSION CHAT: PHOTOS ET VIDÉOS 24H
  // ==========================================

  Future<void> _showAttachmentPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text("Prendre une photo", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhotos(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("Photos (Galerie)", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhotos(ImageSource.gallery, multiple: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.redAccent),
                title: const Text("Vidéoclip (15s max)", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendPhotos(ImageSource source, {bool multiple = false}) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      final List<XFile> pickedFiles = [];
      if (multiple) {
        final picked = await _picker.pickMultiImage(imageQuality: 70);
        pickedFiles.addAll(picked);
      } else {
        final picked = await _picker.pickImage(source: source, imageQuality: 70);
        if (picked != null) pickedFiles.add(picked);
      }

      if (pickedFiles.isEmpty) return;

      // 1. Ajouter les messages optimistes immédiatement
      final List<String> optimisticIds = [];
      setState(() {
        for (var file in pickedFiles) {
          final optId = "opt_img_${DateTime.now().millisecondsSinceEpoch}_${file.name}";
          optimisticIds.add(optId);
          _localOptimisticQueue.add(ClanMessageEntity(
            id: optId,
            clanId: widget.clanId ?? "private",
            senderId: user.id,
            senderName: user.username,
            imageUrl: file.path, 
            type: 'image',
            timestamp: DateTime.now(),
            isOptimistic: true,
          ));
        }
      });

      // 2. Traitement en arrière-plan (Upload + Firestore)
      for (int i = 0; i < pickedFiles.length; i++) {
        _processSinglePhotoUpload(pickedFiles[i], optimisticIds[i], user);
      }
    } catch (e) {
      debugPrint("❌ [_pickAndSendPhotos] Erreur: $e");
    }
  }

  Future<void> _processSinglePhotoUpload(XFile file, String optId, UserEntity user) async {
    try {
      final bytes = await file.readAsBytes();
      final storageService = ref.read(storageServiceProvider);
      
      String storeId = widget.clanId ?? "";
      if (widget.friendId != null) {
        final List<String> ids = [user.id, widget.friendId!];
        ids.sort();
        storeId = ids.join('_');
      }

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
      final destination = "chat_ephemeral/$storeId/$fileName";
      
      final imageUrl = await storageService.uploadGenericFile(
        destination, 
        bytes,
        metadata: SettableMetadata(contentType: 'image/jpeg'),
      );

      if (widget.clanId != null) {
        await ref.read(clanRepositoryProvider).sendClanMessage(
              clanId: widget.clanId!,
              senderId: user.id,
              senderName: user.username,
              imageUrl: imageUrl,
              type: 'image',
            );
      } else if (widget.friendId != null) {
        await ref.read(valerionRepositoryProvider).sendPrivateMessage(
              fromId: user.id,
              toId: widget.friendId!,
              senderName: user.username,
              imageUrl: imageUrl,
              type: 'image',
            );
      }
    } catch (e) {
      debugPrint("❌ [_processSinglePhotoUpload] Erreur: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'envoi d'une photo: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _localOptimisticQueue.removeWhere((m) => m.id == optId);
        });
      }
    }
  }

  Future<void> _pickAndSendVideo() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      // --- APPEL DE L'ALPHA CAMERA (Custom Recording) ---
      final XFile? picked = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AlphaCameraScreen()),
      );

      if (picked == null) return;

      // --- OPTIMISATION ALPHA (Compression) ---
      setState(() {
        _isCompressing = true;
        _compressionProgress = 0;
      });
      
      final subscription = _smartVideoService.compressionProgress.listen((progress) {
        if (mounted) setState(() => _compressionProgress = progress);
      });

      final compressedFile = await _smartVideoService.processAndCompress(picked.path);
      subscription.cancel();
      
      if (mounted) setState(() => _isCompressing = false);

      if (compressedFile == null) return;

      // --- OPTIMISTIC UI : AFFICHAGE IMMÉDIAT ---
      final optimisticId = "opt_vid_${DateTime.now().millisecondsSinceEpoch}";
      setState(() {
        _localOptimisticQueue.add(ClanMessageEntity(
          id: optimisticId,
          clanId: widget.clanId ?? "private",
          senderId: user.id,
          senderName: user.username,
          videoUrl: compressedFile.path, // Chemin local
          type: 'video',
          timestamp: DateTime.now(),
          isOptimistic: true,
        ));
      });

      // --- BACKGROUND UPLOAD & SYNC ---
      await _processVideoUploadAndSync(compressedFile, optimisticId, user);

    } catch (e) {
      debugPrint("❌ [_pickAndSendVideo] Erreur: $e");
    }
  }

  Future<void> _processVideoUploadAndSync(File compressedFile, String optId, UserEntity user) async {
    try {
      final bytes = await compressedFile.readAsBytes();
      final storageService = ref.read(storageServiceProvider);
      
      String storeId = widget.clanId ?? "";
      if (widget.friendId != null) {
        final ids = [user.id, widget.friendId!];
        ids.sort();
        storeId = ids.join('_');
      }

      final fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
      final destination = "chat_media/$storeId/$fileName";

      final videoUrl = await storageService.uploadGenericFile(
        destination, 
        bytes,
        metadata: SettableMetadata(contentType: 'video/mp4'),
      );

      if (widget.clanId != null) {
        await ref.read(clanRepositoryProvider).sendClanMessage(
              clanId: widget.clanId!,
              senderId: user.id,
              senderName: user.username,
              videoUrl: videoUrl,
              type: 'video',
            );
      } else if (widget.friendId != null) {
        await ref.read(valerionRepositoryProvider).sendPrivateMessage(
              fromId: user.id,
              toId: widget.friendId!,
              senderName: user.username,
              videoUrl: videoUrl,
              type: 'video',
            );
      }
    } catch (e) {
      debugPrint("❌ [_processVideoUploadAndSync] Erreur: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Oups, échec de l'envoi vidéo : $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _localOptimisticQueue.removeWhere((m) => m.id == optId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeData.estimateBrightnessForColor(widget.surfaceColor) == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // Toujours sombre dans le chat
      appBar: AppBar(
        title: Text(
          widget.chatName,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: widget.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.accentColor),
        actions: [
          if (widget.friendId != null)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Profil",
              onPressed: () async {
                final userAsync = ref.read(otherUserProfileProvider(widget.friendId!));
                final user = userAsync.valueOrNull;
                
                if (user != null) {
                  showDialog(
                    context: context,
                    builder: (context) => PublicProfileDialog(
                      user: user,
                      accentColor: widget.accentColor,
                    ),
                  );
                } else {
                  // Si pas encore chargé, on le force
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chargement du profil...")),
                  );
                  final fetchedUser = await ref.read(otherUserProfileProvider(widget.friendId!).future);
                  if (mounted && fetchedUser != null) {
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => PublicProfileDialog(
                        user: fetchedUser,
                        accentColor: widget.accentColor,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child:
                      (widget.clanId == null && widget.friendId == null && !widget.isSystem)
                          ? const Center(
                            child: Text(
                              "Chat indisponible (Mockup)",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                          : _buildMessageList(),
                ),
                if (!widget.isSystem) _buildMessageInputBox(),
              ],
            ),
            if (_isCompressing || _isUploadingMedia)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.cyanAccent),
                        const SizedBox(height: 20),
                        Text(
                          _isCompressing 
                            ? "OPTIMISATION ALPHA... ${(_compressionProgress * 100).toInt()}%"
                            : "TRANSMISSION SÉCURISÉE...",
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Codage H.264 & Réduction Bitrate",
                          style: TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ClanMessageEntity msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Effacer définitivement ?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          "Ce message sera supprimé pour tout le monde et sera irrécupérable dans la base de données.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (widget.clanId != null) {
                  await ref.read(clanRepositoryProvider).deleteClanMessage(
                    widget.clanId!,
                    msg.id,
                    audioUrl: msg.audioUrl,
                  );
                } else if (widget.friendId != null) {
                  // Déterminer l'ID du chat privé
                  final currentUser = ref.read(userProfileProvider).valueOrNull;
                  if (currentUser != null) {
                    final ids = [currentUser.id, widget.friendId!]..sort();
                    final chatId = ids.join('_');
                    await ref.read(valerionRepositoryProvider).deletePrivateMessage(
                      chatId,
                      msg.id,
                      audioUrl: msg.audioUrl,
                    );
                  }
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Message effacé définitivement.")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Échec de la suppression : $e")),
                  );
                }
              }
            },
            child: const Text("EFFACER", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messagesStream =
        widget.isSystem
            ? ref.watch(systemAnnouncementsProvider)
            : widget.clanId != null
            ? ref.watch(clanMessagesProvider(widget.clanId!))
            : ref.watch(privateMessagesProvider(widget.friendId!));

    return messagesStream.when(
      data: (firestoreMessages) {
        // 1. Fusionner les messages Firestore avec les messages optimistes locaux
        // On filtre les messages optimistes dont l'ID est déjà présent dans Firestore (confirmés)
        final Map<String, ClanMessageEntity> combinedMap = {};
        
        // Ajouter les messages optimistes d'abord
        for (var m in _localOptimisticQueue) {
          combinedMap[m.id] = m;
        }
        
        // Les messages Firestore écrasent les messages optimistes avec le même ID (confirmation)
        for (var m in firestoreMessages) {
          combinedMap[m.id] = m;
        }

        final List<ClanMessageEntity> allMessages = combinedMap.values.toList();
        
        // Trier par timestamp décroissant (pour reverse: true)
        allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (allMessages.isEmpty) {
          return const Center(
            child: Text(
              "Début de la conversation sécurisée alpha.",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          );
        }

        final currentUser = ref.read(userProfileProvider).valueOrNull;

        return ListView.builder(
          reverse:
              true, // Affiche les messages du plus récent au plus ancien en bas
          padding: const EdgeInsets.all(20),
          itemCount: allMessages.length,
          itemBuilder: (context, index) {
            final msg = allMessages[index];
            final isMe = currentUser?.id == msg.senderId;

            return Opacity(
              opacity: msg.isOptimistic ? 0.6 : 1.0,
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                onLongPress: () => _showDeleteConfirmation(msg),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? widget.accentColor.withValues(alpha: 0.25)
                            : const Color(0xFF1A1A2E), // Toujours sombre, jamais blanc
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          isMe
                              ? const Radius.circular(0)
                              : const Radius.circular(16),
                      bottomLeft:
                          !isMe
                              ? const Radius.circular(0)
                              : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color:
                          isMe
                              ? widget.accentColor.withValues(alpha: 0.5)
                              : Colors.white12,
                    ),
                  ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        msg.senderName,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    if (!isMe) const SizedBox(height: 4),
                    if (msg.type == 'audio' && msg.audioUrl != null)
                      AudioMessageBubble(
                        audioUrl: msg.audioUrl!,
                        isMe: isMe,
                        accentColor: widget.accentColor,
                        timestamp: msg.timestamp,
                      )
                    else if (msg.type == 'image' && msg.imageUrl != null)
                      Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                          child: msg.imageUrl!.startsWith('http') 
                            ? CachedNetworkImage(
                                imageUrl: msg.imageUrl!,
                                width: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                              )
                            : Image.file(
                                File(msg.imageUrl!),
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                              ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(top: 4),
                            icon: const Icon(Icons.download, size: 20, color: Colors.white54),
                            tooltip: "Enregistrer dans la pellicule",
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Téléchargement de la photo...")));
                                final hasAccess = await Gal.hasAccess();
                                if (!hasAccess) await Gal.requestAccess();
                                final tempDir = await getTemporaryDirectory();
                                final savePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final res = await http.get(Uri.parse(msg.imageUrl!));
                                await File(savePath).writeAsBytes(res.bodyBytes);
                                await Gal.putImage(savePath);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo enregistrée ! ✅")));
                                }
                              } catch (e) {
                                debugPrint("❌ Erreur téléchargement Image: $e");
                              }
                            },
                          ),
                        ],
                      )
                    else if (msg.type == 'video' && msg.videoUrl != null)
                      VideoMessageBubble(
                        videoUrl: msg.videoUrl!,
                        isMe: isMe,
                        accentColor: widget.accentColor,
                      )
                    else
                      ClickableText(
                        text: msg.text ?? "",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: isMe ? TextAlign.end : TextAlign.start,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
          },
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
      error:
          (e, s) => Center(
            child: Text(
              "Erreur: $e",
              style: const TextStyle(color: Colors.red),
            ),
          ),
    );
  }

  Widget _buildMessageInputBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), // Toujours sombre pour que le texte blanc soit lisible
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isUploadingMedia
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
            color: widget.accentColor,
            onPressed: _isUploadingMedia ? null : _showAttachmentPicker,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Transmettre un message...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            color: _isRecording ? Colors.redAccent : widget.accentColor,
            onPressed: () {
              if (_isRecording) {
                _stopAndSendRecording();
              } else {
                _startRecording();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: widget.accentColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ALPHA CONNECT : PROFIL PUBLIC
// ==========================================

class PublicProfileDialog extends ConsumerWidget {
  final UserEntity user;
  final Color accentColor;

  const PublicProfileDialog({
    super.key,
    required this.user,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar & Name
            AvatarViewer(
              imageUrl: user.profileImageUrl,
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1,
              ),
            ),
            if (user.clanIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Membre de ${user.clanIds.length} Clan(s)",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Main Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBadge("NIVEAU", user.level.toString(), Colors.white),
                _buildStatBadge("XP TOTAL", user.xp.toString(), accentColor),
                _buildStatBadge(
                  "SÉRIE",
                  "${user.streak} J",
                  Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // Detailed Stats (Force / Sagesse / Records)
            _buildDetailRow(
              Icons.fitness_center,
              "XP Force (Dojo)",
              user.forceXp.toString(),
              Colors.redAccent,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.directions_run,
              "XP Sagesse (Arène)",
              user.wisdomXp.toString(),
              Colors.cyanAccent,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.star,
              "Record Pompes",
              user.maxPushups.toString(),
              Colors.yellowAccent,
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("FERMER"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Logique d'invitation : si je suis leader d'un clan, je peux recruter
                      final currentUser = ref.read(userProfileProvider).value;
                      final myClans = ref.read(userClansProvider).value ?? [];

                      if (currentUser == null) return;
                      // Trouver le premier clan dont je suis leader
                      final myLedClan =
                          myClans
                              .where((c) => c.leaderId == currentUser.id)
                              .firstOrNull;

                      if (myLedClan != null) {
                        try {
                          await ref
                              .read(clanRepositoryProvider)
                              .sendClanInvitation(
                                clan: myLedClan,
                                targetUserId: user.id,
                                targetUsername: user.username,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Invitation envoyée à ${user.username} !",
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Impossible d'envoyer l'invitation: $e",
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        // Sinon simple info
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Vous devez être chef pour recruter.",
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "RECRUTER / AMIS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Supprimer Ami (si déjà ami)
            Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(userProfileProvider).valueOrNull;
                final isFriend = currentUser?.friendIds.contains(user.id) ?? false;
                
                if (!isFriend) return const SizedBox.shrink();
                
                return SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ids = [currentUser!.id, user.id]..sort();
                      final chatId = ids.join('_');
                      
                      final purgeHistory = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          title: const Text("Retirer des amis ?", style: TextStyle(color: Colors.white)),
                          content: const Text(
                            "Voulez-vous également effacer définitivement tout l'historique de votre conversation ?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("GARDER CHAT", style: TextStyle(color: Colors.white38)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("EFFACER TOUT", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );

                      if (purgeHistory != null) {
                        try {
                          if (purgeHistory) {
                            await ref.read(valerionRepositoryProvider).deletePrivateChatHistory(chatId);
                          }
                          await ref.read(valerionRepositoryProvider).removeFriend(currentUser.id, user.id);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${user.username} a été retiré de vos amis.")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur : $e")),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 18),
                    label: const Text(
                      "RETIRER DE MES AMIS",
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ECRAN DE MODERATION CLAN (BANNISSEMENT)
// ==========================================

class ClanMembersScreen extends ConsumerStatefulWidget {
  final ClanEntity clan;
  final String currentUserId;
  final Color surfaceColor;
  final Color accentColor;

  const ClanMembersScreen({
    super.key,
    required this.clan,
    required this.currentUserId,
    required this.surfaceColor,
    required this.accentColor,
  });

  @override
  ConsumerState<ClanMembersScreen> createState() => _ClanMembersScreenState();
}

class _ClanMembersScreenState extends ConsumerState<ClanMembersScreen> {
  // Mémorise les membres chargés (Map = userId -> infos brutes)
  List<dynamic>? _members;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await ref
          .read(clanRepositoryProvider)
          .getClanMembers(widget.clan.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de récupération : $e")));
      }
    }
  }

  void _kickMember(String memberId, String memberName) async {
    // S'assurer de ne pas se bannir soi-même
    if (memberId == widget.clan.leaderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le créateur ne peut pas être banni.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "Bannissement",
              style: TextStyle(color: Colors.redAccent),
            ),
            content: Text(
              "Voulez-vous vraiment bannir $memberName de ${widget.clan.name} ?",
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "ANNULER",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "BANNIR",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(clanRepositoryProvider)
            .kickMember(clanId: widget.clan.id, userId: memberId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$memberName a été banni.")));
        }
        _loadMembers(); // Rafraichissement
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeData.estimateBrightnessForColor(widget.surfaceColor) == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final textDimColor = isLight ? Colors.black54 : Colors.white54;

    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      appBar: AppBar(
        title: Text(
          "Membres de ${widget.clan.name}",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: widget.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.accentColor),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                )
                : _members == null || _members!.isEmpty
                ? const Center(
                  child: Text(
                    "Aucun membre trouvé.",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members!.length,
                  itemBuilder: (context, index) {
                    final m = _members![index];
                    final isLeader = m['id'] == widget.clan.leaderId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLeader ? widget.accentColor : (isLight ? Colors.black12 : Colors.white10),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isLight ? Colors.black12 : Colors.white10,
                            child: Icon(
                              Icons.person,
                              color:
                                  isLeader
                                      ? widget.accentColor
                                      : textDimColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m['username'] ?? "Soldat Inconnu",
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight:
                                            isLeader
                                                ? FontWeight.w900
                                                : FontWeight.bold,
                                      ),
                                    ),
                                    if (isLeader) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.star,
                                        color: Colors.orangeAccent,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  "Niv. ${m['level'] ?? '?'} • ${m['xp'] ?? '?'} XP",
                                  style: TextStyle(
                                    color: textDimColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bouton d'action: Seul le leader peut bannir, et on ne peut pas bannir le leader
                          if (widget.clan.leaderId == widget.currentUserId &&
                              !isLeader)
                            IconButton(
                              icon: const Icon(Icons.person_remove),
                              color: Colors.redAccent,
                              tooltip: "Bannir",
                              onPressed:
                                  () => _kickMember(
                                    m['id'],
                                    m['username'] ?? "Inconnu",
                                  ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

// ==========================================
// ALPHA CONNECT : DÉTAILS DU CLAN (LE JOIN)
// ==========================================

class ClanDetailsDialog extends ConsumerWidget {
  final ClanEntity clan;
  final Color accentColor;

  const ClanDetailsDialog({
    super.key,
    required this.clan,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isMember = user?.clanIds.contains(clan.id) ?? false;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar & Name
            AvatarViewer(
              imageUrl: clan.logoUrl,
              radius: 40,
              borderColor: accentColor,
              fallbackIcon: Icons.shield,
            ),
            const SizedBox(height: 16),
            Text(
              clan.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              clan.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBadge("XP TOTAL", clan.totalXp.toString(), accentColor),
                _buildStatBadge(
                  "MEMBRES",
                  clan.membersCount.toString(),
                  Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("FERMER"),
                  ),
                ),
                if (!isMember) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (user == null) return;
                        try {
                          await ref.read(clanRepositoryProvider).requestToJoinClan(
                            clan: clan,
                            userId: user.id,
                            username: user.username,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Demande d'adhésion envoyée !"),
                                backgroundColor: Colors.greenAccent,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur: $e")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "REJOINDRE",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
