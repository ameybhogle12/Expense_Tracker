import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/split_trip_model.dart';
import '../models/split_expense_model.dart';
import '../providers/split_provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class BillItem {
  String id;
  String name;
  double price;
  List<String> assignedMembers;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    required this.assignedMembers,
  });
}

class ItemizedSplitterScreen extends StatefulWidget {
  final SplitTripModel trip;

  const ItemizedSplitterScreen({super.key, required this.trip});

  @override
  State<ItemizedSplitterScreen> createState() => _ItemizedSplitterScreenState();
}

class _ItemizedSplitterScreenState extends State<ItemizedSplitterScreen> {
  int _selectedModeIndex = 0; // 0: Quick Mode, 1: Fun Mode
  final AudioPlayer _audioPlayer = AudioPlayer();

  late String _paidBy;
  final List<BillItem> _items = [];

  final _taxController = TextEditingController();
  final _tipController = TextEditingController();

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  List<String> _selectedMembersForItem = [];

  @override
  void initState() {
    super.initState();
    _paidBy = widget.trip.members.isNotEmpty ? widget.trip.members.first : '';
    _selectedMembersForItem = List<String>.from(widget.trip.members);
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _taxController.dispose();
    _tipController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  double get _taxPercent => double.tryParse(_taxController.text.trim()) ?? 0.0;
  double get _tipPercent => double.tryParse(_tipController.text.trim()) ?? 0.0;

  double get _itemsSubtotal => _items.fold(0.0, (sum, item) => sum + item.price);

  double get _taxAmount => _itemsSubtotal * (_taxPercent / 100.0);
  double get _tipAmount => _itemsSubtotal * (_tipPercent / 100.0);
  double get _grandTotal => _itemsSubtotal + _taxAmount + _tipAmount;

  // Calculates exact per-member total (subtotal + proportional tax/tip)
  Map<String, double> _calculateMemberTotals() {
    final Map<String, double> memberSubtotals = {};
    for (final member in widget.trip.members) {
      memberSubtotals[member] = 0.0;
    }

    for (final item in _items) {
      if (item.assignedMembers.isEmpty) continue;
      final share = item.price / item.assignedMembers.length;
      for (final member in item.assignedMembers) {
        memberSubtotals[member] = (memberSubtotals[member] ?? 0.0) + share;
      }
    }

    final double multiplier = _itemsSubtotal > 0
        ? (1.0 + (_taxPercent + _tipPercent) / 100.0)
        : 1.0;

    final Map<String, double> finalTotals = {};
    memberSubtotals.forEach((member, subtotal) {
      finalTotals[member] = double.parse((subtotal * multiplier).toStringAsFixed(2));
    });

    return finalTotals;
  }

  void _showAddItemModal([BillItem? existingItem]) {
    if (existingItem != null) {
      _itemNameController.text = existingItem.name;
      _itemPriceController.text = existingItem.price.toString();
      _selectedMembersForItem = List<String>.from(existingItem.assignedMembers);
    } else {
      _itemNameController.clear();
      _itemPriceController.clear();
      _selectedMembersForItem = List<String>.from(widget.trip.members);
    }

    final currency = context.read<CurrencyProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final colorScheme = Theme.of(modalCtx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingItem == null ? 'Add Bill Item' : 'Edit Bill Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemNameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Item Name (e.g. Pastry, Garlic Bread)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fastfood_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixText: '${currency.symbol} ',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Members:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (_selectedMembersForItem.length == widget.trip.members.length) {
                              _selectedMembersForItem.clear();
                            } else {
                              _selectedMembersForItem = List<String>.from(widget.trip.members);
                            }
                          });
                        },
                        child: Text(
                          _selectedMembersForItem.length == widget.trip.members.length
                              ? 'Deselect All'
                              : 'Select All',
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.trip.members.map((m) {
                      final isSelected = _selectedMembersForItem.contains(m);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(m),
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.onPrimaryContainer,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              _selectedMembersForItem.add(m);
                            } else {
                              _selectedMembersForItem.remove(m);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final name = _itemNameController.text.trim();
                        final price = double.tryParse(_itemPriceController.text.trim());

                        if (name.isEmpty || price == null || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid item name and price')),
                          );
                          return;
                        }
                        if (_selectedMembersForItem.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select at least one member for this item')),
                          );
                          return;
                        }

                        setState(() {
                          if (existingItem != null) {
                            existingItem.name = name;
                            existingItem.price = price;
                            existingItem.assignedMembers = List<String>.from(_selectedMembersForItem);
                          } else {
                            _items.add(BillItem(
                              id: 'bi_${DateTime.now().microsecondsSinceEpoch}',
                              name: name,
                              price: price,
                              assignedMembers: List<String>.from(_selectedMembersForItem),
                            ));
                          }
                        });
                        Navigator.pop(modalCtx);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(existingItem == null ? 'Add Item' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAllExpenses() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one bill item to split')),
      );
      return;
    }

    final double multiplier = _itemsSubtotal > 0
        ? (1.0 + (_taxPercent + _tipPercent) / 100.0)
        : 1.0;

    final provider = context.read<SplitProvider>();
    final now = DateTime.now();

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final itemTotalWithTax = double.parse((item.price * multiplier).toStringAsFixed(2));

      final expense = SplitExpenseModel(
        id: 'se_${now.microsecondsSinceEpoch}_$i',
        tripId: widget.trip.id,
        amount: itemTotalWithTax,
        description: '${item.name} (Itemized)',
        paidBy: _paidBy,
        splitAmong: item.assignedMembers,
        date: now,
      );

      await provider.addExpense(expense);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${_items.length} itemized expense(s)!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;
    final memberTotals = _calculateMemberTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itemized Bill Splitter'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context, 'open_equal_split');
            },
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('Equal Split'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector (Quick Mode vs Fun Mode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('⚡ Quick Mode'),
                  icon: Icon(Icons.flash_on_outlined),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('🎨 Fun Mode'),
                  icon: Icon(Icons.style_outlined),
                ),
              ],
              selected: {_selectedModeIndex},
              onSelectionChanged: (newSelection) async {
                final newIndex = newSelection.first;
                setState(() {
                  _selectedModeIndex = newIndex;
                });
                if (newIndex == 1) {
                  try {
                    await _audioPlayer.stop();
                    await _audioPlayer.play(AssetSource('meme/gta-san-andreas-male-panic-crying-scream.mp3'));
                  } catch (_) {}
                } else {
                  try {
                    await _audioPlayer.stop();
                  } catch (_) {}
                }
              },
            ),
          ),

          Expanded(
            child: _selectedModeIndex == 0
                ? _buildQuickMode(colorScheme, currency, l10n, memberTotals)
                : _buildFunModeTeaser(colorScheme),
          ),
        ],
      ),
      bottomNavigationBar: _selectedModeIndex == 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: _items.isEmpty ? null : _saveAllExpenses,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Save ${_items.length} Itemized Expense(s) (${currency.symbol}${_grandTotal.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildQuickMode(
    ColorScheme colorScheme,
    CurrencyProvider currency,
    AppLocalizations l10n,
    Map<String, double> memberTotals,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _paidBy,
                    decoration: const InputDecoration(
                      labelText: 'Who Paid the Whole Bill?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                    items: widget.trip.members
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _paidBy = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taxController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tax (%)',
                            hintText: 'e.g. 5',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tipController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tip / Service (%)',
                            hintText: 'e.g. 10',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bill Items List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill Items (${_items.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddItemModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (_items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.secondary.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  const Text(
                    'No items added yet',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Add Item" above to add pastries, drinks, or desserts!',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (ctx, idx) {
                final item = _items[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${currency.symbol}${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        children: item.assignedMembers.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddItemModal(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _items.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Live Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Per-Person Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Icon(Icons.pie_chart_outline, size: 20, color: colorScheme.primary),
                    ],
                  ),
                  const Divider(height: 20),
                  ...widget.trip.members.map((m) {
                    final total = memberTotals[m] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m, style: const TextStyle(fontSize: 14)),
                          Text(
                            '${currency.symbol}${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: total > 0 ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_taxPercent > 0 || _tipPercent > 0) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Subtotal: ${currency.symbol}${_itemsSubtotal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        Text(
                          '+ Tax/Tip (${(_taxPercent + _tipPercent).toStringAsFixed(1)}%): ${currency.symbol}${(_taxAmount + _tipAmount).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunModeTeaser(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/meme/Wait_Guys.png',
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) {
                  return Icon(
                    Icons.engineering_outlined,
                    size: 100,
                    color: colorScheme.primary,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Developer is working hard on this, please be patient',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
