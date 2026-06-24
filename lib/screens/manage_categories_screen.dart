import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category_model.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddCategoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          
          if (categories.isEmpty) {
            return Center(child: Text(l10n.noCategoriesFound));
          }

          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Dismissible(
                key: ValueKey(category.id),
                direction: category.isCustom ? DismissDirection.endToStart : DismissDirection.none,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(l10n.confirmDelete),
                        content: Text(l10n.confirmDeleteCategoryMsg(category.name)),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (_) {
                  provider.deleteCategory(category);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryDeleted(category.name))));
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category.colorValue).withOpacity(0.2),
                    child: Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(category.colorValue)),
                  ),
                  title: Text(category.name),
                  subtitle: Text(category.isCustom ? l10n.customCategory : l10n.defaultCategory),
                  trailing: category.isCustom ? const Icon(Icons.swipe_left, size: 16, color: Colors.grey) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCategory),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  
  final List<Color> _vibrantColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.orange, Colors.deepOrange, Colors.brown, Colors.blueGrey,
  ];
  
  final List<IconData> _curatedIcons = [
    Icons.shopping_cart, Icons.fastfood, Icons.local_cafe, Icons.flight,
    Icons.directions_car, Icons.train, Icons.hotel, Icons.local_hospital,
    Icons.fitness_center, Icons.sports_esports, Icons.movie, Icons.music_note,
    Icons.pets, Icons.school, Icons.work, Icons.home,
    Icons.build, Icons.auto_awesome, Icons.favorite, Icons.star,
  ];

  late Color _selectedColor;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedColor = _vibrantColors[0];
    _selectedIcon = _curatedIcons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.createCategory),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            Text(l10n.selectColor, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _vibrantColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 16,
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(l10n.selectIcon, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _curatedIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? _selectedColor : Colors.grey.shade300),
                    ),
                    child: Icon(icon, color: isSelected ? _selectedColor : Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterName)));
              return;
            }
            
            final provider = context.read<ExpenseProvider>();
            if (provider.getCategoryByName(name) != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryAlreadyExists)));
              return;
            }

            final newCategory = CategoryModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              colorValue: _selectedColor.value,
              iconCodePoint: _selectedIcon.codePoint,
              isCustom: true,
            );
            
            provider.addCategory(newCategory);
            Navigator.of(context).pop();
          },
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
