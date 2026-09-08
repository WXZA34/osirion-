import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/providers/library_providers.dart';
import '../../core/providers/repository_providers.dart';
import 'models/relic.dart';
import 'models/relic_localization.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';

class ArsenalScreen extends ConsumerStatefulWidget {
  const ArsenalScreen({super.key});

  @override
  ConsumerState<ArsenalScreen> createState() => _ArsenalScreenState();
}

class _ArsenalScreenState extends ConsumerState<ArsenalScreen> {
  int _selectedTabIndex = 0; // 0: Boutique, 1: Grades, 2: Inventaire
  String _selectedShopFilter = 'TOUS'; // TOUS, HALO, TITLE, BOOST
  bool _isPurchasing = false;

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
          AppLocalizations.of(context)!.arsenalLArsenal,
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
                user?.unlockedTitles ?? [],
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
    List<String> unlockedTitles,
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
            return _buildShopTab(aether, inventory, list, level, unlockedTitles);
          case 1:
            final list = titleMap.values.toList();
            list.sort((a, b) => (a.requiredLevel ?? 0).compareTo(b.requiredLevel ?? 0));
            return _buildLevelTitlesTab(level, title, list);
          case 2:
            // Pour l'inventaire, on utilise tous les types connus
            final allList = [...shopMap.values, ...titleMap.values];
            return _buildInventoryTab(inventory, halo, title, allList, level, unlockedTitles);
          default:
            return const SizedBox.shrink();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildFallbackContent(aether, inventory, level, title, halo, unlockedTitles),
    );
  }

  Widget _buildFallbackContent(int aether, List<String> inventory, int level, String? title, String? halo, List<String> unlockedTitles) {
    switch (_selectedTabIndex) {
      case 0: return _buildShopTab(aether, inventory, arsenalRelics, level, unlockedTitles);
      case 1: return _buildLevelTitlesTab(level, title, levelTitles);
      case 2: return _buildInventoryTab(inventory, halo, title, [...arsenalRelics, ...levelTitles], level, unlockedTitles);
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
                      titleRelic.getLocalizedName(context),
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
                          ? titleRelic.getLocalizedDescription(context)
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
  Widget _buildShopTab(int currentAether, List<String> inventory, List<Relic> list, int userLevel, List<String> unlockedTitles) {
    // Filtrage des éléments
    List<Relic> filteredList = list;
    if (_selectedShopFilter != 'TOUS') {
      filteredList = list.where((r) => r.type.toUpperCase() == _selectedShopFilter).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barre des filtres
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _buildFilterChip('TOUS'),
              const SizedBox(width: 8),
              _buildFilterChip('HALO'),
              const SizedBox(width: 8),
              _buildFilterChip('TITLE'),
              const SizedBox(width: 8),
              _buildFilterChip('BOOST'),
            ],
          ),
        ),
        
        // Grille des reliques
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68, // Ajustement pour correspondre à la capture d'écran
            ),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final relic = filteredList[index];
              final bool isOwned = inventory.contains(relic.id) || 
                                   unlockedTitles.contains(relic.id) || 
                                   (relic.type == 'title' && relic.requiredLevel != null && userLevel >= relic.requiredLevel!);
              return _buildRelicGridCard(relic, isOwned, currentAether);
            },
          ),
        ),
      ],
    );
  }

  String _getFilterTranslation(BuildContext context, String filter) {
    switch (filter) {
      case 'TOUS': return AppLocalizations.of(context)!.arsenalFilterAll;
      case 'HALO': return AppLocalizations.of(context)!.arsenalFilterHalo;
      case 'TITLE': return AppLocalizations.of(context)!.arsenalFilterTitle;
      case 'BOOST': return AppLocalizations.of(context)!.arsenalFilterBoost;
      default: return filter;
    }
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedShopFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedShopFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentTech : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _accentTech : (_isSummer ? Colors.black12 : Colors.white30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, color: _isSummer ? Colors.white : Colors.black, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              _getFilterTranslation(context, label),
              style: TextStyle(
                color: isSelected 
                    ? (_isSummer ? Colors.white : Colors.black) 
                    : (_isSummer ? Colors.black54 : Colors.white70),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelicGridCard(Relic relic, bool isOwned, int currentAether) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceArmory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: relic.color.withValues(alpha: 0.2)),
        boxShadow: [
          if (isOwned)
            BoxShadow(
              color: relic.color.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icône en haut
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: relic.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(relic.icon, color: relic.color, size: 28),
          ),
          
          // Texte au milieu
          Column(
            children: [
              Text(
                relic.getLocalizedName(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _isSummer ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                relic.type.toUpperCase(),
                style: TextStyle(
                  color: relic.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          
          // Bouton en bas
          SizedBox(
            width: double.infinity,
            child: _buildBuyButton(relic, isOwned, currentAether),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton(Relic relic, bool isOwned, int currentAether) {
    if (isOwned) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          AppLocalizations.of(context)!.arsenalOwned,
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
      onPressed: (canAfford && !_isPurchasing) ? () => _confirmPurchase(relic) : null,
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
              AppLocalizations.of(context)!.arsenalBlacksmithPact,
              style: TextStyle(color: _accentPremium),
            ),
            content: Text(
              AppLocalizations.of(context)!.arsenalExchangeAetherFor(relic.cost.toString(), relic.getLocalizedName(context)),
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
                child: Text(AppLocalizations.of(context)!.commonAccept),
              ),
            ],
          ),
    );
  }

  Future<void> _executePurchase(Relic relic) async {
    if (_isPurchasing) return;
    
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final repo = ref.read(valerionRepositoryProvider);
      await repo.buyRelic(user.id, relic.id, relic.cost, relic.type);
      if (mounted) {
        HapticFeedback.heavyImpact();
        _confettiController.play();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.arsenalRelicAcquired(relic.getLocalizedName(context))),
            backgroundColor: relic.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Nettoyage de l'erreur pour une meilleure UX
        if (errorMessage.contains('already-exists')) {
          errorMessage = AppLocalizations.of(context)!.arsenalOwned; // "Possédé"
        } else if (errorMessage.contains('failed-precondition')) {
          errorMessage = "Fonds d'Aether insuffisants.";
        } else {
          errorMessage = errorMessage.replaceAll(RegExp(r'\[.*?\]\s*'), '').replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  // ============== INVENTAIRE ==============
  Widget _buildInventoryTab(
    List<String> inventoryIds,
    String? currentHalo,
    String? currentTitle,
    List<Relic> allRelics,
    int userLevel,
    List<String> unlockedTitles,
  ) {
    // Obtenir les objets possédés : inventory, unlockedTitles, et ceux du niveau
    final ownedRelics = allRelics.where((r) {
      if (inventoryIds.contains(r.id)) return true;
      if (unlockedTitles.contains(r.id)) return true;
      if (r.type == 'title' && r.requiredLevel != null && userLevel >= r.requiredLevel!) return true;
      return false;
    }).toList();

    if (ownedRelics.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.arsenalEmptyInventory,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

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
                      relic.getLocalizedName(context),
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
                ? AppLocalizations.of(context)!.arsenalEquippedSuccess(relic.getLocalizedName(context)) 
                : AppLocalizations.of(context)!.arsenalUnequipped(relic.getLocalizedName(context))
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
