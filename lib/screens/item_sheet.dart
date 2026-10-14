import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../widgets/app_ui.dart';
import '../core/navigation/app_navigator.dart';
import '../core/nest/nest_logic.dart';
import '../models/shop_item.dart';
import '../providers/nest_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/item_cover.dart';

Future<void> showItemSheet(BuildContext context, {NestItem? item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheet) {
      final media = MediaQuery.of(sheet);
      final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.72;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _ItemSheet(item: item),
        ),
      );
    },
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({this.item});

  final NestItem? item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _tags;
  late final TextEditingController _note;
  late String _roomId;
  late String _areaId;
  late String _photo;
  late int _cover;
  DateTime? _bought;
  DateTime? _warranty;
  DateTime? _maintain;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final board = context.read<NestProvider>().board;
    _name = TextEditingController(text: item?.name ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _price = TextEditingController(text: item == null ? '' : (item.priceCents / 100).toStringAsFixed(2));
    _tags = TextEditingController(text: item?.tags.join(', ') ?? '');
    _note = TextEditingController(text: item?.note ?? '');
    _roomId = item?.roomId ?? (board.rooms.isEmpty ? '' : board.rooms.first.id);
    _areaId = item?.areaId ?? '';
    _photo = item?.photoPath ?? '';
    _cover = item?.cover ?? board.items.length % 6;
    _bought = item?.bought;
    _warranty = item?.warrantyUntil;
    _maintain = item?.maintainOn;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _tags.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate(void Function(DateTime?) set) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => set(picked));
  }

  Future<void> _photoPick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/nest_photos');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final dest = File('${folder.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(picked.path).copy(dest.path);
    if (!mounted) return;
    setState(() => _photo = dest.path);
  }

  Future<void> _save() async {
    final nest = context.read<NestProvider>();
    final shop = context.read<ShopProvider>();
    if (widget.item == null && !nest.canAddItem) {
      AppToast.show(
        context,
        title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}),
        actionLabel: 'Shop',
        onAction: AppTabs.goShop,
      );
      return;
    }
    final price = parseNestMoney(_price.text) ?? 0;
    final saved = await nest.saveItem(
      id: widget.item?.id,
      name: _name.text,
      category: _category.text,
      roomId: _roomId,
      areaId: _areaId,
      priceCents: price,
      bought: _bought,
      warrantyUntil: _warranty,
      maintainOn: _maintain,
      tags: _tags.text.split(','),
      photoPath: _photo,
      cover: _cover,
      note: _note.text,
    );
    if (!mounted) return;
    if (saved == null) {
      AppToast.show(context, title: _name.text.trim().isEmpty ? 'Add a name' : 'Choose a room');
      return;
    }
    if (shop.featureOn(ShopCatalog.featSound)) HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  InputDecoration _field(String hint) {
    final fill = AppColors.isDark(context) ? AppColors.surfaceOf(context) : const Color(0xFFF2F4F7);
    final line = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: line,
      enabledBorder: line,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryOf(context)),
      ),
    );
  }

  Widget _caption(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(text, style: AppTypography.body(size: 13, context: context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<NestProvider>().board;
    final areas = board.areas.where((row) => row.roomId == _roomId).toList();
    final categories = NestMath.categories(board);
    final fill = AppColors.isDark(context) ? AppColors.surfaceOf(context) : const Color(0xFFF2F4F7);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.item == null ? 'Add Item' : 'Edit Item',
              style: AppTypography.display(size: 22, context: context),
            ),
          ),
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            children: [
              GestureDetector(
                onTap: _photoPick,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ItemCover(cover: _cover, photoPath: _photo),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_outlined, size: 16, color: AppColors.primaryOf(context)),
                                  const SizedBox(width: 6),
                                  Text('Add photo', style: AppTypography.body(size: 13, context: context, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _caption('Name'),
              TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: _field('Remote Control')),
              _caption('Category'),
              if (categories.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final name = categories[index];
                      final selected = _category.text.trim().toLowerCase() == name.toLowerCase();
                      return GestureDetector(
                        onTap: () => setState(() => _category.text = name),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryOf(context) : fill,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: Text(
                                name,
                                style: AppTypography.body(
                                  size: 13,
                                  context: context,
                                  color: selected ? Colors.white : AppColors.inkOf(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              TextField(controller: _category, decoration: _field('Or type a category')),
              _caption('Location'),
              DropdownButtonFormField<String>(
                value: board.rooms.any((row) => row.id == _roomId) ? _roomId : null,
                isExpanded: true,
                decoration: _field('Choose a room'),
                borderRadius: BorderRadius.circular(14),
                items: [
                  for (final room in board.rooms) DropdownMenuItem(value: room.id, child: Text(room.name)),
                ],
                onChanged: (value) => setState(() {
                  _roomId = value ?? '';
                  _areaId = '';
                }),
              ),
              _caption('Area'),
              DropdownButtonFormField<String>(
                value: areas.any((row) => row.id == _areaId) ? _areaId : '',
                isExpanded: true,
                decoration: _field('None'),
                borderRadius: BorderRadius.circular(14),
                items: [
                  const DropdownMenuItem(value: '', child: Text('None')),
                  for (final area in areas) DropdownMenuItem(value: area.id, child: Text(area.name)),
                ],
                onChanged: (value) => setState(() => _areaId = value ?? ''),
              ),
              _caption('Purchase price'),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _field('0.00'),
              ),
              _DateRow(label: 'Bought', value: nestDate(_bought), onPick: () => _pickDate((v) => _bought = v), onClear: () => setState(() => _bought = null)),
              _DateRow(label: 'Warranty', value: nestDate(_warranty), onPick: () => _pickDate((v) => _warranty = v), onClear: () => setState(() => _warranty = null)),
              _DateRow(label: 'Maintain', value: nestDate(_maintain), onPick: () => _pickDate((v) => _maintain = v), onClear: () => setState(() => _maintain = null)),
              _caption('Tags'),
              TextField(controller: _tags, decoration: _field('remote, living room')),
              _caption('Note'),
              TextField(controller: _note, decoration: _field('Optional'), maxLines: 2),
              if (widget.item != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      await context.read<NestProvider>().deleteItem(widget.item!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Remove item', style: TextStyle(color: AppColors.error)),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, required this.onPick, required this.onClear});

  final String label;
  final String value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final shown = value.isEmpty ? 'Not set' : value;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body(size: 13, context: context)),
                const SizedBox(height: 2),
                Text(shown, style: AppTypography.title(size: 15, context: context)),
              ],
            ),
          ),
          if (value.isNotEmpty)
            IconButton(onPressed: onClear, icon: Icon(Icons.close, color: AppColors.mutedInk(context))),
          IconButton(onPressed: onPick, icon: Icon(Icons.calendar_today_outlined, color: AppColors.primaryOf(context))),
        ],
      ),
    );
  }
}
