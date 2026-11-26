import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../ranking/insertion_session.dart';
import '../theme.dart';
import '../widgets/item_photo.dart';
import '../widgets/raised_card.dart';

/// Ranks one item by asking "which do you prefer?" until its place is found.
///
/// Closing the screen early leaves the item in the "Not ranked yet" tray.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.listId, required this.itemId});

  final String listId;
  final String itemId;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  RankItem? _item;
  InsertionSession<RankItem>? _session;
  bool _placed = false;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _session == null) _load();
  }

  Future<void> _load() async {
    final repo = AppScope.of(context);
    final item = await repo.item(widget.itemId);
    final ranked = (await repo.rankedItems(widget.listId))
        .where((i) => i.id != widget.itemId)
        .toList();
    if (!mounted) return;
    setState(() {
      _item = item;
      _session = InsertionSession(ranked);
      _loading = false;
    });
    await _placeIfDone();
  }

  Future<void> _placeIfDone() async {
    final session = _session!;
    if (!session.isDone || _placed) return;
    await AppScope.of(context)
        .placeAt(widget.itemId, session.ranked, session.insertIndex);
    if (mounted) setState(() => _placed = true);
  }

  Future<void> _answer(Preference p) async {
    setState(() => _session!.answer(p));
    await _placeIfDone();
  }

  Future<void> _tooClose() async {
    setState(() => _session!.tooClose());
    await _placeIfDone();
  }

  Future<void> _back() async {
    final session = _session!;
    if (_placed) {
      await AppScope.of(context).unrank(widget.itemId);
      _placed = false;
    }
    setState(session.undo);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final item = _item;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _placed ? 'Close' : 'Stop and rank later',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading || session == null
            ? const Center(child: CircularProgressIndicator())
            : item == null
            ? const Center(child: Text('This item no longer exists.'))
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: session.isDone
                    ? _Result(
                        key: const ValueKey('result'),
                        item: item,
                        rank: session.insertIndex + 1,
                        total: session.ranked.length + 1,
                        canUndo: session.canUndo,
                        onUndo: _back,
                        onDone: () => Navigator.of(context).pop(),
                      )
                    : _Question(
                        key: ValueKey('q${session.answered}'),
                        item: item,
                        session: session,
                        onAnswer: _answer,
                        onTooClose: _tooClose,
                        onBack: session.canUndo ? _back : null,
                      ),
              ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    super.key,
    required this.item,
    required this.session,
    required this.onAnswer,
    required this.onTooClose,
    required this.onBack,
  });

  final RankItem item;
  final InsertionSession<RankItem> session;
  final ValueChanged<Preference> onAnswer;
  final VoidCallback onTooClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final opponent = session.opponent;
    final number = session.answered + 1;
    final most = session.answered + session.remainingAtMost;
    final progress = session.answered / (most == 0 ? 1 : most);

    final newCard = _Choice(
      label: 'NEW',
      item: item,
      onTap: () => onAnswer(Preference.newItem),
    );
    final oldCard = _Choice(
      label: '#${session.compareIndex + 1} NOW',
      item: opponent,
      onTap: () => onAnswer(Preference.existingItem),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Question $number of up to $most',
                style: t.bodyMedium,
                key: const ValueKey('progress-label'),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    color: OrdoColors.accent,
                    backgroundColor: OrdoColors.outline,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Which do you prefer?',
                style: t.displaySmall?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth > 600;
                    final or = Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'or',
                        textAlign: TextAlign.center,
                        style: t.titleMedium?.copyWith(
                          color: OrdoColors.textMuted,
                        ),
                      ),
                    );
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: newCard),
                              Center(child: or),
                              Expanded(child: oldCard),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: newCard),
                              or,
                              Expanded(child: oldCard),
                            ],
                          );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTooClose,
                      child: const Text('Too close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.item, required this.onTap});

  final String label;
  final RankItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return RaisedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, c) {
          final photoSize = (c.maxHeight - 90).clamp(48.0, 160.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: t.labelLarge?.copyWith(
                  color: OrdoColors.accent,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              if (c.maxHeight > 150) ...[
                ItemPhoto(photo: item.photo, name: item.name, size: photoSize),
                const SizedBox(height: 14),
              ],
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleLarge,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    super.key,
    required this.item,
    required this.rank,
    required this.total,
    required this.canUndo,
    required this.onUndo,
    required this.onDone,
  });

  final RankItem item;
  final int rank;
  final int total;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ItemPhoto(photo: item.photo, name: item.name, size: 96),
              ),
              const SizedBox(height: 24),
              Text(item.name, textAlign: TextAlign.center, style: t.titleLarge),
              const SizedBox(height: 8),
              Text(
                '#$rank',
                textAlign: TextAlign.center,
                style: t.displaySmall?.copyWith(
                  fontSize: 72,
                  color: OrdoColors.accent,
                ),
              ),
              Text(
                'of $total',
                textAlign: TextAlign.center,
                style: t.bodyMedium,
              ),
              const SizedBox(height: 36),
              FilledButton(onPressed: onDone, child: const Text('Done')),
              if (canUndo) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Undo last answer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
