import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/repository.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/raised_card.dart';
import 'list_screen.dart';

/// All of the person's lists.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _createList(BuildContext context) async {
    final repo = AppScope.of(context);
    final title = await askForText(
      context,
      title: 'New list',
      action: 'Create',
      hint: 'e.g. Best films of all time',
    );
    if (title == null || !context.mounted) return;
    final id = await repo.createList(title);
    if (!context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ListScreen(listId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createList(context),
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ListSummary>>(
          stream: repo.watchListSummaries(),
          builder: (context, snapshot) {
            final lists = snapshot.data;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: _Header(count: lists?.length),
                  ),
                ),
                if (lists == null)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (lists.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyHome(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 150,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ListCard(summary: lists[i]),
                        childCount: lists.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.count});
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ORDO',
          style: t.labelLarge?.copyWith(
            color: OrdoColors.accent,
            letterSpacing: 4,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Text('Your lists,\nin order.', style: t.displaySmall),
        if (count != null && count! > 0) ...[
          const SizedBox(height: 10),
          Text('$count ${count == 1 ? 'list' : 'lists'}', style: t.bodyMedium),
        ],
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.format_list_numbered_rounded,
            size: 56,
            color: OrdoColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text('No lists yet', style: t.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Make a list, add items, and Ordo asks a few\n"which do you prefer?" questions to rank them.',
            textAlign: TextAlign.center,
            style: t.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.summary});
  final ListSummary summary;

  Future<void> _showMenu(BuildContext context) async {
    final repo = AppScope.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: OrdoColors.surfaceHigh,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: OrdoColors.danger,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: OrdoColors.danger),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'rename') {
      final title = await askForText(
        context,
        title: 'Rename list',
        action: 'Save',
        initial: summary.list.title,
      );
      if (title != null) await repo.renameList(summary.list.id, title);
    } else if (choice == 'delete') {
      final ok = await confirm(
        context,
        title: 'Delete "${summary.list.title}"?',
        message: 'The list and its ${summary.itemCount} items will be removed.',
        action: 'Delete',
      );
      if (ok) await repo.deleteList(summary.list.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final count = summary.itemCount;
    return RaisedCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ListScreen(listId: summary.list.id)),
      ),
      onLongPress: () => _showMenu(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.list.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'List options',
                icon: const Icon(Icons.more_horiz, color: OrdoColors.textMuted),
                onPressed: () => _showMenu(context),
              ),
            ],
          ),
          const Spacer(),
          Text('$count ${count == 1 ? 'item' : 'items'}', style: t.bodyMedium),
          if (summary.topItem != null) ...[
            const SizedBox(height: 4),
            Text(
              '#1  ${summary.topItem}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleMedium?.copyWith(color: OrdoColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}
