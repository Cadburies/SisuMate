import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Multi-select tag field: type to filter a dropdown of known tags; submitting
/// a novel string adds it as a tag (caller persists it to the library).
class TagCombobox extends StatefulWidget {
  final String label;
  final String? helperText;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Called when the user commits a tag that was not already in [options].
  final ValueChanged<String>? onNovelTag;

  const TagCombobox({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.helperText,
    this.onNovelTag,
  });

  @override
  State<TagCombobox> createState() => _TagComboboxState();
}

class _TagComboboxState extends State<TagCombobox> {
  final _textCtrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _textCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    // Match existing option case-insensitively if present.
    final match = widget.options.cast<String?>().firstWhere(
          (o) => o!.toLowerCase() == t.toLowerCase(),
          orElse: () => null,
        );
    final tag = match ?? t;
    final next = Set<String>.from(widget.selected)..add(tag);
    if (match == null) {
      widget.onNovelTag?.call(tag);
    }
    widget.onChanged(next);
    _textCtrl.clear();
    // Keep focus for rapid multi-add.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _remove(String tag) {
    final next = Set<String>.from(widget.selected)..remove(tag);
    widget.onChanged(next);
  }

  Iterable<String> _filtered(String query) {
    final q = query.trim().toLowerCase();
    final selectedLower = widget.selected.map((s) => s.toLowerCase()).toSet();
    return widget.options.where((o) {
      if (selectedLower.contains(o.toLowerCase())) return false;
      if (q.isEmpty) return true;
      return o.toLowerCase().contains(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (widget.helperText != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final t in widget.selected)
                InputChip(
                  label: Text(t, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _remove(t),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        RawAutocomplete<String>(
          textEditingController: _textCtrl,
          focusNode: _focus,
          optionsBuilder: (value) => _filtered(value.text),
          onSelected: _commit,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Type to filter or add…',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Add tag',
                  icon: const Icon(Icons.add),
                  onPressed: () => _commit(controller.text),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: _commit,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final list = options.toList();
            if (list.isEmpty) {
              final typed = _textCtrl.text.trim();
              if (typed.isEmpty) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.add, size: 18),
                      title: Text('Add "$typed"'),
                      onTap: () => onSelected(typed),
                    ),
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final opt = list[i];
                      return ListTile(
                        dense: true,
                        title: Text(opt),
                        onTap: () => onSelected(opt),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
