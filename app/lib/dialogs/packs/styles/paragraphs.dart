import 'package:butterfly/dialogs/name.dart';
import 'package:butterfly/models/defaults.dart';
import 'package:butterfly_api/butterfly_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../delete.dart';
import 'paragraph.dart';

class ParagraphsStyleView extends StatefulWidget {
  final TextStyleSheet value;
  final ValueChanged<TextStyleSheet> onChanged;

  const ParagraphsStyleView({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ParagraphsStyleView> createState() => _ParagraphsStyleViewState();
}

class _ParagraphsStyleViewState extends State<ParagraphsStyleView> {
  String? _currentStyle;

  @override
  void initState() {
    super.initState();

    _currentStyle = widget.value.paragraphProperties.keys.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant ParagraphsStyleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _currentStyle != null) {
      setState(() {
        if (!widget.value.paragraphProperties.containsKey(_currentStyle!)) {
          _currentStyle = widget.value.paragraphProperties.keys.firstOrNull;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = DocumentDefaults.getParagraphTranslations(context)
        .entries
        .where((element) =>
            !widget.value.paragraphProperties.containsKey(element.key));
    return Column(children: [
      Row(
        children: [
          Flexible(
            child: DropdownMenu<String?>(
              expandedInsets: const EdgeInsets.all(4),
              dropdownMenuEntries: [
                ...widget.value.paragraphProperties.entries.map(
                  (style) => DropdownMenuEntry(
                    value: style.key,
                    label: style.key,
                  ),
                ),
              ],
              initialSelection: _currentStyle,
              onSelected: (value) {
                setState(() {
                  _currentStyle = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const PhosphorIcon(PhosphorIconsLight.plus),
            tooltip: AppLocalizations.of(context).add,
            onPressed: () async {
              final name = await showDialog<String>(
                context: context,
                builder: (context) => NameDialog(
                  validator: defaultFileNameValidator(
                    context,
                    widget.value.paragraphProperties.keys.toList(),
                  ),
                ),
              );
              if (name == null) {
                return;
              }
              widget.onChanged(widget.value.copyWith(
                paragraphProperties: {
                  ...widget.value.paragraphProperties,
                  name: const DefinedParagraphProperty(),
                },
              ));
            },
          ),
          MenuAnchor(
            builder: defaultMenuButton(
              tooltip: AppLocalizations.of(context).addElement,
              enabled: translations.isNotEmpty,
            ),
            menuChildren: translations
                .where((element) =>
                    !widget.value.paragraphProperties.containsKey(element.key))
                .map(
                  (e) => MenuItemButton(
                    child: Text(e.value),
                    onPressed: () {
                      widget.onChanged(widget.value.copyWith(
                        paragraphProperties: {
                          ...widget.value.paragraphProperties,
                          e.key: const DefinedParagraphProperty(),
                        },
                      ));
                    },
                  ),
                )
                .toList(),
          ),
          if (_currentStyle != null) ...[
            const VerticalDivider(),
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsLight.pencil),
              tooltip: AppLocalizations.of(context).rename,
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => NameDialog(
                    value: _currentStyle,
                    validator: defaultFileNameValidator(
                      context,
                      widget.value.paragraphProperties.keys.toList(),
                    ),
                  ),
                );
                if (name == null) {
                  return;
                }
                final lastStyle = _currentStyle;
                _currentStyle = name;
                widget.onChanged(widget.value.copyWith(
                  paragraphProperties:
                      Map<String, DefinedParagraphProperty>.from(
                          widget.value.paragraphProperties)
                        ..remove(lastStyle)
                        ..[name] = widget.value.paragraphProperties[lastStyle]!,
                ));
              },
            ),
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsLight.trash),
              tooltip: AppLocalizations.of(context).delete,
              onPressed: () async {
                final result = await showDialog<bool>(
                    context: context, builder: (ctx) => const DeleteDialog());
                if (result != true) return;
                if (context.mounted) {
                  final lastStyle = _currentStyle;
                  _currentStyle = null;
                  widget.onChanged(widget.value.copyWith(
                    paragraphProperties:
                        Map<String, DefinedParagraphProperty>.from(
                            widget.value.paragraphProperties)
                          ..remove(lastStyle),
                  ));
                }
              },
            ),
          ]
        ],
      ),
      const SizedBox(height: 8),
      Flexible(
        child: Builder(
          builder: (context) {
            final currentParagraph =
                widget.value.paragraphProperties[_currentStyle];
            if (currentParagraph == null) {
              return const SizedBox();
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: ParagraphStyleView(
                    value: currentParagraph,
                    onChanged: (paragraph) {
                      widget.onChanged(widget.value.copyWith(
                        paragraphProperties: {
                          ...widget.value.paragraphProperties,
                          _currentStyle!: paragraph,
                        },
                      ));
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
