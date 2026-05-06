import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../widgets/common_widgets.dart';
import '../../data/models/card_catalog_models.dart';
import '../../data/repositories/card_catalog_repository.dart';

class CardCatalogScreen extends StatefulWidget {
  const CardCatalogScreen({super.key, required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  State<CardCatalogScreen> createState() => _CardCatalogScreenState();
}

class _CardCatalogScreenState extends State<CardCatalogScreen> {
  final CardCatalogRepository _repository = CardCatalogRepository();
  final PageController _modePageController = PageController();
  final Map<_CardShareMode, Set<String>> _selectedCardIds = {
    _CardShareMode.need: <String>{},
    _CardShareMode.spare: <String>{},
  };
  final Map<_CardShareMode, int> _setIndexByMode = {
    _CardShareMode.need: -1,
    _CardShareMode.spare: -1,
  };

  CardCatalogSeason? _season;
  bool _isLoading = true;
  String? _loadError;
  int _modeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _modePageController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final season = await _repository.fetchActiveSeason();
      if (!mounted) return;
      setState(() {
        _season = season;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectMode(int index) {
    if (index == _modeIndex) return;
    setState(() => _modeIndex = index);
    _modePageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleCard(_CardShareMode mode, CardCatalogCard card) {
    setState(() {
      final selectedIds = _selectedCardIds[mode]!;
      if (selectedIds.contains(card.id)) {
        selectedIds.remove(card.id);
      } else {
        selectedIds.add(card.id);
      }
    });
  }

  void _moveSet(_CardShareMode mode, int delta) {
    final season = _season;
    if (season == null || season.sets.isEmpty) return;
    final current = _selectedSetIndex(mode) < 0
        ? 0
        : _safeSetIndex(mode, season.sets.length);
    final next = (current + delta).clamp(0, season.sets.length - 1).toInt();
    if (current == next) return;
    setState(() => _setIndexByMode[mode] = next);
  }

  void _selectSetFilter(_CardShareMode mode, int setIndex) {
    setState(() => _setIndexByMode[mode] = setIndex);
  }

  int _selectedSetIndex(_CardShareMode mode) {
    return _setIndexByMode[mode] ?? -1;
  }

  int _safeSetIndex(_CardShareMode mode, int setCount) {
    if (setCount <= 0) return 0;
    final index = _setIndexByMode[mode] ?? 0;
    if (index < 0) return 0;
    if (index >= setCount) return setCount - 1;
    return index;
  }

  String _shareText(_CardShareMode mode, CardCatalogSeason season) {
    final selectedIds = _selectedCardIds[mode] ?? const <String>{};
    if (selectedIds.isEmpty) return '';

    final cardsBySetId = season.cardsBySetId;
    final lines = <String>[];
    for (final set in season.sets) {
      final selectedNames = (cardsBySetId[set.id] ?? const <CardCatalogCard>[])
          .where((card) => selectedIds.contains(card.id))
          .map((card) => card.name)
          .toList(growable: false);
      if (selectedNames.isEmpty) continue;
      lines.add('[${set.name}] ${selectedNames.join(', ')}');
    }
    if (lines.isEmpty) return '';
    return [mode.label, ...lines].join('\n');
  }

  Future<void> _copyShareText(_CardShareMode mode, String text) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${mode.label} 문구를 복사했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final season = _season;
    return Column(
      children: [
        AppTopHeader(title: '카드', onSearchTap: widget.onSearchTap),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_loadError != null || season == null)
          Expanded(child: _buildError())
        else
          Expanded(child: _buildLoaded(season)),
      ],
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: const Color(0xFFED9A3A),
      onRefresh: _loadCatalog,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 170),
        children: [
          const Text(
            '카드 시즌 정보를 불러오지 못했습니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? '알 수 없는 오류가 발생했습니다.',
            style: const TextStyle(color: Color(0xFF7A8190), height: 1.35),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadCatalog, child: const Text('다시 불러오기')),
        ],
      ),
    );
  }

  Widget _buildLoaded(CardCatalogSeason season) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _SeasonSummaryCard(season: season),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ModeSwitcher(
            selectedIndex: _modeIndex,
            onSelected: _selectMode,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _modePageController,
            onPageChanged: (index) => setState(() => _modeIndex = index),
            children: [
              _buildModePage(_CardShareMode.need, season),
              _buildModePage(_CardShareMode.spare, season),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardTabBanner() {
    return const SizedBox.shrink();
  }

  Widget _buildModePage(_CardShareMode mode, CardCatalogSeason season) {
    final shareText = _shareText(mode, season);
    return RefreshIndicator(
      color: const Color(0xFFED9A3A),
      onRefresh: _loadCatalog,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 170),
        children: [
          _buildCardTabBanner(),
          _ShareTextPanel(
            mode: mode,
            text: shareText,
            selectedCount: _selectedCardIds[mode]?.length ?? 0,
            onCopy: () => _copyShareText(mode, shareText),
          ),
          const SizedBox(height: 12),
          _SetFilterChips(
            sets: season.sets,
            selectedIndex: _selectedSetIndex(mode),
            onSelected: (index) => _selectSetFilter(mode, index),
          ),
          const SizedBox(height: 12),
          if (_selectedSetIndex(mode) < 0)
            _buildAllSetBoards(mode, season)
          else
            _buildSetBoard(
              mode,
              season,
              setIndex: _safeSetIndex(mode, season.sets.length),
              showArrows: true,
            ),
        ],
      ),
    );
  }

  Widget _buildAllSetBoards(_CardShareMode mode, CardCatalogSeason season) {
    if (season.sets.isEmpty) {
      return const _EmptyStateCard(message: '등록된 카드 세트가 없습니다.');
    }

    return Column(
      children: [
        for (var index = 0; index < season.sets.length; index++) ...[
          _buildSetBoard(mode, season, setIndex: index, showArrows: false),
          if (index != season.sets.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSetBoard(
    _CardShareMode mode,
    CardCatalogSeason season, {
    required int setIndex,
    required bool showArrows,
  }) {
    if (season.sets.isEmpty) {
      return const _EmptyStateCard(message: '등록된 카드 세트가 없습니다.');
    }

    final cardsBySetId = season.cardsBySetId;
    final set = season.sets[setIndex];
    final cards = cardsBySetId[set.id] ?? const <CardCatalogCard>[];
    final selectedIds = _selectedCardIds[mode] ?? const <String>{};

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2029)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showArrows)
                _SetArrowButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: setIndex > 0,
                  onTap: () => _moveSet(mode, -1),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      set.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '세트 ${setIndex + 1}/${season.sets.length}',
                      style: const TextStyle(
                        color: Color(0xFF7A8190),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrows)
                _SetArrowButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: setIndex < season.sets.length - 1,
                  onTap: () => _moveSet(mode, 1),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          _CardGrid(
            setOrder: set.order,
            cards: cards,
            selectedIds: selectedIds,
            onCardTap: (card) => _toggleCard(mode, card),
          ),
        ],
      ),
    );
  }
}

enum _CardShareMode { need, spare }

extension _CardShareModeLabel on _CardShareMode {
  String get label {
    switch (this) {
      case _CardShareMode.need:
        return '구해요';
      case _CardShareMode.spare:
        return '남아요';
    }
  }

  String get emptyGuide {
    switch (this) {
      case _CardShareMode.need:
        return '구하는 카드를 선택하면 문구가 자동으로 만들어져요.';
      case _CardShareMode.spare:
        return '남는 카드를 선택하면 문구가 자동으로 만들어져요.';
    }
  }

  IconData get icon {
    switch (this) {
      case _CardShareMode.need:
        return Icons.search_rounded;
      case _CardShareMode.spare:
        return Icons.inventory_2_outlined;
    }
  }
}

class _SeasonSummaryCard extends StatelessWidget {
  const _SeasonSummaryCard({required this.season});

  final CardCatalogSeason season;

  @override
  Widget build(BuildContext context) {
    final title = season.title.trim().isNotEmpty ? season.title : season.name;
    final remainingDays = _remainingDays(season.endAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF233E8B), Color(0xFF0C8D8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.style_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${season.sets.length}세트 · ${season.totalCards}장'
                  '${remainingDays == null ? '' : ' · $remainingDays일 남음'}',
                  style: const TextStyle(
                    color: Color(0xDFFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _remainingDays(DateTime? endAt) {
    if (endAt == null) return null;
    final diff = endAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff + 1;
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF232A35)
            : const Color(0xFFEDEFF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ModeButton(
            mode: _CardShareMode.need,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _ModeButton(
            mode: _CardShareMode.spare,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _CardShareMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (mode == _CardShareMode.need
                      ? const Color(0xFFED9A3A)
                      : const Color(0xFF259A70))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode.icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFB6C0CF)
                          : const Color(0xFF697181)),
              ),
              const SizedBox(width: 6),
              Text(
                mode.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFFE6ECF5)
                            : const Color(0xFF303642)),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetFilterChips extends StatelessWidget {
  const _SetFilterChips({
    required this.sets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CardCatalogSet> sets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final setIndex = isAll ? -1 : index - 1;
          final label = isAll ? '전체' : sets[index - 1].name;
          final selected = selectedIndex == setIndex;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(label),
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFDCE3F0)
                        : const Color(0xFF3A404B)),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            avatar: isAll
                ? Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFFDCE3F0)
                              : const Color(0xFF596170)),
                  )
                : null,
            selectedColor: const Color(0xFFED9A3A),
            backgroundColor: isDark
                ? const Color(0xFF232A35)
                : const Color(0xFFEDEFF4),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            onSelected: (_) => onSelected(setIndex),
          );
        },
      ),
    );
  }
}

class _ShareTextPanel extends StatelessWidget {
  const _ShareTextPanel({
    required this.mode,
    required this.text,
    required this.selectedCount,
    required this.onCopy,
  });

  final _CardShareMode mode;
  final String text;
  final int selectedCount;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2029) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasText
              ? const Color(0xFFED9A3A)
              : (isDark ? const Color(0xFF303846) : const Color(0xFFE4E7EF)),
          width: hasText ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${mode.label} 문구',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$selectedCount개 선택',
                style: const TextStyle(
                  color: Color(0xFF7A8190),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: hasText ? onCopy : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFED9A3A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF303846)
                      : const Color(0xFFE0E3EA),
                  disabledForegroundColor: const Color(0xFF8D94A1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text(
                  '복사',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Container(
              key: ValueKey<String>(hasText ? text : mode.emptyGuide),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121720)
                    : const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                hasText ? text : mode.emptyGuide,
                style: TextStyle(
                  color: hasText
                      ? (isDark
                            ? const Color(0xFFF1F5FA)
                            : const Color(0xFF20242D))
                      : const Color(0xFF8A909D),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: hasText ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetArrowButton extends StatelessWidget {
  const _SetArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xFFFFE1B8)
            : const Color(0xFFE7E8EC),
        foregroundColor: enabled
            ? const Color(0xFFB05B05)
            : const Color(0xFF9AA0AA),
      ),
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.setOrder,
    required this.cards,
    required this.selectedIds,
    required this.onCardTap,
  });

  final int setOrder;
  final List<CardCatalogCard> cards;
  final Set<String> selectedIds;
  final ValueChanged<CardCatalogCard> onCardTap;

  @override
  Widget build(BuildContext context) {
    final slots = _slotsForGrid(cards);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        final card = slots[index];
        if (card == null) {
          return const _EmptyCardSlot();
        }
        return _SelectableCardTile(
          card: card,
          setOrder: setOrder,
          selected: selectedIds.contains(card.id),
          onTap: () => onCardTap(card),
        );
      },
    );
  }

  List<CardCatalogCard?> _slotsForGrid(List<CardCatalogCard> cards) {
    final slots = List<CardCatalogCard?>.filled(10, null);
    for (final card in cards) {
      final slot = card.slotIndex - 1;
      if (slot >= 0 && slot < slots.length && slots[slot] == null) {
        slots[slot] = card;
        continue;
      }
      final emptyIndex = slots.indexWhere((item) => item == null);
      if (emptyIndex != -1) slots[emptyIndex] = card;
    }
    return slots;
  }
}

class _SelectableCardTile extends StatelessWidget {
  const _SelectableCardTile({
    required this.card,
    required this.setOrder,
    required this.selected,
    required this.onTap,
  });

  final CardCatalogCard card;
  final int setOrder;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SetPalette.byOrder(setOrder);
    final borderColor = card.isGold
        ? const Color(0xFFE7B64C)
        : (selected ? const Color(0xFF36B96B) : const Color(0xFFC8D1EA));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: borderColor,
              width: selected || card.isGold ? 2.4 : 1.4,
            ),
            boxShadow: [
              if (card.isGold)
                const BoxShadow(
                  color: Color(0x44E7B64C),
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              BoxShadow(
                color: selected
                    ? const Color(0x4436B96B)
                    : const Color(0x18000000),
                blurRadius: selected ? 10 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Column(
                    children: [
                      Expanded(
                        child: card.imageUrl.isNotEmpty
                            ? Image.network(
                                card.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _CardFallbackArt(palette: palette),
                              )
                            : _CardFallbackArt(palette: palette),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 5,
                        ),
                        color: palette.label,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            card.name,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x55000000),
                    borderRadius: BorderRadius.circular(9),
                    border: card.isGold
                        ? Border.all(color: const Color(0xFFE7B64C), width: 0.7)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      card.stars,
                      (_) => const Icon(
                        Icons.star_rounded,
                        size: 9.5,
                        color: Color(0xFFFFD84A),
                        shadows: [
                          Shadow(
                            color: Color(0xAA6B3E00),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: selected ? 1 : 0.86,
                  child: Container(
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF36B96B)
                          : Colors.white.withValues(alpha: 0.82),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFBFC6D6),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
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

class _CardFallbackArt extends StatelessWidget {
  const _CardFallbackArt({required this.palette});

  final _SetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.background, palette.art],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.style_rounded,
        color: Colors.white.withValues(alpha: 0.78),
        size: 24,
      ),
    );
  }
}

class _EmptyCardSlot extends StatelessWidget {
  const _EmptyCardSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF252B34)
            : const Color(0xFFE9E4D7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFCAC4B6), width: 1.2),
      ),
      child: const Center(
        child: Icon(Icons.lock_outline_rounded, color: Color(0xFF9B9384)),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2029)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF7A8190),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SetPalette {
  const _SetPalette({
    required this.background,
    required this.art,
    required this.label,
  });

  final Color background;
  final Color art;
  final Color label;

  static _SetPalette byOrder(int order) {
    const palettes = [
      _SetPalette(
        background: Color(0xFF52B75A),
        art: Color(0xFFB8E986),
        label: Color(0xFF319342),
      ),
      _SetPalette(
        background: Color(0xFFE95757),
        art: Color(0xFFFFA45B),
        label: Color(0xFFC93C42),
      ),
      _SetPalette(
        background: Color(0xFF8654D9),
        art: Color(0xFF4DC5E8),
        label: Color(0xFF6D43C4),
      ),
      _SetPalette(
        background: Color(0xFFF27B35),
        art: Color(0xFFFFCC55),
        label: Color(0xFFD75F25),
      ),
      _SetPalette(
        background: Color(0xFF458AEF),
        art: Color(0xFF8EE3F5),
        label: Color(0xFF3376D5),
      ),
      _SetPalette(
        background: Color(0xFF2A9D9A),
        art: Color(0xFFA9E2CA),
        label: Color(0xFF208985),
      ),
    ];
    return palettes[(order <= 0 ? 0 : order - 1) % palettes.length];
  }
}
