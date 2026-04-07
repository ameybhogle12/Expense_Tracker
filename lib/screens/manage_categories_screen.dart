import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category_model.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
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
                        title: const Text("Confirm Delete"),
                        content: Text("Are you sure you want to delete '${category.name}'?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (_) {
                  provider.deleteCategory(category);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${category.name} deleted')));
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category.colorValue).withOpacity(0.2),
                    child: Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(category.colorValue)),
                  ),
                  title: Text(category.name),
                  subtitle: Text(category.isCustom ? 'Custom Category' : 'Default Category'),
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
        label: const Text('New Category'),
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
    return AlertDialog(
      title: const Text('Create Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
              return;
            }
            
            final provider = context.read<ExpenseProvider>();
            if (provider.getCategoryByName(name) != null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category already exists')));
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
          child: const Text('Create'),
        ),
      ],
    );
  }
}
