import 'package:flutter/material.dart';
import '../theme/rootery_theme.dart';
import '../models/app_models.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  List<Product> _filteredProducts = [];
  List<Product> _cartItems = [];

  // Mock data for marketplace - Raw dried agricultural products
  final List<Product> _mockProducts = [
    Product(
      id: '1',
      name: 'Dried Mango Slices',
      farm: 'Sunny Valley Farms',
      price: 899,
      unit: 'per kg',
      rating: 4.8,
      category: 'Fruits',
      stock: 45,
      imageUrl: 'assets/images/dried_mango.jfif',
      description:
          'Naturally sun-dried mango slices. No additives. Ideal for export or local distribution. Moisture content: 15%',
    ),
    Product(
      id: '2',
      name: 'Dried Tomatoes (Whole)',
      farm: 'Green Harvest Co.',
      price: 650,
      unit: 'per kg',
      rating: 4.6,
      category: 'Vegetables',
      stock: 32,
      imageUrl: 'assets/images/dried_tomatoes.jfif',
      description:
          'Premium sun-dried whole tomatoes. Perfect for food processing or culinary use. Moisture: 12%',
    ),
    Product(
      id: '3',
      name: 'Dried Banana (Sliced)',
      farm: 'Tropical Delight',
      price: 499,
      unit: 'per kg',
      rating: 4.9,
      category: 'Fruits',
      stock: 67,
      imageUrl: 'assets/images/dried_banana.jfif',
      description:
          'Pure dried banana slices, no sugar added. Ready for packaging or further processing. Moisture: 14%',
    ),
    Product(
      id: '4',
      name: 'Dried Basil Leaves',
      farm: 'Herb Garden Express',
      price: 320,
      unit: 'per 100g',
      rating: 4.7,
      category: 'Herbs',
      stock: 28,
      imageUrl: 'assets/images/dried_basil.jfif',
      description:
          'Aromatic dried basil leaves. Carefully dried to preserve essential oils. Ideal for spice companies.',
    ),
    Product(
      id: '5',
      name: 'Dried Apple Slices',
      farm: 'Orchard Fresh',
      price: 599,
      unit: 'per kg',
      rating: 4.5,
      category: 'Fruits',
      stock: 54,
      imageUrl: 'assets/images/dried_apple.jfif',
      description:
          'Clean dried apple slices, untreated. Perfect base material for snack producers. Moisture: 15%',
    ),
    Product(
      id: '6',
      name: 'Dried Bell Peppers (Diced)',
      farm: 'Rainbow Harvest',
      price: 750,
      unit: 'per kg',
      rating: 4.4,
      category: 'Vegetables',
      stock: 18,
      imageUrl: 'assets/images/dried_bell_peppers.jfif',
      description:
          'Mixed colored bell peppers, diced and dried. Ready for soup mixes and food service. Moisture: 10%',
    ),
    Product(
      id: '7',
      name: 'Dried Oregano',
      farm: 'Mediterranean Herbs',
      price: 280,
      unit: 'per 100g',
      rating: 4.8,
      category: 'Herbs',
      stock: 42,
      imageUrl: 'assets/images/dried_oregano.jfif',
      description:
          'Premium dried oregano leaves. High essential oil content. Perfect for spice distributors.',
    ),
    Product(
      id: '8',
      name: 'Dried Pineapple Rings',
      farm: 'Island Paradise',
      price: 849,
      unit: 'per kg',
      rating: 4.7,
      category: 'Fruits',
      stock: 36,
      imageUrl: 'assets/images/dried_pineapple.jfif',
      description:
          'Naturally sweet dried pineapple rings. No sulfites. Great for bulk distribution. Moisture: 16%',
    ),
    Product(
      id: '9',
      name: 'Dried Carrot Slices',
      farm: 'Root Vegetable Co.',
      price: 449,
      unit: 'per kg',
      rating: 4.3,
      category: 'Vegetables',
      stock: 25,
      imageUrl: 'assets/images/dried_carrot.jfif',
      description:
          'Sliced and dried carrots. Perfect for soup mixes, camping food, or pet treats. Moisture: 8%',
    ),
    Product(
      id: '10',
      name: 'Dried Mint Leaves',
      farm: 'Fresh Herb Farm',
      price: 299,
      unit: 'per 100g',
      rating: 4.6,
      category: 'Herbs',
      stock: 31,
      imageUrl: 'assets/images/dried_mint.jfif',
      description:
          'Clean dried mint leaves for tea blends and herbal products. Strong menthol content.',
    ),
    Product(
      id: '11',
      name: 'Dried Papaya Strips',
      farm: 'Tropical Valley',
      price: 799,
      unit: 'per kg',
      rating: 4.8,
      category: 'Fruits',
      stock: 29,
      imageUrl: 'assets/images/dried_papaya.jfif',
      description:
          'Premium dried papaya strips. Rich color retained. Ideal for health food distributors. Moisture: 18%',
    ),
    Product(
      id: '12',
      name: 'Dried Onion Flakes',
      farm: 'Valley Vegetables',
      price: 480,
      unit: 'per kg',
      rating: 4.5,
      category: 'Vegetables',
      stock: 48,
      imageUrl: 'assets/images/dried_onion.jfif',
      description:
          'Dehydrated onion flakes for food processing. Strong flavor, long shelf life. Moisture: 5%',
    ),
    Product(
      id: '13',
      name: 'Dried Chili Peppers',
      farm: 'Spice Mountain',
      price: 890,
      unit: 'per kg',
      rating: 4.9,
      category: 'Vegetables',
      stock: 38,
      imageUrl: 'assets/images/dried_chilli.jfif',
      description:
          'Whole dried red chili peppers. High heat level. Perfect for spice manufacturers. Moisture: 8%',
    ),
    Product(
      id: '14',
      name: 'Dried Coconut Strips',
      farm: 'Coastal Harvest',
      price: 650,
      unit: 'per kg',
      rating: 4.6,
      category: 'Fruits',
      stock: 55,
      imageUrl: 'assets/images/dried_coccnut.jfif',
      description:
          'Unsweetened dried coconut strips. Natural coconut flavor. For bakery and confectionery. Moisture: 3%',
    ),
    Product(
      id: '15',
      name: 'Dried Mushroom Slices',
      farm: 'Forest Foods Co.',
      price: 1200,
      unit: 'per kg',
      rating: 4.7,
      category: 'Vegetables',
      stock: 15,
      imageUrl: 'assets/images/dried_mushroom.jfif',
      description:
          'Premium dried mushroom slices. Rich umami flavor. Restaurant quality. Moisture: 10%',
    ),
    Product(
      id: '16',
      name: 'Dried Lemongrass',
      farm: 'Aromatic Herbs Ltd',
      price: 380,
      unit: 'per 100g',
      rating: 4.5,
      category: 'Herbs',
      stock: 22,
      imageUrl: 'assets/images/dried_lemongrass.jfif',
      description:
          'Dried lemongrass for tea and Asian cuisine. Strong citrus aroma. Food service grade.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  void _loadProducts() async {
    // Use mock data instead of data service
    setState(() {
      _filteredProducts = _mockProducts;
    });
  }

  void _filterProducts() async {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _mockProducts.where((product) {
        final matchesSearch =
            query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.farm.toLowerCase().contains(query);
        final matchesFilter =
            _selectedFilter == 'All' || product.category == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterProducts();
    });
  }

  void _addToCart(Product product) {
    setState(() {
      _cartItems.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: RooteryTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: _showCart,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: RooteryTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RooteryTheme.accentGreen.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: RooteryTheme.subText),
          prefixIcon: Icon(Icons.search, color: RooteryTheme.accentGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: RooteryTheme.subText),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Fruits', 'Vegetables', 'Herbs'];
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => _applyFilter(filter),
              backgroundColor: RooteryTheme.surface,
              selectedColor: RooteryTheme.accentGreen.withOpacity(0.3),
              checkmarkColor: RooteryTheme.accentGreen,
              labelStyle: TextStyle(
                color: isSelected ? RooteryTheme.accentGreen : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected
                    ? RooteryTheme.accentGreen
                    : RooteryTheme.subText.withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCart() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: RooteryTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCartSheet(),
    );
  }

  Widget _buildCartSheet() {
    final total = _cartItems.fold<double>(0, (sum, item) => sum + item.price);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shopping Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final product = _cartItems[index];
                return Card(
                  color: RooteryTheme.card,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: RooteryTheme.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: RooteryTheme.accentGreen,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      product.unit,
                      style: const TextStyle(color: RooteryTheme.subText),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'â‚¹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: RooteryTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _cartItems.removeAt(index);
                            });
                            Navigator.pop(context);
                            if (_cartItems.isNotEmpty) {
                              _showCart();
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: RooteryTheme.subText),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'â‚¹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: RooteryTheme.accentGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout feature coming soon!'),
                    backgroundColor: RooteryTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RooteryTheme.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: _showCart,
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: RooteryTheme.subText,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            color: RooteryTheme.subText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_filteredProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSearchBarOld() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: RooteryTheme.card,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: RooteryTheme.subText),
          prefixIcon: const Icon(Icons.search, color: RooteryTheme.subText),
          filled: true,
          fillColor: RooteryTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFilterChipsOld() {
    final filters = ['All', 'Fruits', 'Vegetables', 'Herbs'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => _applyFilter(filter),
                backgroundColor: RooteryTheme.card,
                selectedColor: RooteryTheme.accentGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : RooteryTheme.subText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? RooteryTheme.accentGreen
                        : RooteryTheme.subText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Get category-specific icon and color
    IconData categoryIcon;
    Color categoryColor;

    switch (product.category) {
      case 'Fruits':
        categoryIcon = Icons.apple;
        categoryColor = Colors.red;
        break;
      case 'Vegetables':
        categoryIcon = Icons.eco;
        categoryColor = Colors.green;
        break;
      case 'Herbs':
        categoryIcon = Icons.spa;
        categoryColor = Colors.purple;
        break;
      default:
        categoryIcon = Icons.inventory_2;
        categoryColor = RooteryTheme.accentGreen;
    }

    return Card(
      color: RooteryTheme.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? Image.asset(
                            product.imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      categoryColor.withOpacity(0.3),
                                      categoryColor.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    categoryIcon,
                                    size: 56,
                                    color: categoryColor,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  categoryColor.withOpacity(0.3),
                                  categoryColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                categoryIcon,
                                size: 56,
                                color: categoryColor,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              color: RooteryTheme.subText,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.farm,
                                style: const TextStyle(
                                  color: RooteryTheme.subText,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.stock > 30
                                ? RooteryTheme.accentGreen.withOpacity(0.2)
                                : product.stock > 15
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory,
                                size: 10,
                                color: product.stock > 30
                                    ? RooteryTheme.accentGreen
                                    : product.stock > 15
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.stock} in stock',
                                style: TextStyle(
                                  color: product.stock > 30
                                      ? RooteryTheme.accentGreen
                                      : product.stock > 15
                                      ? Colors.orange
                                      : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'â‚¹${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: RooteryTheme.accentGreen,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  product.unit,
                                  style: const TextStyle(
                                    color: RooteryTheme.subText,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: RooteryTheme.accentGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RooteryTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RooteryTheme.subText,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        RooteryTheme.accentGreen.withOpacity(0.3),
                        RooteryTheme.accentGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: RooteryTheme.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.store,
                      color: RooteryTheme.subText,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.farm,
                      style: const TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: RooteryTheme.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: product.stock > 20
                            ? RooteryTheme.accentGreen.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${product.stock} in stock',
                        style: TextStyle(
                          color: product.stock > 20
                              ? RooteryTheme.accentGreen
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: const TextStyle(
                    color: RooteryTheme.subText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(
                            color: RooteryTheme.subText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'â‚¹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: RooteryTheme.accentGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.unit,
                          style: const TextStyle(
                            color: RooteryTheme.subText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _addToCart(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RooteryTheme.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

