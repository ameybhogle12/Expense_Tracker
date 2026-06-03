import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/split_provider.dart';
import '../providers/tour_provider.dart';
import '../models/split_trip_model.dart';
import '../widgets/animations.dart';
import 'split_detail_screen.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen> {
  final GlobalKey _splitsFabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<TourProvider>().registerKey('splits_fab', _splitsFabKey);
      } catch (e) {
        debugPrint("Error registering Splits FAB key: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitProvider>();
    final trips = provider.trips;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Splits'),
        centerTitle: true,
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 80, color: colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No trips yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first group trip!',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                final total = provider.getTripTotal(trip.id);
                final expenseCount = provider.getExpensesForTrip(trip.id).length;

                return Dismissible(
                  key: ValueKey(trip.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_outline, color: colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Trip?'),
                        content: Text('This will permanently delete "${trip.name}" and all its expenses.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => provider.deleteTrip(trip.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            page: SplitDetailScreen(tripId: trip.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.flight_takeoff, color: colorScheme.onPrimaryContainer),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(trip.createdAt),
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${total.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                    ),
                                    Text(
                                      '$expenseCount expense${expenseCount == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Member avatars — compact row of circles with initials
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: trip.members.map((member) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getAvatarColor(member, colorScheme).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: _getAvatarColor(member, colorScheme),
                                        child: Text(
                                          member[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        member,
                                        style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        key: _splitsFabKey,
        onPressed: () => _showCreateTripDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateTripDialog(),
    );
  }

  Color _getAvatarColor(String name, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

// ─── Stateful Create Trip Dialog ──────────────────────────────
// Uses chip-based member input: type a name → press Enter → chip appears
class _CreateTripDialog extends StatefulWidget {
  const _CreateTripDialog();

  @override
  State<_CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<_CreateTripDialog> {
  final _nameController = TextEditingController();
  final _memberController = TextEditingController();
  final _memberFocus = FocusNode();
  final List<String> _members = [];

  @override
  void dispose() {
    _nameController.dispose();
    _memberController.dispose();
    _memberFocus.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty) return;
    if (_members.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name is already added!')),
      );
      return;
    }
    setState(() {
      _members.add(name);
      _memberController.clear();
    });
    _memberFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('New Trip'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g. Lonavala Day Trip',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            // ─── Member Input with Add button ───────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberController,
                    focusNode: _memberFocus,
                    decoration: InputDecoration(
                      labelText: 'Add Member',
                      hintText: 'e.g. Rahul',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _addMember,
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ─── Member Chips ────────────────────────────────
            if (_members.isEmpty)
              Text(
                'Type a name and press Enter to add',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _members.map((name) {
                  return InputChip(
                    label: Text(name, style: const TextStyle(fontSize: 13)),
                    avatar: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    onDeleted: () {
                      setState(() => _members.remove(name));
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            if (_members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_members.length} member${_members.length == 1 ? '' : 's'} added',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter a trip name!')),
              );
              return;
            }
            if (_members.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add at least 2 members!')),
              );
              return;
            }

            final trip = SplitTripModel(
              id: 'trip_${DateTime.now().microsecondsSinceEpoch}',
              name: name,
              members: _members,
              createdAt: DateTime.now(),
            );

            context.read<SplitProvider>().addTrip(trip);
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
