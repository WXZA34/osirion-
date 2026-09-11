import 'package:valerion/l10n/app_localizations.dart';
// OSIRION - PANTHEON ALPHA MODULE
import '../../l10n/app_localizations.dart';
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
import '../../core/constants/default_relics.dart';
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
import '../duel/screens/live_duel_screen.dart';

class PantheonScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  PantheonScreen({
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
        SnackBar(content: Text(AppLocalizations.of(context)!.pantheonUploadDuLogoEn)),
      );

      final bytes = await pickedFile.readAsBytes();
      final storageService = ref.read(storageServiceProvider);
      final clanRepo = ref.read(clanRepositoryProvider);

      final downloadUrl = await storageService.uploadClanLogo(clan.id, bytes);
      await clanRepo.updateClanLogo(clan.id, downloadUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pantheonLogoDuClanMis),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commonError(e.toString())),
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
    final Color accentColor = isSummer ? arc.primaryColor : Color(0xFFFFD700);
    final Color surfaceColor = arc.surfaceColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.pantheonLePanthOn,
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
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
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
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          _buildNavTab(2, AppLocalizations.of(context)!.pantheonTabClassements, Icons.emoji_events, accentColor, arc, isSummer),
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
            SizedBox(height: 4),
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
        return SizedBox.shrink();
    }
  }

  // --- Tab 0: Alpha Connect (Messagerie) ---
  Widget _buildConnectTab(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return Column(
      key: ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Statut Personnel Actuel
        _buildAlphaStatusPanel(surfaceColor, accentColor, arc, isSummer, onSurfaceColor),
        SizedBox(height: 24),

        // 2. Gestion des Demandes d'Amis
        _buildFriendRequestsSection(accentColor),

        // Cercle de Confiance (Amis)
        _buildSectionTitle("CERCLE DE CONFIANCE", Icons.group, accentColor),
        SizedBox(height: 16),
        _buildHorizontalFriendsList(accentColor),
        SizedBox(height: 24),

        // Discussions Actives
        _buildSectionTitle("TRANSMISSIONS", Icons.forum, accentColor),
        SizedBox(height: 16),
        _buildChatList(surfaceColor, accentColor, arc, isSummer, onSurfaceColor),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8),
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
            if (requests.isEmpty) return SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  "DEMANDES ALPHA",
                  Icons.person_add,
                  Colors.cyanAccent,
                ),
                SizedBox(height: 16),
                ...requests.map(
                  (req) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
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
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            req.username,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
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
                          icon: Icon(
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
                SizedBox(height: 24),
              ],
            );
          },
          loading: () => SizedBox.shrink(),
          error: (_, __) => SizedBox.shrink(),
        );
  }

  Widget _buildAlphaStatusPanel(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    if (user == null) return SizedBox.shrink();

    Color statusColor;
    String statusText = user.status ?? "online";

    switch (statusText.toLowerCase()) {
      case 'online':
      case 'disponible':
        statusColor = Colors.greenAccent;
        statusText = AppLocalizations.of(context)!.pantheonStatusDisponible;
        break;
      case 'in_dojo':
      case 'in_arena':
      case 'en plein effort':
        statusColor = Colors.orangeAccent;
        statusText = AppLocalizations.of(context)!.pantheonStatusEnPleinEffort;
        break;
      case 'offline':
      case 'hors ligne':
      case 'en repos':
        statusColor = Colors.grey;
        statusText = AppLocalizations.of(context)!.pantheonStatusEnRepos;
        break;
      case 'ne pas déranger':
      case 'do not disturb':
        statusColor = Colors.redAccent;
        statusText = AppLocalizations.of(context)!.pantheonStatusNePasDeranger;
        break;
      default:
        statusColor = Colors.cyanAccent;
    }

    return Container(
      padding: EdgeInsets.all(16),
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
              SizedBox(width: 12),
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: Size(60, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.commonModify, style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, String currentStatus) {
    final statuses = [
      {"label": AppLocalizations.of(context)!.pantheonStatusDisponible, "value": "online", "color": Colors.greenAccent},
      {
        "label": AppLocalizations.of(context)!.pantheonStatusEnPleinEffort,
        "value": "in_dojo",
        "color": Colors.orangeAccent,
      },
      {"label": AppLocalizations.of(context)!.pantheonStatusEnRepos, "value": "offline", "color": Colors.grey},
      {
        "label": AppLocalizations.of(context)!.pantheonStatusNePasDeranger,
        "value": "ne pas déranger",
        "color": Colors.redAccent,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF111115),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.pantheonChangerVotreStatut,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 24),
              ...statuses.map(
                (s) => ListTile(
                  leading: CircleAvatar(
                    radius: 6,
                    backgroundColor: s['color'] as Color,
                  ),
                  title: Text(
                    s['label'] as String,
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing:
                      currentStatus == s['value']
                          ? Icon(Icons.check, color: Colors.cyanAccent)
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
                    padding: EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PantheonChatScreen(
                                  chatName: friend.username,
                                  friendId: friend.id,
                                  surfaceColor: Color(
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
                                    color: Color(0xFF111115),
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
                                    
                                    if (score == 0) return SizedBox.shrink();
                                    
                                    return Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Color(0xFF111115), width: 2),
                                        ),
                                        child: Text(
                                          score.toString(),
                                          style: TextStyle(
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
                          SizedBox(height: 8),
                          Text(
                            friend.username,
                            style: TextStyle(
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
              () => SizedBox(
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
                    style: TextStyle(
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
          SizedBox(height: 8),
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
        SizedBox(height: 12),

        // Section Clans
        clansAsync.when(
          data: (clans) {
            if (clans.isEmpty) return SizedBox.shrink();
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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
          loading: () => SizedBox.shrink(),
          error: (e, s) => SizedBox.shrink(),
        ),

        // Section Amis
        friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) return SizedBox.shrink();
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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
          loading: () => SizedBox.shrink(),
          error: (e, s) => SizedBox.shrink(),
        ),

        // Message si rien
        if (clansAsync.valueOrNull?.isEmpty == true &&
            friendsAsync.valueOrNull?.isEmpty == true)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                AppLocalizations.of(context)!.pantheonAucunCanalActifNrejoignez,
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
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
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
            SizedBox(width: 16),
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
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (isAudio) ...[
                        Icon(Icons.mic, color: Colors.cyan, size: 14),
                        SizedBox(width: 4),
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
                SizedBox(height: 8),
                if (hasUnread)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadScore.toString(),
                      style: TextStyle(
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
              backgroundColor: Color(0xFF111115),
              title: Text(AppLocalizations.of(context)!.pantheonRechercherUnAlpha,
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
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Pseudo...",
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: () => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (searchQuery.length >= 3)
                    SizedBox(
                      height: 200,
                      width: double.maxFinite,
                      child: ref
                          .watch(userSearchProvider(searchQuery))
                          .when(
                            data: (users) {
                              if (users.isEmpty) {
                                return Center(child: Text(AppLocalizations.of(context)!.pantheonAucunAlphaTrouv,
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
                                    return SizedBox.shrink();
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
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Niveau ${user.level}",
                                      style: TextStyle(
                                        color: Colors.white38,
                                      ),
                                    ),
                                    trailing:
                                        isAlreadyFriend
                                            ? Icon(
                                              Icons.check_circle,
                                              color: Colors.greenAccent,
                                            )
                                            : isPending
                                            ? Text(AppLocalizations.of(context)!.pantheonEnAttente,
                                              style: TextStyle(
                                                color: Colors.white24,
                                                fontSize: 10,
                                              ),
                                            )
                                            : IconButton(
                                              icon: Icon(
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
                                () => Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error: (e, s) => Text(AppLocalizations.of(context)!.commonError(e.toString())),
                          ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
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
  // --- Tab 3: Domination Urbaine (Spots) ---
  Widget _buildDominationSpots(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return SingleChildScrollView(
      key: ValueKey(3),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 80, bottom: 40, left: 16, right: 16),
      child: Column(
        children: [
          _buildDominationCard(
            title: "LE DUEL",
            subtitle: "Entraînement Rapide",
            description: "Affrontez un adversaire ou un fantôme. Système de handicap actif.",
            icon: Icons.sports_mma,
            color: Colors.amber,
            onTap: () => _showExerciseSelector(context, "duel", Colors.amber),
          ),
          const SizedBox(height: 16),
          _buildDominationCard(
            title: "LA LIGUE",
            subtitle: "Mode Classé (Ranked)",
            description: "Compétition pure. Zéro handicap. Gravissez les échelons.",
            icon: Icons.emoji_events,
            color: Colors.cyanAccent,
            onTap: () => _showExerciseSelector(context, "ligue", Colors.cyanAccent),
          ),
          const SizedBox(height: 16),
          _buildDominationCard(
            title: "LE RAID MONDIAL",
            subtitle: "Événement Communautaire",
            description: "Abattez le Boss ensemble. (Bientôt disponible)",
            icon: Icons.fort,
            color: Colors.deepOrangeAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Le Raid Mondial sera bientôt disponible !")),
              );
            },
            isLocked: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDominationCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? color.withOpacity(0.05) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked ? color.withOpacity(0.3) : color.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: isLocked ? null : [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isLocked ? Colors.grey : color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: TextStyle(
                      color: isLocked ? Colors.grey : color.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: isLocked ? Colors.grey : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: isLocked ? Colors.grey : Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 12),
              const Icon(Icons.lock, color: Colors.grey, size: 24),
            ] else ...[
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: color, size: 28),
            ]
          ],
        ),
      ),
    );
  }

  void _showExerciseSelector(BuildContext context, String modeId, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F111A), // Dark surface
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "SÉLECTIONNEZ VOTRE EXERCICE",
                style: TextStyle(
                  color: themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExerciseOption(context, "Pompes", "pushups", Icons.fitness_center, themeColor, modeId),
                  _buildExerciseOption(context, "Squats", "squats", Icons.accessibility_new, themeColor, modeId),
                  _buildExerciseOption(context, "Abdos", "situps", Icons.airline_seat_flat, themeColor, modeId),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseOption(BuildContext context, String label, String type, IconData icon, Color color, String modeId) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        final demoDuelId = "duel_\${modeId}_\${DateTime.now().millisecondsSinceEpoch}";
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveDuelScreen(
              duelId: demoDuelId,
              opponentId: "opponent_bot_123", // Utilisateur factice pour le moment
              exerciseType: type,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Le Panthéon (Classements) ---
  Widget _buildLeaderboards(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    return Column(
      key: ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête Filtres
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              AppLocalizations.of(context)!.pantheonLesImmortels,
              Icons.emoji_events,
              accentColor,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.pantheonMondial,
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
        SizedBox(height: 16),

        // Clan Search Bar (Only for Clans Tab)
        if (_currentSortBy == 'clans') ...[
          TextField(
            style: TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.pantheonRechercherUneFaction,
              hintStyle: TextStyle(color: Colors.white24),
              prefixIcon: Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _clanSearchQuery = val;
              });
            },
          ),
          SizedBox(height: 16),
        ],

        // Category Selector (Les 3 Piliers)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  {'label': AppLocalizations.of(context)!.pantheonAlphaSupreme, 'value': 'xp'},
                  {'label': AppLocalizations.of(context)!.pantheonMaitresDuDojo, 'value': 'forceXp'},
                  {
                    'label': AppLocalizations.of(context)!.pantheonSagesArN,
                    'value': 'wisdomXp',
                  },
                  {'label': AppLocalizations.of(context)!.pantheonFactionsTopClans, 'value': 'clans'},
                ].map((cat) {
                  bool isSelected = _currentSortBy == cat['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentSortBy = cat['value']!;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(
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
        SizedBox(height: 24),

        // Podiums & Leaderboard List via Riverpod
        if (_currentSortBy == 'clans')
          _buildClansLeaderboardView(surfaceColor, accentColor, arc, isSummer, onSurfaceColor)
        else
          ref
              .watch(leaderboardProvider(_currentSortBy))
              .when(
                data: (users) {
                  if (users.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.pantheonAucunImmortelTrouv,
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
                        SizedBox(height: 24),
                        _buildSectionTitle(AppLocalizations.of(context)!.pantheonVotrePosition, Icons.person_pin_circle, accentColor),
                        SizedBox(height: 12),
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
                          loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => SizedBox.shrink(),
                        ),
                      ],
                    ],
                  );
                },
                loading:
                    () => Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    ),
                error:
                    (err, stack) => Center(
                      child: Text(
                        "Erreur de connexion aux archives: $err",
                        style: TextStyle(color: Colors.redAccent),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isUser ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.white10)),
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
            SizedBox(width: 12),
            AvatarViewer(
              imageUrl: user.profileImageUrl,
              radius: 16,
              enableFullScreen: true,
              fallbackIcon: Icons.person,
              borderColor: isUser ? accentColor.withValues(alpha: 0.5) : null,
            ),
            SizedBox(width: 12),
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
                      defaultRelicsToSeed.where((r) => r.id == user.activeTitle).firstOrNull?.name ?? "",
                      style: TextStyle(
                        color: defaultRelicsToSeed.where((r) => r.id == user.activeTitle).firstOrNull?.color.withValues(alpha: 0.7) ?? Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              scoreStr,
              style: TextStyle(
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
            if (user == null) return SizedBox.shrink();

            return Column(
              key: ValueKey("ClansTab"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildClanInvitationsSection(surfaceColor, accentColor),
                _buildUserClansSection(user, surfaceColor, accentColor, arc, isSummer),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.add_moderator),
                  label: Text(AppLocalizations.of(context)!.pantheonFonderUnNouveauClan,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 20),
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
              () => Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
          error:
              (e, s) => Center(
                child: Text(
                  "Erreur: $e",
                  style: TextStyle(color: Colors.red),
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
            if (requests.isEmpty) return SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  AppLocalizations.of(context)!.pantheonInvitationsRecues,
                  Icons.mail,
                  Colors.orangeAccent,
                ),
                SizedBox(height: 16),
                ...requests
                    .map(
                      (req) => Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield,
                              color: Colors.orangeAccent,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${AppLocalizations.of(context)!.pantheonRejoindre} ${req.clanName}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
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
                              icon: Icon(
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
                SizedBox(height: 32),
              ],
            );
          },
          loading: () => SizedBox.shrink(),
          error:
              (e, s) => Text(
                "Erreur invitations: $e",
                style: TextStyle(color: Colors.red),
              ),
        );
  }

  // --- VUE: LEADERBOARD DES CLANS (CLASSEMENTS) ---
  Widget _buildClansLeaderboardView(Color surfaceColor, Color accentColor, ArcData arc, bool isSummer, Color onSurfaceColor) {
    final clansAsync = _clanSearchQuery.isEmpty
        ? ref.watch(clansLeaderboardProvider)
        : ref.watch(clanSearchProvider(_clanSearchQuery));

    return Column(
      key: ValueKey("ClansLeaderboard"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clansAsync.when(
              data: (clans) {
                if (clans.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.pantheonAucunClanNExiste,
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
                                SizedBox(width: 12),
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
                                            placeholder: (context, url) => Opacity(opacity: 0.5, child: Icon(Icons.shield, size: 20)),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${clan.membersCount} membres",
                              style: TextStyle(color: Colors.white54),
                            ),
                            trailing: Text(
                              "${clan.totalXp} XP",
                              style: TextStyle(
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
                  () => Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
              error:
                  (e, s) => Text(
                    "Erreur: $e",
                    style: TextStyle(color: Colors.red),
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
              return Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.pantheonVousNeFaitesPartie,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, height: 1.5),
                  ),
                ),
              );
            }

            return Column(
              key: ValueKey("MyClansList"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("MES FACTIONS", Icons.shield, accentColor),
                SizedBox(height: 16),
                ...clans.map((clan) {
                  final isLeader = clan.leaderId == user.id;
                  final isLight = ThemeData.estimateBrightnessForColor(surfaceColor) == Brightness.light;
                  final textColor = isLight ? Colors.black87 : Colors.white;
                  final textDimColor = isLight ? Colors.black54 : Colors.white70;

                  return Container(
                    margin: EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header: Clan Name & Stats
                        Container(
                          padding: EdgeInsets.all(24),
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
                                    backgroundColor: Color(0xFF111111),
                                  child: ClipOval(
                                    child: clan.logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: clan.logoUrl!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => SizedBox(width: 80, height: 80, child: CircularProgressIndicator(strokeWidth: 2)),
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
                              SizedBox(height: 12),
                              Text(
                                clan.name.toUpperCase(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                clan.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textDimColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 24),
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
                        SizedBox(height: 16),

                        // Boutons d'Action Rapide pour ce Clan
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.forum, size: 18),
                                label: Text(
                                  "TRANSMISSION",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: surfaceColor,
                                  foregroundColor: textColor,
                                  padding: EdgeInsets.symmetric(
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
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
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
                              child: Icon(Icons.people_alt),
                            ),
                            if (!isLeader) ...[
                              SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white70,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white24),
                                  ),
                                ),
                                onPressed: () => _confirmLeaveClan(context, clan),
                                child: Icon(Icons.exit_to_app),
                              ),
                            ],
                            if (isLeader) ...[
                              SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                onPressed:
                                    () => _confirmDeleteClan(context, clan),
                                child: Icon(Icons.delete_forever),
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
              () => Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
          error:
              (e, s) =>
                  Text("Erreur: $e", style: TextStyle(color: Colors.red)),
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
        SizedBox(height: 4),
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
          backgroundColor: Color(0xFF1E293B), // slate-800
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: accentColor, size: 48),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.pantheonForgerUnNouveauClan,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Nom du Clan",
                    labelStyle: TextStyle(color: Colors.white54),
                    hintText: AppLocalizations.of(context)!.pantheonExLesSpartiatesDu,
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Devise / Description",
                    labelStyle: TextStyle(color: Colors.white54),
                    hintText: "Optionnel",
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 24),
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
                          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppLocalizations.of(context)!.pantheonCrErLeClan,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
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
            backgroundColor: Color(0xFF1E293B),
            title: Text(AppLocalizations.of(context)!.pantheonDissoudreLeClan,
              style: TextStyle(color: Colors.redAccent),
            ),
            content: Text(
              "Êtes-vous sûr de vouloir dissoudre définitivement ${clan.name} ? Cette action est irréversible et retirera le clan de tous ses membres.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Annuler",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pantheonLeClanAT),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commonError(e.toString())),
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
            backgroundColor: Color(0xFF1E293B),
            title: Text(AppLocalizations.of(context)!.pantheonQuitterLeClan,
              style: TextStyle(color: Colors.orangeAccent),
            ),
            content: Text(
              "Voulez-vous vraiment quitter le clan ${clan.name} ? Vous perdrez l'accès au chat et aux bonus de faction.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
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
                child: Text(
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
            content: Text(AppLocalizations.of(context)!.commonError(e.toString())),
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

  PantheonChatScreen({
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
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonError(cleanMsg.toString()))));
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
        backgroundColor: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.pantheonActionRequise, style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.commonClose, style: TextStyle(color: Colors.white38)),
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
                      SnackBar(content: Text(AppLocalizations.of(context)!.pantheonNouvelleDemandeLancE)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
                    );
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.pantheonRInviter, style: TextStyle(fontWeight: FontWeight.bold)),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.pantheonLAccSAu)),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.pantheonPermissionMicroRefusE)),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ [_startRecording] ERREUR FATALE: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
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
      backgroundColor: Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: Text(AppLocalizations.of(context)!.pantheonPrendreUnePhoto, style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhotos(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.greenAccent),
                title: Text(AppLocalizations.of(context)!.pantheonPhotosGalerie, style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhotos(ImageSource.gallery, multiple: true);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: Colors.redAccent),
                title: Text(AppLocalizations.of(context)!.pantheonVidOclip15sMax, style: TextStyle(color: Colors.white)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
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
        MaterialPageRoute(builder: (context) => AlphaCameraScreen()),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
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
      backgroundColor: Color(0xFF0D0D12), // Toujours sombre dans le chat
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
              icon: Icon(Icons.person),
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
                    SnackBar(content: Text(AppLocalizations.of(context)!.pantheonChargementDuProfil)),
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
                          ? Center(child: Text(AppLocalizations.of(context)!.pantheonChatIndisponibleMockup,
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
                        CircularProgressIndicator(color: Colors.cyanAccent),
                        SizedBox(height: 20),
                        Text(
                          _isCompressing 
                            ? "OPTIMISATION ALPHA... ${(_compressionProgress * 100).toInt()}%"
                            : "TRANSMISSION SÉCURISÉE...",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.pantheonCodageH264R,
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
        backgroundColor: Color(0xFF1E293B),
        title: Text(AppLocalizations.of(context)!.pantheonEffacerDFinitivement, style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(AppLocalizations.of(context)!.pantheonCeMessageSeraSupprim,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: Colors.white38)),
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
                    SnackBar(content: Text(AppLocalizations.of(context)!.pantheonMessageEffacDFinitivement)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.commonErase, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
          return Center(child: Text(AppLocalizations.of(context)!.pantheonDButDeLa,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          );
        }

        final currentUser = ref.read(userProfileProvider).valueOrNull;

        return ListView.builder(
          reverse:
              true, // Affiche les messages du plus récent au plus ancien en bas
          padding: EdgeInsets.all(20),
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
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? widget.accentColor.withValues(alpha: 0.25)
                            : Color(0xFF1A1A2E), // Toujours sombre, jamais blanc
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          isMe
                              ? Radius.circular(0)
                              : Radius.circular(16),
                      bottomLeft:
                          !isMe
                              ? Radius.circular(0)
                              : Radius.circular(16),
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
                    if (!isMe) SizedBox(height: 4),
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
                                placeholder: (context, url) => SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                errorWidget: (context, url, error) => Icon(Icons.broken_image, color: Colors.white54, size: 50),
                              )
                            : Image.file(
                                File(msg.imageUrl!),
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.white54, size: 50),
                              ),
                          ),
                          IconButton(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.only(top: 4),
                            icon: Icon(Icons.download, size: 20, color: Colors.white54),
                            tooltip: AppLocalizations.of(context)!.pantheonEnregistrerDansLaPellicule,
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pantheonTLChargementDe)));
                                final hasAccess = await Gal.hasAccess();
                                if (!hasAccess) await Gal.requestAccess();
                                final tempDir = await getTemporaryDirectory();
                                final savePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final res = await http.get(Uri.parse(msg.imageUrl!));
                                await File(savePath).writeAsBytes(res.bodyBytes);
                                await Gal.putImage(savePath);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pantheonPhotoEnregistrE)));
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
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
          () => Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
      error:
          (e, s) => Center(
            child: Text(
              "Erreur: $e",
              style: TextStyle(color: Colors.red),
            ),
          ),
    );
  }

  Widget _buildMessageInputBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.only(bottom: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E), // Toujours sombre pour que le texte blanc soit lisible
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isUploadingMedia
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.add),
            color: widget.accentColor,
            onPressed: _isUploadingMedia ? null : _showAttachmentPicker,
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _msgController,
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.pantheonTransmettreUnMessage,
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
            icon: Icon(Icons.send),
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

  PublicProfileDialog({
    super.key,
    required this.user,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar & Name
            AvatarViewer(
              imageUrl: user.profileImageUrl,
              radius: 40,
            ),
            SizedBox(height: 16),
            Text(
              user.username,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1,
              ),
            ),
            if (user.clanIds.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Membre de ${user.clanIds.length} Clan(s)",
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            SizedBox(height: 24),

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
            SizedBox(height: 24),
            Divider(color: Colors.white10),
            SizedBox(height: 16),

            // Detailed Stats (Force / Sagesse / Records)
            _buildDetailRow(
              Icons.fitness_center,
              "XP Force (Dojo)",
              user.forceXp.toString(),
              Colors.redAccent,
            ),
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.directions_run,
              "XP Sagesse (Arène)",
              user.wisdomXp.toString(),
              Colors.cyanAccent,
            ),
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.star,
              "Record Pompes",
              user.maxPushups.toString(),
              Colors.yellowAccent,
            ),

            SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white24),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.commonClose),
                  ),
                ),
                SizedBox(width: 16),
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
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.pantheonVousDevezTreChef,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.pantheonRecruterAmis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Action Supprimer Ami (si déjà ami)
            Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(userProfileProvider).valueOrNull;
                final isFriend = currentUser?.friendIds.contains(user.id) ?? false;
                
                if (!isFriend) return SizedBox.shrink();
                
                return SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ids = [currentUser!.id, user.id]..sort();
                      final chatId = ids.join('_');
                      
                      final purgeHistory = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Color(0xFF1E293B),
                          title: Text(AppLocalizations.of(context)!.pantheonRetirerDesAmis, style: TextStyle(color: Colors.white)),
                          content: Text(AppLocalizations.of(context)!.pantheonVoulezVousGalementEffacer,
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(AppLocalizations.of(context)!.pantheonGarderChat, style: TextStyle(color: Colors.white38)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(AppLocalizations.of(context)!.pantheonEffacerTout, style: TextStyle(color: Colors.redAccent)),
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
                              SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(Icons.person_remove, color: Colors.redAccent, size: 18),
                    label: Text(AppLocalizations.of(context)!.pantheonRetirerDeMesAmis,
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
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
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
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
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

  ClanMembersScreen({
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
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))));
      }
    }
  }

  void _kickMember(String memberId, String memberName) async {
    // S'assurer de ne pas se bannir soi-même
    if (memberId == widget.clan.leaderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pantheonLeCrAteurNe)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Color(0xFF1E293B),
            title: Text(
              "Bannissement",
              style: TextStyle(color: Colors.redAccent),
            ),
            content: Text(
              "Voulez-vous vraiment bannir $memberName de ${widget.clan.name} ?",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "ANNULER",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
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
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))));
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
      backgroundColor: Color(0xFF111115),
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
                ? Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                )
                : _members == null || _members!.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.pantheonAucunMembreTrouv,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _members!.length,
                  itemBuilder: (context, index) {
                    final m = _members![index];
                    final isLeader = m['id'] == widget.clan.leaderId;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
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
                          SizedBox(width: 16),
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
                                      SizedBox(width: 8),
                                      Icon(
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
                              icon: Icon(Icons.person_remove),
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

  ClanDetailsDialog({
    super.key,
    required this.clan,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isMember = user?.clanIds.contains(clan.id) ?? false;

    return Dialog(
      backgroundColor: Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
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
            SizedBox(height: 16),
            Text(
              clan.name.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              clan.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),

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
            SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white24),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.commonClose),
                  ),
                ),
                if (!isMember) ...[
                  SizedBox(width: 16),
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
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.pantheonDemandeDAdhSion),
                                backgroundColor: Colors.greenAccent,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
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
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
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
