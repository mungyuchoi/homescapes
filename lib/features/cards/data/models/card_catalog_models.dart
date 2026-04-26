class CardCatalogSeason {
  const CardCatalogSeason({
    required this.id,
    required this.name,
    required this.title,
    required this.totalCards,
    required this.startAt,
    required this.endAt,
    required this.sets,
    required this.cards,
  });

  final String id;
  final String name;
  final String title;
  final int totalCards;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<CardCatalogSet> sets;
  final List<CardCatalogCard> cards;

  Map<String, List<CardCatalogCard>> get cardsBySetId {
    final grouped = <String, List<CardCatalogCard>>{};
    for (final card in cards) {
      grouped.putIfAbsent(card.setId, () => <CardCatalogCard>[]).add(card);
    }
    for (final cardsInSet in grouped.values) {
      cardsInSet.sort((a, b) {
        final slot = a.slotIndex.compareTo(b.slotIndex);
        if (slot != 0) return slot;
        return a.name.compareTo(b.name);
      });
    }
    return grouped;
  }
}

class CardCatalogSet {
  const CardCatalogSet({
    required this.id,
    required this.name,
    required this.order,
  });

  final String id;
  final String name;
  final int order;
}

class CardCatalogCard {
  const CardCatalogCard({
    required this.id,
    required this.name,
    required this.setId,
    required this.slotIndex,
    required this.stars,
    required this.isGold,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String setId;
  final int slotIndex;
  final int stars;
  final bool isGold;
  final String imageUrl;
  final bool isActive;
}
