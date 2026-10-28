import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/search_filter.dart';
import '../core/tags.dart';
import '../data/db.dart';
import '../providers.dart';
import 'expenses.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  SearchFilter _f = const SearchFilter();
  final _min = TextEditingController();
  final _max = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final init = (from ? _f.from : _f.to) ?? DateTime.now();
    final d = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d == null) return;
    setState(() => _f = from ? _f.copyWith(from: d) : _f.copyWith(to: d));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final all = ref.watch(allExpensesProvider).valueOrNull ?? const <Expense>[];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final catMap = {for (final c in cats) c.id: c};
    final rates = ref.watch(rateTableProvider);
    final display = ref.watch(currencyProvider);
    final space = ref.watch(spaceIdProvider);
    final members = ref.watch(isSharedSpaceProvider) ? (ref.watch(membersProvider(space)).valueOrNull ?? const <MemberInfo>[]) : const <MemberInfo>[];

    final allTags = <String, int>{};
    for (final e in all) {
      for (final tag in splitTags(e.tags)) {
        allTags[tag] = (allTags[tag] ?? 0) + 1;
      }
    }
    final topTags = (allTags.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(12).map((e) => e.key).toList();

    final results = [
      for (final e in all)
        if (matchesFilter(_f,
            note: e.note,
            tags: e.tags,
            categoryName: catMap[e.categoryId]?.name ?? '',
            categoryId: e.categoryId,
            amount: rates.convert(e.amountMinor, e.currency, display.code),
            at: e.spentAt,
            hasReceipt: e.attachmentId != null))
          e,
    ];
    var total = 0;
    for (final e in results) {
      total += rates.convert(e.amountMinor, e.currency, display.code) ?? 0;
    }
    final dateFmt = context.dayLabelFull;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: t.searchHint, border: InputBorder.none),
          onChanged: (v) => setState(() => _f = _f.copyWith(query: v)),
        ),
        actions: [
          IconButton(
            tooltip: t.filters,
            icon: Badge(isLabelVisible: _f.copyWith(query: '').isEmpty == false, child: const Icon(Icons.tune)),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(children: [
        if (_showFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [
                ActionChip(
                  avatar: const Icon(Icons.event, size: 16),
                  label: Text(_f.from == null ? t.fromDate : dateFmt(_f.from!.millisecondsSinceEpoch)),
                  onPressed: () => _pickDate(from: true),
                ),
                ActionChip(
                  avatar: const Icon(Icons.event, size: 16),
                  label: Text(_f.to == null ? t.toDate : dateFmt(_f.to!.millisecondsSinceEpoch)),
                  onPressed: () => _pickDate(from: false),
                ),
                if (_f.from != null || _f.to != null)
                  ActionChip(label: Text(t.clearDates), onPressed: () => setState(() => _f = _f.copyWith(clearFrom: true, clearTo: true))),
              ]),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.minAmount, suffixText: display.symbol),
                    onChanged: (v) => setState(() {
                      final m = parseMinor(v, display.decimals);
                      _f = m == null ? _f.copyWith(clearMin: true) : _f.copyWith(minMinor: m);
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.maxAmount, suffixText: display.symbol),
                    onChanged: (v) => setState(() {
                      final m = parseMinor(v, display.decimals);
                      _f = m == null ? _f.copyWith(clearMax: true) : _f.copyWith(maxMinor: m);
                    }),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(t.category, style: Theme.of(context).textTheme.labelMedium),
              Wrap(spacing: 8, children: [
                for (final c in cats)
                  FilterChip(
                    label: Text(c.name),
                    selected: _f.categoryIds.contains(c.id),
                    onSelected: (s) => setState(() {
                      final next = {..._f.categoryIds};
                      s ? next.add(c.id) : next.remove(c.id);
                      _f = _f.copyWith(categoryIds: next);
                    }),
                  ),
                FilterChip(
                  label: Text(t.noCategory),
                  selected: _f.categoryIds.contains(''),
                  onSelected: (s) => setState(() {
                    final next = {..._f.categoryIds};
                    s ? next.add('') : next.remove('');
                    _f = _f.copyWith(categoryIds: next);
                  }),
                ),
              ]),
              if (topTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(t.tags, style: Theme.of(context).textTheme.labelMedium),
                Wrap(spacing: 8, children: [
                  for (final tag in topTags)
                    FilterChip(
                      label: Text('#$tag'),
                      selected: _f.tag == tag,
                      onSelected: (s) => setState(() => _f = s ? _f.copyWith(tag: tag) : _f.copyWith(clearTag: true)),
                    ),
                ]),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.onlyWithReceipt),
                value: _f.onlyWithReceipt,
                onChanged: (v) => setState(() => _f = _f.copyWith(onlyWithReceipt: v)),
              ),
              const Divider(),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: Text(t.resultsCount(results.length))),
            Text(formatMinor(total, display), style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(child: Text(_f.isEmpty ? t.searchPrompt : t.noResults))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => ExpenseTile(expense: results[i], categories: catMap, members: members),
                ),
        ),
      ]),
    );
  }
}
