import 'dart:isolate';
import 'dart:math';

import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/helpers/point_helper.dart';
import 'package:butterfly/visualizer/element.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

Future<List<SearchResult>> _searchIsolate(AppDocument document, String query) =>
    Isolate.run(() => document.search(RegExp(query, caseSensitive: false)));

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<SearchResult>> _searchResults = Future.value([]);

  void _search(AppDocument document, String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = Future.value([]);
      } else {
        _searchResults = _searchIsolate(document, query);
      }
    });
  }

  IconData _getIcon(Object item) {
    if (item is PadElement) {
      item.getIcon();
    }
    if (item is Waypoint) {
      return PhosphorIcons.mapPinLight;
    }
    if (item is Area) {
      return PhosphorIcons.selectionLight;
    }
    return PhosphorIcons.questionLight;
  }

  String _getLocalizedName(Object item, BuildContext context) {
    if (item is PadElement) {
      return item.getLocalizedName(context);
    }
    if (item is Waypoint) {
      return AppLocalizations.of(context).waypoint;
    }
    if (item is Area) {
      return AppLocalizations.of(context).area;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: min(constraints.maxWidth, 600),
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Flexible(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).search,
                              filled: true,
                            ),
                            autofocus: true,
                            controller: _searchController,
                            onChanged: (value) {
                              final state = context.read<DocumentBloc>().state;
                              if (state is DocumentLoaded) {
                                _search(state.document, value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: FutureBuilder<List<SearchResult>>(
                          future: _searchResults,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(snapshot.error.toString());
                            }
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  CircularProgressIndicator(),
                                ],
                              );
                            }
                            final results = snapshot.data ?? [];
                            return ListView.builder(
                              itemCount: results.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                final result = results[index];
                                return ListTile(
                                  leading: Icon(_getIcon(result.item)),
                                  title: Text(
                                      _getLocalizedName(result.item, context)),
                                  subtitle: Text(result.name),
                                  onTap: () {
                                    final state =
                                        context.read<DocumentBloc>().state;
                                    if (state is DocumentLoaded) {
                                      state.transformCubit.setPosition(
                                          result.location.toOffset());
                                      state.currentIndexCubit
                                          .bake(state.document);
                                      Navigator.pop(context);
                                    }
                                  },
                                );
                              },
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}