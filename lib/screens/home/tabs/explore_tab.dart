import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/item_service.dart';
import '../../../models/item_model.dart';
import '../../../widgets/item_card.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final ItemService _itemService = ItemService();
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  double _minValue = 0;
  double _maxValue = 10000;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Home & Garden',
    'Sports',
    'Toys',
    'Other',
  ];

  final List<String> _conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userLocation = authProvider.userProfile?.location;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Explore'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search items... ✨',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : 'All';
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Items Grid
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: _itemService.getItems(
                userLocation: userLocation,
                radiusKm: 50,
                limit: 50,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildMessage(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    subtitle: 'Please try again later',
                  );
                }

                final items = snapshot.data ?? [];
                final filteredItems = _filterItems(items);

                if (filteredItems.isEmpty) {
                  return _buildMessage(
                    icon: Icons.search_off,
                    title: 'No items found',
                    subtitle: 'Try adjusting your filters',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return ItemCard(
                      item: filteredItems[index],
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/item-details',
                          arguments: filteredItems[index],
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  List<ItemModel> _filterItems(List<ItemModel> items) {
    return items.where((item) {
      if (_selectedCategory != 'All' && !item.tags.contains(_selectedCategory)) {
        return false;
      }
      if (_selectedCondition != 'All') {
        final conditionMap = {
          'New': ItemCondition.new_,
          'Like New': ItemCondition.likeNew,
          'Good': ItemCondition.good,
          'Fair': ItemCondition.fair,
          'Poor': ItemCondition.poor,
        };
        if (item.condition != conditionMap[_selectedCondition]) {
          return false;
        }
      }
      if (item.estimatedValue < _minValue || item.estimatedValue > _maxValue) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCondition = value!);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Value Range: \$${_minValue.toInt()} - \$${_maxValue.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            RangeSlider(
              values: RangeValues(_minValue, _maxValue),
              min: 0,
              max: 10000,
              divisions: 100,
              labels: RangeLabels(
                '\$${_minValue.toInt()}',
                '\$${_maxValue.toInt()}',
              ),
              onChanged: (values) {
                setState(() {
                  _minValue = values.start;
                  _maxValue = values.end;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _selectedCondition = 'All';
                _minValue = 0;
                _maxValue = 10000;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
