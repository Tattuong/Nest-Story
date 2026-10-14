class House {
  House({required this.id, required this.name});

  final String id;
  String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory House.fromJson(Map<String, dynamic> json) => House(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class Room {
  Room({required this.id, required this.houseId, required this.name});

  final String id;
  String houseId;
  String name;

  Map<String, dynamic> toJson() => {'id': id, 'houseId': houseId, 'name': name};

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String? ?? '',
        houseId: json['houseId'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class Area {
  Area({required this.id, required this.roomId, required this.name});

  final String id;
  String roomId;
  String name;

  Map<String, dynamic> toJson() => {'id': id, 'roomId': roomId, 'name': name};

  factory Area.fromJson(Map<String, dynamic> json) => Area(
        id: json['id'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class NestItem {
  NestItem({
    required this.id,
    required this.name,
    required this.category,
    required this.roomId,
    this.areaId = '',
    this.priceCents = 0,
    this.bought,
    this.warrantyUntil,
    this.maintainOn,
    this.tags = const [],
    this.photoPath = '',
    this.cover = 0,
    this.note = '',
  });

  final String id;
  String name;
  String category;
  String roomId;
  String areaId;
  int priceCents;
  DateTime? bought;
  DateTime? warrantyUntil;
  DateTime? maintainOn;
  List<String> tags;
  String photoPath;
  int cover;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'roomId': roomId,
        'areaId': areaId,
        'priceCents': priceCents,
        'bought': bought?.toIso8601String(),
        'warrantyUntil': warrantyUntil?.toIso8601String(),
        'maintainOn': maintainOn?.toIso8601String(),
        'tags': tags,
        'photoPath': photoPath,
        'cover': cover,
        'note': note,
      };

  factory NestItem.fromJson(Map<String, dynamic> json) => NestItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        areaId: json['areaId'] as String? ?? '',
        priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
        bought: DateTime.tryParse(json['bought'] as String? ?? ''),
        warrantyUntil: DateTime.tryParse(json['warrantyUntil'] as String? ?? ''),
        maintainOn: DateTime.tryParse(json['maintainOn'] as String? ?? ''),
        tags: (json['tags'] as List?)?.map((row) => row.toString()).toList() ?? const [],
        photoPath: json['photoPath'] as String? ?? '',
        cover: (json['cover'] as num?)?.toInt() ?? 0,
        note: json['note'] as String? ?? '',
      );
}

class NestBoard {
  NestBoard({
    required this.houses,
    required this.rooms,
    required this.areas,
    required this.items,
  });

  final List<House> houses;
  final List<Room> rooms;
  final List<Area> areas;
  final List<NestItem> items;

  Map<String, dynamic> toJson() => {
        'houses': houses.map((row) => row.toJson()).toList(),
        'rooms': rooms.map((row) => row.toJson()).toList(),
        'areas': areas.map((row) => row.toJson()).toList(),
        'items': items.map((row) => row.toJson()).toList(),
      };

  factory NestBoard.fromJson(Map<String, dynamic> json) => NestBoard(
        houses: _maps(json['houses']).map(House.fromJson).toList(),
        rooms: _maps(json['rooms']).map(Room.fromJson).toList(),
        areas: _maps(json['areas']).map(Area.fromJson).toList(),
        items: _maps(json['items']).map(NestItem.fromJson).toList(),
      );
}

class NestMath {
  NestMath._();

  static String roomName(NestBoard board, String roomId) {
    for (final room in board.rooms) {
      if (room.id == roomId) return room.name;
    }
    return '';
  }

  static String areaName(NestBoard board, String areaId) {
    for (final area in board.areas) {
      if (area.id == areaId) return area.name;
    }
    return '';
  }

  static String houseName(NestBoard board, String houseId) {
    for (final house in board.houses) {
      if (house.id == houseId) return house.name;
    }
    return '';
  }

  static int totalCents(NestBoard board) => board.items.fold(0, (sum, row) => sum + row.priceCents);

  static List<String> categories(NestBoard board) {
    final names = board.items.map((row) => row.category.trim()).where((row) => row.isNotEmpty).toSet().toList()
      ..sort();
    return names;
  }

  static List<NestItem> visible(
    NestBoard board, {
    required String query,
    required String? category,
    required String? roomId,
  }) {
    final needle = query.trim().toLowerCase();
    final rows = board.items.where((item) {
      if (category != null && item.category != category) return false;
      if (roomId != null && item.roomId != roomId) return false;
      if (needle.isEmpty) return true;
      final room = roomName(board, item.roomId).toLowerCase();
      final area = areaName(board, item.areaId).toLowerCase();
      final tags = item.tags.join(' ').toLowerCase();
      return item.name.toLowerCase().contains(needle) ||
          item.category.toLowerCase().contains(needle) ||
          room.contains(needle) ||
          area.contains(needle) ||
          tags.contains(needle);
    }).toList();
    return rows;
  }

  static List<NestItem> dueSoon(NestBoard board) {
    DateTime? first(NestItem item) {
      final dates = [item.maintainOn, item.warrantyUntil].whereType<DateTime>();
      if (dates.isEmpty) return null;
      return dates.reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final rows = board.items.where((row) => first(row) != null).toList()
      ..sort((a, b) => first(a)!.compareTo(first(b)!));
    return rows;
  }
}

List<Map<String, dynamic>> _maps(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String nestDate(DateTime? at) {
  if (at == null) return '';
  return '${at.day} ${_months[at.month.clamp(1, 12) - 1]} ${at.year}';
}

String nestMoney(int cents) {
  final whole = cents.abs() ~/ 100;
  final frac = (cents.abs() % 100).toString().padLeft(2, '0');
  final digits = whole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final body = '\$$buf.$frac';
  return cents < 0 ? '-$body' : body;
}

int? parseNestMoney(String raw) {
  final cleaned = raw.trim().replaceAll('\$', '').replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return null;
  if (value > 100000000) return null;
  return (value * 100).round();
}

String nestCsv(NestBoard board) {
  final lines = <String>['Name,Category,Room,Area,Price,Bought,Warranty,Maintain,Tags,Note'];
  for (final item in board.items) {
    lines.add([
      item.name,
      item.category,
      NestMath.roomName(board, item.roomId),
      NestMath.areaName(board, item.areaId),
      (item.priceCents / 100).toStringAsFixed(2),
      nestDate(item.bought),
      nestDate(item.warrantyUntil),
      nestDate(item.maintainOn),
      item.tags.join(' '),
      item.note,
    ].map(_csv).join(','));
  }
  return lines.join('\n');
}

String _csv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
