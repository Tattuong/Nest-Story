import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../core/nest/nest_logic.dart';
import '../models/shop_item.dart';
import '../providers/nest_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_ui.dart';
import '../widgets/coin_balance_chip.dart';
import '../widgets/item_cover.dart';
import 'item_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;
  var _awake = false;
  var _query = '';
  String? _category;
  String? _roomId;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    if (_awake) WakelockPlus.disable();
    super.dispose();
  }

  void _syncAwake(bool on) {
    if (on == _awake) return;
    _awake = on;
    if (on) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _named(String title, Future<void> Function(String value) save) async {
    final value = await showDialog<String>(
      context: context,
      builder: (dialog) => _NameDialog(title: title),
    );
    if (value == null || value.isEmpty || !mounted) return;
    await save(value);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    _syncAwake(shop.featureOn(ShopCatalog.featAwake));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _tab == 0) return;
        setState(() => _tab = 0);
      },
      child: FtrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _tab == 0 ? _ItemsPage(query: _query, category: _category, roomId: _roomId, search: _search, onQuery: (value) => setState(() => _query = value), onCategory: (value) => setState(() => _category = value), onRoom: (value) => setState(() => _roomId = value)) : _AccountPage(onName: _named)),
              const AdBannerSlot(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: AppColors.surfaceOf(context),
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryOf(context) : AppColors.mutedInk(context),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(color: selected ? AppColors.primaryOf(context) : AppColors.mutedInk(context));
            }),
          ),
          child: NavigationBar(
            selectedIndex: _tab == 0 ? 0 : 2,
            onDestinationSelected: (index) {
              if (index == 1) {
                showItemSheet(context);
                return;
              }
              setState(() => _tab = index == 0 ? 0 : 1);
            },
            destinations: const [
              NavigationDestination(
                icon: Image(image: AssetImage('assets/logo.png'), width: 26, height: 26),
                selectedIcon: Image(image: AssetImage('assets/logo.png'), width: 26, height: 26),
                label: 'My Items',
              ),
              NavigationDestination(icon: Icon(Icons.add), label: 'Add Item'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title});

  final String title;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(hintText: 'Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: const Text('Save')),
      ],
    );
  }
}

class _ItemsPage extends StatelessWidget {
  const _ItemsPage({
    required this.query,
    required this.category,
    required this.roomId,
    required this.search,
    required this.onQuery,
    required this.onCategory,
    required this.onRoom,
  });

  final String query;
  final String? category;
  final String? roomId;
  final TextEditingController search;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onRoom;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<NestProvider>().board;
    final rows = NestMath.visible(board, query: query, category: category, roomId: roomId);
    final chip = AppColors.isDark(context) ? AppColors.surfaceOf(context) : const Color(0xFFF2F4F7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Item', style: AppTypography.display(size: 24, context: context)),
                        Text('${rows.length} of ${board.items.length} items', style: AppTypography.body(size: 13, context: context)),
                      ],
                    ),
                  ),
                  CoinBalanceChip(
                    variant: CoinChipVariant.header,
                    onTap: () => Future<void>.delayed(Duration.zero, AppTabs.goShop),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: search,
                onChanged: onQuery,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, category or location',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                  isDense: true,
                  filled: true,
                  fillColor: chip,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _FilterPill(
                    label: category ?? 'Category',
                    selected: category != null,
                    color: chip,
                    onPick: (value) => onCategory(value.isEmpty ? null : value),
                    options: {'': 'All', for (final name in NestMath.categories(board)) name: name},
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: roomId == null ? 'Location' : NestMath.roomName(board, roomId!),
                    selected: roomId != null,
                    color: chip,
                    onPick: (value) => onRoom(value.isEmpty ? null : value),
                    options: {'': 'All', for (final room in board.rooms) room.id: room.name},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              return _ItemCard(item: item, room: NestMath.roomName(board, item.roomId));
            },
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.options,
    required this.onPick,
  });

  final String label;
  final bool selected;
  final Color color;
  final Map<String, String> options;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.primaryOf(context) : AppColors.inkOf(context);
    return PopupMenuButton<String>(
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final entry in options.entries) PopupMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primaryOf(context) : AppColors.borderOf(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ink)),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ink),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.room});

  final NestItem item;
  final String room;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceOf(context),
      elevation: 0.6,
      shadowColor: const Color(0x14000000),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showItemSheet(context, item: item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ItemCover(cover: item.cover, photoPath: item.photoPath),
                ),
              ),
              const SizedBox(height: 10),
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.primaryOf(context), fontWeight: FontWeight.w600, fontSize: 13)),
              Text(room, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(size: 13, context: context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.onName});

  final Future<void> Function(String title, Future<void> Function(String value) save) onName;

  @override
  Widget build(BuildContext context) {
    final nest = context.watch<NestProvider>();
    final board = nest.board;
    final due = NestMath.dueSoon(board);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('Account', style: AppTypography.display(size: 32, context: context))),
            const CoinBalanceChip(variant: CoinChipVariant.header),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total value', style: AppTypography.body(context: context)),
                Text(nestMoney(NestMath.totalCents(board)), style: AppTypography.display(size: 32, context: context)),
                Text('${board.items.length} items', style: AppTypography.body(size: 13, context: context)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Care', style: AppTypography.title(size: 18, context: context)),
        if (due.isEmpty)
          Text('No maintenance dates yet.', style: AppTypography.body(context: context))
        else
          for (final item in due)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text([
                if (item.maintainOn != null) 'Maintain ${nestDate(item.maintainOn)}',
                if (item.warrantyUntil != null) 'Warranty ${nestDate(item.warrantyUntil)}',
              ].join(' · ')),
              onTap: () => showItemSheet(context, item: item),
            ),
        const SizedBox(height: 8),
        Text('House', style: AppTypography.title(size: 18, context: context)),
        for (final house in board.houses) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(house.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: IconButton(
              onPressed: () => onName('Rename house', (value) => nest.renameHouse(house.id, value)),
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          for (final room in board.rooms.where((row) => row.houseId == house.id))
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(room.name)),
                      IconButton(
                        onPressed: () => onName('Area in ${room.name}', (value) => nest.addArea(room.id, value).then((_) {})),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(onPressed: () => nest.deleteRoom(room.id), icon: const Icon(Icons.close)),
                    ],
                  ),
                  for (final area in board.areas.where((row) => row.roomId == room.id))
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(child: Text(area.name, style: AppTypography.body(size: 13, context: context))),
                        IconButton(onPressed: () => nest.deleteArea(area.id), icon: const Icon(Icons.close, size: 18)),
                      ],
                    ),
                ],
              ),
            ),
          TextButton(onPressed: () => onName('Room', (value) => nest.addRoom(house.id, value).then((_) {})), child: const Text('Add room')),
        ],
        TextButton(onPressed: () => onName('House', (value) => nest.addHouse(value).then((_) {})), child: const Text('Add house')),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final file = await nest.writeCsv();
            await Share.shareXFiles([XFile(file.path)], text: 'Nest Story inventory');
          },
          child: const Text('Export CSV'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final file = await nest.writePdf();
            await Share.shareXFiles([XFile(file.path)], text: 'Nest Story inventory');
          },
          child: const Text('Export PDF'),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings_outlined),
          title: Text(AppStrings.t(context, 'settings')),
          onTap: AppTabs.goSettings,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storefront_outlined),
          title: Text(AppStrings.t(context, 'shop')),
          onTap: AppTabs.goShop,
        ),
      ],
    );
  }
}
