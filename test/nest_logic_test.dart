import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestory/core/constants/iap_constants.dart';
import 'package:nestory/core/nest/demo_seed.dart';
import 'package:nestory/core/nest/nest_logic.dart';
import 'package:nestory/core/services/hive_service.dart';
import 'package:nestory/core/services/storage_service.dart';
import 'package:nestory/providers/nest_provider.dart';
import 'package:nestory/providers/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('ns_nest');
    await HiveService.init(path: dir.path, suffix: '_nest');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
    await HiveService.data.clear();
  });

  test('demo inventory matches the item grid', () {
    final board = DemoSeed.snapshot();
    expect(board.items, hasLength(6));
    expect(board.items.map((row) => row.name), [
      'Remote Control',
      'Car Keys',
      'Smart Phone',
      'Wallet',
      'Linen Jacket',
      'Bedside Plant',
    ]);
    expect(NestMath.totalCents(board), 88500);
    expect(nestMoney(88500), '\$885.00');
    final living = NestMath.visible(board, query: '', category: null, roomId: 'living');
    expect(living.map((row) => row.name), ['Remote Control', 'Smart Phone', 'Wallet']);
    final kitchen = NestMath.visible(board, query: 'kitchen', category: null, roomId: null);
    expect(kitchen.single.name, 'Car Keys');
    final gadget = NestMath.visible(board, query: '', category: 'Gadget', roomId: null);
    expect(gadget.single.name, 'Smart Phone');
  });

  test('fresh board stays empty and the ninth item is refused', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final nest = NestProvider(shop);
    await nest.init();
    expect(nest.board.items, isEmpty);
    final again = NestProvider(shop);
    await again.init();
    expect(again.board.items, isEmpty);
    final house = await again.addHouse('Home');
    final room = await again.addRoom(house!.id, 'Living room');
    for (var i = 0; i < IapConstants.freeArchiveLimit; i++) {
      expect(
        await again.saveItem(
          name: 'Extra $i',
          category: 'Other',
          roomId: room!.id,
          areaId: '',
          priceCents: 100,
          tags: const [],
          photoPath: '',
          cover: 0,
          note: '',
        ),
        isNotNull,
      );
    }
    expect(
      await again.saveItem(
        name: 'One more',
        category: 'Other',
        roomId: room!.id,
        areaId: '',
        priceCents: 100,
        tags: const [],
        photoPath: '',
        cover: 0,
        note: '',
      ),
      isNull,
    );
  });

  test('demo rows are removed once and a user item stays', () async {
    final board = DemoSeed.snapshot();
    board.houses.add(House(id: 'mine', name: 'Cabin'));
    board.rooms.add(Room(id: 'loft', houseId: 'mine', name: 'Loft'));
    board.items.add(NestItem(id: 'lamp-1', name: 'Lamp', category: 'Decor', roomId: 'loft'));
    await StorageService.instance.saveData('ns_nest', board.toJson());
    final shop = ShopProvider();
    await shop.init(remote: false);
    final nest = NestProvider(shop);
    await nest.init();
    expect(nest.board.items.map((row) => row.name), ['Lamp']);
    expect(nest.board.rooms.map((row) => row.id), ['loft']);
    expect(nest.board.houses.map((row) => row.id), ['mine']);
    expect(nest.board.areas, isEmpty);
    final again = NestProvider(shop);
    await again.init();
    expect(again.board.items.single.name, 'Lamp');
  });
}
