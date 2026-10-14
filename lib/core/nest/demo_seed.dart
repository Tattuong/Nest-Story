import 'nest_logic.dart';

class DemoSeed {
  DemoSeed._();

  static NestBoard snapshot() {
    return NestBoard(
      houses: [House(id: 'home', name: 'Home')],
      rooms: [
        Room(id: 'living', houseId: 'home', name: 'Living room'),
        Room(id: 'kitchen', houseId: 'home', name: 'Kitchen'),
        Room(id: 'closet', houseId: 'home', name: 'Closet'),
        Room(id: 'bedroom', houseId: 'home', name: 'Bedroom'),
      ],
      areas: [
        Area(id: 'tv', roomId: 'living', name: 'TV stand'),
        Area(id: 'counter', roomId: 'kitchen', name: 'Counter'),
        Area(id: 'rail', roomId: 'closet', name: 'Rail'),
        Area(id: 'night', roomId: 'bedroom', name: 'Nightstand'),
      ],
      items: [
        _item(
          id: 'demo-remote',
          name: 'Remote Control',
          category: 'Electronics',
          roomId: 'living',
          areaId: 'tv',
          priceCents: 1800,
          bought: DateTime(2024, 3, 12),
          maintainOn: DateTime(2026, 11, 2),
          tags: ['tv', 'batteries'],
          cover: 0,
        ),
        _item(
          id: 'demo-keys',
          name: 'Car Keys',
          category: 'Automotive',
          roomId: 'kitchen',
          areaId: 'counter',
          priceCents: 1200,
          bought: DateTime(2023, 8, 4),
          tags: ['car'],
          cover: 1,
        ),
        _item(
          id: 'demo-phone',
          name: 'Smart Phone',
          category: 'Gadget',
          roomId: 'living',
          priceCents: 69900,
          bought: DateTime(2025, 6, 1),
          warrantyUntil: DateTime(2027, 6, 1),
          tags: ['daily'],
          cover: 2,
        ),
        _item(
          id: 'demo-wallet',
          name: 'Wallet',
          category: 'Accessories',
          roomId: 'living',
          priceCents: 4500,
          bought: DateTime(2024, 11, 20),
          tags: ['leather'],
          cover: 3,
        ),
        _item(
          id: 'demo-jacket',
          name: 'Linen Jacket',
          category: 'Clothing',
          roomId: 'closet',
          areaId: 'rail',
          priceCents: 8900,
          bought: DateTime(2025, 9, 2),
          warrantyUntil: DateTime(2026, 12, 1),
          tags: ['winter'],
          cover: 4,
        ),
        _item(
          id: 'demo-plant',
          name: 'Bedside Plant',
          category: 'Decor',
          roomId: 'bedroom',
          areaId: 'night',
          priceCents: 2200,
          bought: DateTime(2026, 1, 18),
          maintainOn: DateTime(2026, 10, 20),
          tags: ['green'],
          cover: 5,
        ),
      ],
    );
  }

  static NestItem _item({
    required String id,
    required String name,
    required String category,
    required String roomId,
    String areaId = '',
    required int priceCents,
    DateTime? bought,
    DateTime? warrantyUntil,
    DateTime? maintainOn,
    List<String> tags = const [],
    required int cover,
  }) {
    return NestItem(
      id: id,
      name: name,
      category: category,
      roomId: roomId,
      areaId: areaId,
      priceCents: priceCents,
      bought: bought,
      warrantyUntil: warrantyUntil,
      maintainOn: maintainOn,
      tags: tags,
      cover: cover,
    );
  }
}
