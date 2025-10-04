import 'package:flutter/material.dart';
import '../models/product_type.dart';
import '../models/product.dart';
import '../services/tech_api_service.dart';
import '../services/global_cart_service.dart';
import 'product_detail_screen.dart';

class AllTypesScreen extends StatefulWidget {
  final List<ProductType> types;

  const AllTypesScreen({super.key, required this.types});

  @override
  State<AllTypesScreen> createState() => _AllTypesScreenState();
}

class _AllTypesScreenState extends State<AllTypesScreen> {
  final _cartService = globalCartService;
  ProductType? _selectedType;
  List<Product> _filteredProducts = [];
  bool _isLoadingProducts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1C69),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Types Grid
          Expanded(
            flex: _selectedType == null ? 1 : 0,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: widget.types.length,
              itemBuilder: (context, index) {
                final type = widget.types[index];
                final isSelected = _selectedType?.id == type.id;
                
                return GestureDetector(
                  onTap: () => _onTypeTap(type),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _getTypeColor(index) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? _getTypeColor(index).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (type.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              type.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  _getTypeIcon(type.name),
                                  size: 60,
                                  color: _getTypeColor(index),
                                );
                              },
                            ),
                          )
                        else
                          Icon(
                            _getTypeIcon(type.name),
                            size: 60,
                            color: _getTypeColor(index),
                          ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            type.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? _getTypeColor(index) : const Color(0xFF1E1C69),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Products Section
          if (_selectedType != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedType!.name} Products',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1C69),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _filteredProducts = [];
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _isLoadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found for this category',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getTypeIcon(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'laptop':
        return Icons.laptop;
      case 'mobile':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'fridge':
        return Icons.kitchen;
      default:
        return Icons.devices;
    }
  }

  Color _getTypeColor(int index) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
    ];
    return colors[index % colors.length];
  }

  Future<void> _onTypeTap(ProductType type) async {
    setState(() {
      _selectedType = type;
      _isLoadingProducts = true;
      _filteredProducts = [];
    });

    try {
      final products = await TechApiService.getProducts(typeId: type.id);
      setState(() {
        _filteredProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      color: Color(0xFFF5F5F5),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if (product.isDiscountItem)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1C69),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF316AE9),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _cartService.addToCart(product);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: const Color(0xFF4CAF50),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          setState(() {});
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

