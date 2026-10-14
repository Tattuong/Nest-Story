import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../core/nest/nest_logic.dart';
import '../core/services/nest_notify.dart';
import '../core/services/storage_service.dart';
import 'shop_provider.dart';

class NestProvider extends ChangeNotifier {
  NestProvider(this.shop);

  static const _key = 'ns_nest';
  static const _lookKey = 'ns_demo_look';
  static const _demoHouse = 'home';
  static const _demoRooms = {'living', 'kitchen', 'closet', 'bedroom'};
  static const _demoAreas = {'tv', 'counter', 'rail', 'night'};

  final ShopProvider shop;
  final _uuid = const Uuid();
  NestBoard _board = NestBoard(houses: [], rooms: [], areas: [], items: []);

  NestBoard get board => _board;
  bool get canAddItem => _board.items.length < shop.maxArchive;

  Future<void> init() async {
    final raw = await StorageService.instance.getData(_key);
    if (raw != null && raw.isNotEmpty) {
      _board = NestBoard.fromJson(raw);
    }
    final look = await StorageService.instance.getInt(_lookKey) ?? 0;
    if (look < 1) {
      _stripDemo();
      await StorageService.instance.saveInt(_lookKey, 1);
      await _save();
    }
    notifyListeners();
  }

  void _stripDemo() {
    _board.items.removeWhere((row) => row.id.startsWith('demo-'));
    _board.areas.removeWhere((row) => _demoAreas.contains(row.id) && _board.items.every((item) => item.areaId != row.id));
    _board.rooms.removeWhere((row) => _demoRooms.contains(row.id) && _board.items.every((item) => item.roomId != row.id));
    _board.houses.removeWhere((row) => row.id == _demoHouse && _board.rooms.every((room) => room.houseId != row.id));
  }

  Future<House?> addHouse(String name) async {
    final title = name.trim();
    if (title.isEmpty) return null;
    final house = House(id: _uuid.v4(), name: title);
    _board.houses.add(house);
    await _save();
    notifyListeners();
    return house;
  }

  Future<void> renameHouse(String id, String name) async {
    final title = name.trim();
    if (title.isEmpty) return;
    for (final house in _board.houses) {
      if (house.id == id) house.name = title;
    }
    await _save();
    notifyListeners();
  }

  Future<Room?> addRoom(String houseId, String name) async {
    final title = name.trim();
    if (title.isEmpty || _board.houses.every((row) => row.id != houseId)) return null;
    final room = Room(id: _uuid.v4(), houseId: houseId, name: title);
    _board.rooms.add(room);
    await _save();
    notifyListeners();
    return room;
  }

  Future<void> deleteRoom(String id) async {
    if (_board.items.any((row) => row.roomId == id)) return;
    _board.areas.removeWhere((row) => row.roomId == id);
    _board.rooms.removeWhere((row) => row.id == id);
    await _save();
    notifyListeners();
  }

  Future<Area?> addArea(String roomId, String name) async {
    final title = name.trim();
    if (title.isEmpty || _board.rooms.every((row) => row.id != roomId)) return null;
    final area = Area(id: _uuid.v4(), roomId: roomId, name: title);
    _board.areas.add(area);
    await _save();
    notifyListeners();
    return area;
  }

  Future<void> deleteArea(String id) async {
    if (_board.items.any((row) => row.areaId == id)) return;
    _board.areas.removeWhere((row) => row.id == id);
    await _save();
    notifyListeners();
  }

  Future<NestItem?> saveItem({
    String? id,
    required String name,
    required String category,
    required String roomId,
    required String areaId,
    required int priceCents,
    DateTime? bought,
    DateTime? warrantyUntil,
    DateTime? maintainOn,
    required List<String> tags,
    required String photoPath,
    required int cover,
    required String note,
  }) async {
    final title = name.trim();
    if (title.isEmpty || _board.rooms.every((row) => row.id != roomId)) return null;
    if (id == null && !canAddItem) return null;
    final tagsClean = tags.map((row) => row.trim()).where((row) => row.isNotEmpty).toList();
    if (id == null) {
      final item = NestItem(
        id: _uuid.v4(),
        name: title,
        category: category.trim(),
        roomId: roomId,
        areaId: areaId,
        priceCents: priceCents,
        bought: bought,
        warrantyUntil: warrantyUntil,
        maintainOn: maintainOn,
        tags: tagsClean,
        photoPath: photoPath,
        cover: cover,
        note: note.trim(),
      );
      _board.items.add(item);
      await shop.rewardForTrip();
      await _save();
      notifyListeners();
      return item;
    }
    NestItem? current;
    for (final item in _board.items) {
      if (item.id != id) continue;
      current = item;
      item.name = title;
      item.category = category.trim();
      item.roomId = roomId;
      item.areaId = areaId;
      item.priceCents = priceCents;
      item.bought = bought;
      item.warrantyUntil = warrantyUntil;
      item.maintainOn = maintainOn;
      item.tags = tagsClean;
      item.photoPath = photoPath;
      item.cover = cover;
      item.note = note.trim();
    }
    await _save();
    notifyListeners();
    return current;
  }

  Future<void> deleteItem(String id) async {
    _board.items.removeWhere((row) => row.id == id);
    await _save();
    notifyListeners();
  }

  Future<File> writeCsv() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/nest-inventory.csv');
    await file.writeAsString(nestCsv(_board));
    return file;
  }

  Future<File> writePdf() async {
    final doc = pw.Document();
    final rows = <List<String>>[
      ['Name', 'Category', 'Room', 'Price', 'Warranty', 'Maintain'],
      for (final item in _board.items)
        [
          item.name,
          item.category,
          NestMath.roomName(_board, item.roomId),
          nestMoney(item.priceCents),
          nestDate(item.warrantyUntil),
          nestDate(item.maintainOn),
        ],
    ];
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Nest Story', style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Total ${nestMoney(NestMath.totalCents(_board))} · ${_board.items.length} items'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(data: rows, headerCount: 1),
        ],
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/nest-inventory.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> _save() async {
    await StorageService.instance.saveData(_key, _board.toJson());
    await NestNotify.sync(_board.items);
  }
}
