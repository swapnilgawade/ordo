import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/item_photo.dart';
import '../widgets/raised_card.dart';
import 'compare_screen.dart';
import 'item_editor_screen.dart';

/// One list: its items in rank order, plus a tray of items not ranked yet.
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.listId});
  final String listId;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  /// Shown straight after a drag, until the database confirms the new order.
  List<RankItem>? _pendingOrder;

  Future<void> _addItem() async {
    final itemId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ItemEditorScreen(listId: widget.listId),
      ),
    );
    if (itemId == null || !mounted) return;
    await _rank(itemId);
  }

  Future<void> _rank(String itemId) => Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CompareScreen(listId: widget.listId, itemId: itemId),
    ),
  );

  Future<void> _onReorder(List<RankItem> ranked, int from, int to) async {
    // onReorderItem already gives the index after the item is removed.
    if (from == to) return;
    final moved = ranked[from];
    final rest = [...ranked]..removeAt(from);
    setState(() => _pendingOrder = [...rest]..insert(to, moved));
    await AppScope.of(context).placeAt(moved.id, rest, to);
  }

  Future<void> _listMenu(RankList list, String choice) async {
    final repo = AppScope.of(context);
    if (choice == 'rename') {
      final title = await askForText(
        context,
        title: 'Rename list',
        action: 'Save',
        initial: list.title,
      );
      if (title != null) await repo.renameList(list.id, title);
    } else if (choice == 'delete') {
      final ok = await confirm(
        context,
        title: 'Delete "${list.title}"?',
        message: 'The list and all of its items will be removed.',
        action: 'Delete',
      );
      if (!ok) return;
      await repo.deleteList(list.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return StreamBuilder<RankList?>(
      stream: repo.watchList(widget.listId),
      builder: (context, listSnap) {
        final list = listSnap.data;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (list != null)
                PopupMenuButton<String>(
                  tooltip: 'List options',
                  color: OrdoColors.surfaceHigh,
                  onSelected: (c) => _listMenu(list, c),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete list')),
                  ],
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
          body: StreamBuilder<List<RankItem>>(
            stream: repo.watchRanked(widget.listId),
            builder: (context, rankedSnap) {
              final fromDb = rankedSnap.data;
              if (fromDb != null &&
                  _pendingOrder != null &&
                  _sameOrder(fromDb, _pendingOrder!)) {
                _pendingOrder = null;
              }
              final ranked = _pendingOrder ?? fromDb;
              return StreamBuilder<List<RankItem>>(
                stream: repo.watchUnranked(widget.listId),
                builder: (context, unrankedSnap) {
                  final unranked = unrankedSnap.data ?? const <RankItem>[];
                  if (ranked == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final header = Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list?.title ?? '', style: t.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          ranked.isEmpty && unranked.isEmpty
                              ? 'Add your first item to start ranking.'
                              : '${ranked.length} ranked · drag to fine-tune',
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  );
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    buildDefaultDragHandles: false,
                    header: header,
                    footer: unranked.isEmpty
                        ? null
                        : _UnrankedTray(items: unranked, onRank: _rank),
                    itemCount: ranked.length,
                    onReorderItem: (a, b) => _onReorder(ranked, a, b),
                    proxyDecorator: (child, _, _) =>
                        Material(color: Colors.transparent, child: child),
                    itemBuilder: (context, i) => Padding(
                      key: ValueKey(ranked[i].id),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: _RankedTile(
                        item: ranked[i],
                        rank: i + 1,
                        index: i,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemEditorScreen(
                              listId: widget.listId,
                              itemId: ranked[i].id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  static bool _sameOrder(List<RankItem> a, List<RankItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

class _RankedTile extends StatelessWidget {
  const _RankedTile({
    required this.item,
    required this.rank,
    required this.index,
    required this.onTap,
  });

  final RankItem item;
  final int rank;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final top = rank <= 3;
    return RaisedCard(
      onTap: onTap,
      radius: 20,
      highlighted: rank == 1,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$rank',
              style: t.headlineMedium?.copyWith(
                fontSize: 26,
                color: top ? OrdoColors.accent : OrdoColors.textMuted,
              ),
            ),
          ),
          ItemPhoto(photo: item.photo, name: item.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium,
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.drag_indicator, color: OrdoColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnrankedTray extends StatelessWidget {
  const _UnrankedTray({required this.items, required this.onRank});

  final List<RankItem> items;
  final Future<void> Function(String itemId) onRank;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'NOT RANKED YET',
              style: t.labelLarge?.copyWith(
                color: OrdoColors.textMuted,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: OrdoColors.outline),
                ),
                child: Row(
                  children: [
                    ItemPhoto(photo: item.photo, name: item.name, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onRank(item.id),
                      child: const Text('Rank it'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
