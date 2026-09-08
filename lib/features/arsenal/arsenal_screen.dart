import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/providers/library_providers.dart';
import '../../core/providers/repository_providers.dart';
import 'models/relic.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';

class ArsenalScreen extends ConsumerStatefulWidget {
  const ArsenalScreen({super.key});

  @override
  ConsumerState<ArsenalScreen> createState() => _ArsenalScreenState();
}

class _ArsenalScreenState extends ConsumerState<ArsenalScreen> {
  int _selectedTabIndex = 0; // 0: Boutique, 1: Grades, 2: Inventaire

  // Colors based on Arc theme
  ArcData get _currentArc => ref.watch(arcProvider);
  bool get _isSummer => _currentArc.arcType == AlphaArc.summer;
  Color get _surfaceArmory => _currentArc.surfaceColor;
  Color get _onSurfaceColor => _currentArc.onSurfaceColor;
  final Color _accentPremium = Colors.amber;
  final Color _accentTech = Colors.cyan;
  final Color _aetherColor = Colors.purpleAccent;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écoute de l'utilisateur pour avoir l'Aether et l'Inventaire en temps réel
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.valueOrNull;

    int aetherBalance = user?.aetherBalance ?? 0;
    List<String> userInventory = user?.inventory ?? [];
    String? currentHalo = user?.activeHalo;
    String? currentTitle = user?.activeTitle;

    final mainScaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "L'ARSENAL",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor : Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
            letterSpacing: 4,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _isSummer ? _onSurfaceColor : Colors.white),
        actions: [
          // Affichage de l'Aether
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _aetherColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _aetherColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.diamond, color: _aetherColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  aetherBalance.toString(),
                  style: TextStyle(
                    color: _aetherColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopNavigationBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentTab(
                aetherBalance,
                userInventory,
                user?.level ?? 1,
                currentHalo,
                currentTitle,
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        mainScaffold,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 20,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              Colors.amber,
              Colors.purpleAccent,
              Colors.cyan,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(
    int aether,
    List<String> inventory,
    int level,
    String? halo,
    String? title,
  ) {
    final relicsAsync = ref.watch(relicsProvider);

    return relicsAsync.when(
      data: (firebaseRelics) {
        // Fusion et dédoublonnage
        final Map<String, Relic> shopMap = {};
        for (var r in arsenalRelics) { shopMap[r.id] = r; }
        for (var r in firebaseRelics.where((r) => r.type != 'title' || r.requiredLevel == null)) {
          shopMap[r.id] = r;
        }

        final Map<String, Relic> titleMap = {};
        for (var r in levelTitles) { titleMap[r.id] = r; }
        for (var r in firebaseRelics.where((r) => r.type == 'title' && r.requiredLevel != null)) {
          titleMap[r.id] = r;
        }

        switch (_selectedTabIndex) {
          case 0:
            final list = shopMap.values.toList();
            return _buildShopTab(aether, inventory, list);
          case 1:
            final list = titleMap.values.toList();
            list.sort((a, b) => (a.requiredLevel ?? 0).compareTo(b.requiredLevel ?? 0));
            return _buildLevelTitlesTab(level, title, list);
          case 2:
            // Pour l'inventaire, on utilise tous les types connus
            return _buildInventoryTab(inventory, halo, title);
          default:
            return const SizedBox.shrink();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildFallbackContent(aether, inventory, level, title, halo),
    );
  }

  Widget _buildFallbackContent(int aether, List<String> inventory, int level, String? title, String? halo) {
    switch (_selectedTabIndex) {
      case 0: return _buildShopTab(aether, inventory, arsenalRelics);
      case 1: return _buildLevelTitlesTab(level, title, levelTitles);
      case 2: return _buildInventoryTab(inventory, halo, title);
      default: return const SizedBox.shrink();
    }
  }

  // ============== GRADES (TITRES DE NIVEAU) ==============
  Widget _buildLevelTitlesTab(int userLevel, String? currentTitle, List<Relic> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final titleRelic = list[index];
        final bool isUnlocked = userLevel >= (titleRelic.requiredLevel ?? 1);
        final bool isEquipped = currentTitle == titleRelic.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceArmory,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isUnlocked
                      ? (isEquipped
                          ? titleRelic.color
                          : titleRelic.color.withValues(alpha: 0.3))
                      : (_isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
            ),
            gradient:
                isEquipped
                    ? LinearGradient(
                      colors: [
                        titleRelic.color.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    )
                    : null,
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    titleRelic.icon,
                    color: isUnlocked ? titleRelic.color : Colors.white24,
                    size: 30,
                  ),
                  if (!isUnlocked)
                    const Icon(Icons.lock, color: Colors.white70, size: 16),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleRelic.name,
                      style: TextStyle(
                        color: isUnlocked 
                            ? (_isSummer ? Colors.black87 : Colors.white) 
                            : (_isSummer ? Colors.black26 : Colors.white24),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isUnlocked
                          ? titleRelic.description
                          : AppLocalizations.of(context)!.arsenalUnlockedAtLevel(titleRelic.requiredLevel ?? 0),
                      style: TextStyle(
                        color: isUnlocked 
                            ? (_isSummer ? Colors.black54 : Colors.white54) 
                            : (_isSummer ? Colors.black26 : Colors.white10),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                ElevatedButton(
                  onPressed: isEquipped ? null : () => _equipRelic(titleRelic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped 
                        ? (_isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10) 
                        : _accentTech,
                    foregroundColor: isEquipped 
                        ? (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54) 
                        : Colors.black,
                  ),
                  child: Text(isEquipped ? AppLocalizations.of(context)!.arsenalEquipped : AppLocalizations.of(context)!.arsenalEquip),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceArmory,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _isSummer ? Colors.black12 : Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavTab(0, AppLocalizations.of(context)!.arsenalTheBlacksmith, Icons.storefront, _accentPremium),
          _buildNavTab(1, AppLocalizations.of(context)!.arsenalRanks, Icons.military_tech, Colors.orangeAccent),
          _buildNavTab(2, AppLocalizations.of(context)!.arsenalMyRelics, Icons.backpack, _accentTech),
        ],
      ),
    );
  }

  Widget _buildNavTab(
    int index,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? activeColor 
                    : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected 
                      ? (_isSummer ? _onSurfaceColor : Colors.white) 
                      : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== BOUTIQUE ==============
  Widget _buildShopTab(int currentAether, List<String> inventory, List<Relic> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final relic = list[index];
        final bool isOwned = inventory.contains(relic.id);

        return _buildRelicCard(relic, isOwned, currentAether);
      },
    );
  }

  Widget _buildRelicCard(Relic relic, bool isOwned, int currentAether) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceArmory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: relic.color.withValues(alpha: 0.3)),
        boxShadow: [
          if (isOwned)
            BoxShadow(
              color: relic.color.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: relic.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(relic.icon, color: relic.color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relic.name,
                  style: TextStyle(
                    color: _isSummer ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relic.description,
                  style: TextStyle(
                    color: _isSummer ? Colors.black54 : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${AppLocalizations.of(context)!.arsenalTypePrefix}: ${relic.type.toUpperCase()}",
                  style: TextStyle(
                    color: relic.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildBuyButton(relic, isOwned, currentAether),
        ],
      ),
    );
  }

  Widget _buildBuyButton(Relic relic, bool isOwned, int currentAether) {
    if (isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "POSSÉDÉ",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    bool canAfford = currentAether >= relic.cost;

    return ElevatedButton(
      onPressed: canAfford ? () => _confirmPurchase(relic) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford 
            ? _accentPremium 
            : (_isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.diamond,
            color: canAfford 
                ? Colors.black 
                : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.2) : Colors.white54),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            relic.cost.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: canAfford ? Colors.black : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPurchase(Relic relic) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _surfaceArmory,
            title: Text(
              "Pacte du Forgeron",
              style: TextStyle(color: _accentPremium),
            ),
            content: Text(
              AppLocalizations.of(context)!.arsenalExchangeAetherFor(relic.cost.toString(), relic.name),
              style: TextStyle(
                color: _isSummer ? Colors.black87 : Colors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.commonRefuse,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.6) : Colors.white54
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _executePurchase(relic);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPremium,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Accepter"),
              ),
            ],
          ),
    );
  }

  Future<void> _executePurchase(Relic relic) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      final repo = ref.read(valerionRepositoryProvider);
      await repo.buyRelic(user.id, relic.id, relic.cost, relic.type);
      if (mounted) {
        HapticFeedback.heavyImpact();
        _confettiController.play();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.arsenalRelicAcquired(relic.name)),
            backgroundColor: relic.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de la transaction : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============== INVENTAIRE ==============
  Widget _buildInventoryTab(
    List<String> inventoryIds,
    String? currentHalo,
    String? currentTitle,
  ) {
    if (inventoryIds.isEmpty) {
      return const Center(
        child: Text(
          "Votre sac est vide. Visitez le Forgeron.",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Obtenir les objets possédés
    final ownedRelics =
        arsenalRelics.where((r) => inventoryIds.contains(r.id)).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: ownedRelics.length,
      itemBuilder: (context, index) {
        final relic = ownedRelics[index];
        final bool isEquipped =
            relic.id == currentHalo || relic.id == currentTitle;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceArmory,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEquipped ? _accentPremium : Colors.white10,
            ),
            gradient:
                isEquipped
                    ? LinearGradient(
                      colors: [
                        _accentPremium.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    )
                    : null,
          ),
          child: Row(
            children: [
              Icon(relic.icon, color: relic.color, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relic.name,
                      style: TextStyle(
                        color: _isSummer ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      relic.type.toUpperCase(),
                      style: TextStyle(
                        color: _isSummer ? Colors.black38 : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (relic.type == 'halo' || relic.type == 'title')
                ElevatedButton(
                  onPressed: isEquipped ? null : () => _equipRelic(relic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped 
                        ? (_isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10) 
                        : _accentTech,
                    foregroundColor: isEquipped 
                        ? (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54) 
                        : Colors.black,
                  ),
                  child: Text(isEquipped ? AppLocalizations.of(context)!.arsenalEquipped : AppLocalizations.of(context)!.arsenalEquip),
                )
              else
                Text(AppLocalizations.of(context)!.arsenalConsumable,
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _equipRelic(Relic relic) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    final bool isEquipping = relic.id != (relic.type == 'halo' ? user.activeHalo : user.activeTitle);

    try {
      final repo = ref.read(valerionRepositoryProvider);
      final updatedUser = user.copyWith(
        activeHalo: relic.type == 'halo' 
            ? (user.activeHalo == relic.id ? null : relic.id) 
            : user.activeHalo,
        activeTitle: relic.type == 'title' 
            ? (user.activeTitle == relic.id ? null : relic.id) 
            : user.activeTitle,
      );
      
      await repo.saveUserProfile(updatedUser);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEquipping 
                ? AppLocalizations.of(context)!.arsenalEquippedSuccess(relic.name) 
                : AppLocalizations.of(context)!.arsenalUnequipped(relic.name)
            ),
            backgroundColor: isEquipping ? relic.color : Colors.grey[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.arsenalEquipError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }
}
