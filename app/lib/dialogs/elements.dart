import 'package:butterfly/cubits/settings.dart';
import 'package:butterfly/dialogs/packs/asset.dart';
import 'package:butterfly/handlers/handler.dart';
import 'package:butterfly/services/export.dart';
import 'package:butterfly/visualizer/event.dart';
import 'package:butterfly/widgets/context_menu.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lw_sysinfo/lw_sysinfo.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../renderers/renderer.dart';
import '../bloc/document_bloc.dart';
import '../services/import.dart';

ContextMenuBuilder buildElementsContextMenu(
    DocumentBloc bloc,
    DocumentLoadSuccess state,
    SettingsCubit settingsCubit,
    ImportService importService,
    ExportService exportService,
    ClipboardManager clipboardManager,
    Offset position,
    List<Renderer<PadElement>> renderers,
    Rect? rect) {
  final cubit = state.currentIndexCubit;
  return (context) => [
        if (rect == null) ...[
          ContextMenuItem(
            onPressed: () {
              Navigator.of(context).pop(true);
              final clipboard = clipboardManager.getContent();
              if (clipboard == null) return;
              try {
                importService.import(
                    AssetFileType.values.byName(clipboard.type),
                    clipboard.data,
                    state.data,
                    position:
                        state.transformCubit.state.localToGlobal(position));
              } catch (_) {}
            },
            icon: const PhosphorIcon(PhosphorIconsLight.clipboard),
            label: AppLocalizations.of(context).paste,
          ),
        ] else ...[
          ContextMenuItem(
            onPressed: () {
              Navigator.of(context).pop(true);
              cubit
                  .fetchHandler<SelectHandler>()
                  ?.copySelection(bloc, clipboardManager, true);
            },
            icon: const PhosphorIcon(PhosphorIconsLight.scissors),
            label: AppLocalizations.of(context).cut,
          ),
          ContextMenuItem(
            onPressed: () {
              Navigator.of(context).pop(true);
              cubit
                  .fetchHandler<SelectHandler>()
                  ?.copySelection(bloc, clipboardManager, false);
            },
            icon: const PhosphorIcon(PhosphorIconsLight.copy),
            label: AppLocalizations.of(context).copy,
          ),
          ContextMenuItem(
            icon: const PhosphorIcon(PhosphorIconsLight.copy),
            onPressed: () async {
              Navigator.of(context).pop(true);
              final document = state.data;
              final assetService = state.assetService;
              final page = state.page;
              final transforms = renderers
                  .map((e) => Renderer.fromInstance(e.element))
                  .toList();
              for (final renderer in transforms) {
                await renderer.setup(document, assetService, page);
              }
              cubit
                  .fetchHandler<SelectHandler>()
                  ?.transform(bloc, transforms, null, true);
            },
            label: AppLocalizations.of(context).duplicate,
          ),
          ContextMenuItem(
            onPressed: () {
              Navigator.of(context).pop(true);
              final state = bloc.state;
              if (state is! DocumentLoadSuccess) return;
              final content = state.page.content;
              bloc.add(ElementsRemoved(
                  renderers.map((r) => content.indexOf(r.element)).toList()));
            },
            icon: const PhosphorIcon(PhosphorIconsLight.trash),
            label: AppLocalizations.of(context).delete,
          ),
          ContextMenuGroup(
            icon: const Icon(PhosphorIconsLight.layout),
            children: Arrangement.values
                .map((e) => MenuItemButton(
                      leadingIcon: Icon(e.icon(PhosphorIconsStyle.light)),
                      child: Text(e.getLocalizedName(context)),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        final state = bloc.state;
                        if (state is! DocumentLoadSuccess) return;
                        final content = state.page.content;
                        bloc.add(ElementsArranged(
                            e,
                            renderers
                                .map((r) => content.indexOf(r.element))
                                .toList()));
                      },
                    ))
                .toList(),
            label: AppLocalizations.of(context).arrange,
          ),
          if (renderers.length == 1 &&
              exportService.isExportable(renderers.first.element))
            ContextMenuItem(
              onPressed: () {
                Navigator.of(context).pop(true);
                exportService.export(renderers.first.element);
              },
              icon: const PhosphorIcon(PhosphorIconsLight.export),
              label: AppLocalizations.of(context).export,
            ),
          ContextMenuItem(
            onPressed: () {
              Navigator.of(context).pop(true);
              if (renderers.isEmpty) return;
              cubit.changeSelection(renderers.first);
              renderers.sublist(1).forEach((r) => cubit.insertSelection(r));
            },
            icon: const PhosphorIcon(PhosphorIconsLight.faders),
            label: AppLocalizations.of(context).properties,
          ),
          ContextMenuItem(
            icon: const PhosphorIcon(PhosphorIconsLight.plusCircle),
            label: AppLocalizations.of(context).addToPack,
            onPressed: () async {
              Navigator.of(context).pop();
              addToPack(
                context,
                bloc,
                settingsCubit,
                renderers.map((e) => e.element).toList(),
                rect,
              );
            },
          ),
        ],
      ];
}
