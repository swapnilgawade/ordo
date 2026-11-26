import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/item_photo.dart';
import 'compare_screen.dart';

/// Adds a new item (pops with its id), or edits an existing one.
class ItemEditorScreen extends StatefulWidget {
  const ItemEditorScreen({super.key, required this.listId, this.itemId});

  final String listId;
  final String? itemId;

  bool get isNew => itemId == null;

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  Uint8List? _photo;
  bool _photoChanged = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (widget.isNew) _loaded = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      AppScope.of(context).item(widget.itemId!).then((item) {
        if (item == null || !mounted) return;
        setState(() {
          _name.text = item.name;
          _note.text = item.note;
          _photo = item.photo;
        });
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photo = bytes;
        _photoChanged = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that photo.')),
      );
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = AppScope.of(context);
    if (widget.isNew) {
      final id = await repo.addItem(
        widget.listId,
        name,
        note: _note.text,
        photo: _photo,
      );
      if (mounted) Navigator.of(context).pop(id);
    } else {
      await repo.updateItem(
        widget.itemId!,
        name: name,
        note: _note.text,
        photo: _photoChanged ? _photo : null,
        clearPhoto: _photoChanged && _photo == null,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _rerank() async {
    final repo = AppScope.of(context);
    final navigator = Navigator.of(context);
    await repo.unrank(widget.itemId!);
    navigator.pushReplacement(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            CompareScreen(listId: widget.listId, itemId: widget.itemId!),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete "${_name.text.trim()}"?',
      message: 'This item will be removed from the list.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).deleteItem(widget.itemId!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canSave = _name.text.trim().isNotEmpty && !_saving;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isNew ? 'New item' : 'Edit item')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        ItemPhoto(
                          photo: _photo,
                          name: _name.text.isEmpty ? '+' : _name.text,
                          size: 120,
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: OrdoColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                              color: OrdoColors.accentInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_photo != null)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _photo = null;
                        _photoChanged = true;
                      }),
                      child: const Text('Remove photo'),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Name', style: t.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  autofocus: widget.isNew,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. The Godfather',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 20),
                Text('Note', style: t.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Optional: why it belongs here',
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: canSave ? _save : null,
                  child: Text(widget.isNew ? 'Add and rank' : 'Save'),
                ),
                if (!widget.isNew) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _rerank,
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: const Text('Re-rank with questions'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: OrdoColors.danger,
                    ),
                    child: const Text('Delete item'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
