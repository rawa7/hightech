import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/tech_api_service.dart';
import '../services/api_service.dart';
import '../services/global_cart_service.dart';
import '../services/order_service.dart';
import '../models/user.dart';
import '../models/banner.dart' as banner_model;
import '../models/home_data.dart';
import '../models/product.dart';
import '../models/brand.dart';
import '../models/product_type.dart';
import 'product_detail_screen.dart';
import 'order_confirmation_screen.dart';
import 'order_history_screen.dart';
import 'points_report_screen.dart';
import 'points_shop_screen.dart';
import 'all_brands_screen.dart';
import 'all_types_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cartService = globalCartService;
  final _orderService = OrderService();
  int _currentIndex = 0;
  User? _currentUser;
  HomeData? _homeData;
  List<banner_model.Banner> _banners = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PageController _bannerPageController = PageController();
  int _currentBannerPage = 0;
  
  // Filters
  Brand? _selectedBrandFilter;
  ProductType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First get local user
      final localUser = await UserService.getUser();
      
      // Fetch data from API in parallel
      final results = await Future.wait([
        TechApiService.getHomeData(),
        TechApiService.getBanners(),
      ]);
      
      final homeData = results[0] as HomeData?;
      final banners = results[1] as List<banner_model.Banner>;
      
      // Refresh user data from API if user is logged in
      User? currentUser = localUser;
      if (localUser != null) {
        try {
          final userProfile = await ApiService.getUserProfile(localUser.id);
          if (userProfile['success'] == true && userProfile['user'] != null) {
            currentUser = userProfile['user'] as User;
            await UserService.saveUser(currentUser);
          }
        } catch (e) {
          debugPrint('Error refreshing user data: $e');
        }
      }

      setState(() {
        _currentUser = currentUser;
        _homeData = homeData;
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await UserService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentView(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0: // Home
        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                if (_banners.isNotEmpty) _buildBannerCarousel(),
                if (_homeData != null) ...[
                  if (_homeData!.types.isNotEmpty) _buildCategoriesSection(),
                  if (_homeData!.brands.isNotEmpty) _buildBrandsSection(),
                  if (_homeData!.discountItems.isNotEmpty) _buildDiscountItemsSection(),
                  if (_homeData!.newItems.isNotEmpty) _buildNewItemsSection(),
                  if (_homeData!.pickedItems.isNotEmpty) _buildPickedItemsSection(),
                  if (_homeData!.mostSales.isNotEmpty) _buildMostSalesSection(),
                  if (_homeData!.mostPoints.isNotEmpty) _buildMostPointsSection(),
                ],
              ],
            ),
          ),
        );
      case 1: // Shop
        return _buildShopView();
      case 2: // Cart
        return _buildCartView();
      case 3: // Points Shop
        return const PointsShopScreen();
      case 4: // Profile
        return ProfileScreen(
          user: _currentUser,
          onLogout: _logout,
          onRefresh: _loadData,
        );
      default:
        return const Center(child: Text('Home'));
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF316AE9), Color(0xFF1E1C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF316AE9).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser != null ? 'Welcome, ${_currentUser!.fullName.split(' ')[0]}!' : 'HighTech Store',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Find your perfect device',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Points Display
              if (_currentUser != null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PointsReportScreen(userId: _currentUser!.id),
                      ),
                    );
                    _loadData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentUser!.points}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      height: 180,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerPageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerPage = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () {
                  // Handle banner tap - navigate based on link
                  if (banner.link != null && banner.link!.isNotEmpty) {
                    // Navigate based on link
                    setState(() {
                      _currentIndex = 1; // Go to shop
                    });
                  } else {
                    // Default action - go to shop
                    setState(() {
                      _currentIndex = 1;
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background gradient (fallback)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF316AE9), Color(0xFF1E1C69)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Banner image (main content)
                        if (banner.imageUrl.isNotEmpty)
                          Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultBannerContent(banner);
                            },
                          )
                        else
                          _buildDefaultBannerContent(banner),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Page indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _banners.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentBannerPage == index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentBannerPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultBannerContent(banner_model.Banner banner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF316AE9), Color(0xFF1E1C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_offer,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1C69),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllTypesScreen(types: _homeData!.types),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text('See All', style: TextStyle(color: Color(0xFF316AE9))),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF316AE9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _homeData!.types.length,
              itemBuilder: (context, index) {
                final type = _homeData!.types[index];
                return _buildCategoryCard(type, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ProductType type, int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 1; // Switch to shop
          _selectedTypeFilter = type;
          _selectedBrandFilter = null;
        });
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: type.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        type.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getTypeIcon(type.name),
                            color: Colors.white,
                            size: 32,
                          );
                        },
                      ),
                    )
                  : Icon(
                      _getTypeIcon(type.name),
                      color: Colors.white,
                      size: 32,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              type.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1C69),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

  Widget _buildBrandsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Brands',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1C69),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllBrandsScreen(brands: _homeData!.brands),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text('See All', style: TextStyle(color: Color(0xFF316AE9))),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF316AE9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _homeData!.brands.length,
              itemBuilder: (context, index) {
                final brand = _homeData!.brands[index];
                return _buildBrandCard(brand);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(Brand brand) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 1; // Switch to shop
          _selectedBrandFilter = brand;
          _selectedTypeFilter = null;
        });
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (brand.imageUrl.isNotEmpty)
              Image.network(
                brand.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _getBrandIcon(brand.name);
                },
              )
            else
              _getBrandIcon(brand.name),
            const SizedBox(height: 8),
            Text(
              brand.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1C69),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBrandIcon(String brandName) {
    IconData icon;
    switch (brandName.toLowerCase()) {
      case 'apple':
        icon = Icons.apple;
        break;
      case 'samsung':
        icon = Icons.smartphone;
        break;
      case 'lenovo':
        icon = Icons.laptop;
        break;
      case 'lg':
        icon = Icons.tv;
        break;
      default:
        icon = Icons.business;
    }
    return Icon(icon, size: 50, color: const Color(0xFF316AE9));
  }

  Widget _buildDiscountItemsSection() {
    return _buildProductSection(
      title: '🔥 Hot Deals',
      products: _homeData!.discountItems,
      icon: Icons.local_fire_department,
      color: Colors.red,
    );
  }

  Widget _buildNewItemsSection() {
    return _buildProductSection(
      title: '✨ New Arrivals',
      products: _homeData!.newItems,
      icon: Icons.fiber_new,
      color: const Color(0xFF4CAF50),
    );
  }

  Widget _buildPickedItemsSection() {
    return _buildProductSection(
      title: '⭐ Editor\'s Pick',
      products: _homeData!.pickedItems,
      icon: Icons.star,
      color: Colors.amber,
    );
  }

  Widget _buildMostSalesSection() {
    return _buildProductSection(
      title: '🏆 Best Sellers',
      products: _homeData!.mostSales,
      icon: Icons.trending_up,
      color: const Color(0xFF316AE9),
    );
  }

  Widget _buildMostPointsSection() {
    return _buildProductSection(
      title: '💎 Earn More Points',
      products: _homeData!.mostPoints,
      icon: Icons.diamond,
      color: Colors.purple,
    );
  }

  Widget _buildProductSection({
    required String title,
    required List<Product> products,
    required IconData icon,
    required Color color,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1C69),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
            ),
          ),
        ],
      ),
    );
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
        width: 180,
        margin: const EdgeInsets.only(right: 16),
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
            Stack(
              children: [
                Container(
                  height: 160,
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
                if (product.isPicked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.price}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF316AE9),
                              ),
                            ),
                            if (product.pointsEarnedAsInt > 0)
                              Row(
                                children: [
                                  const Icon(Icons.stars, size: 12, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+${product.pointsEarnedAsInt}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () async {
                            await _cartService.addToCart(product);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('${product.name} added to cart'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF4CAF50),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setState(() {});
                          },
                          child: Container(
                            width: 40,
                            height: 40,
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
            ),
          ],
        ),
      ),
    );
  }

  // Continue with shop, cart and other views from original file...
  Widget _buildShopView() {
    // Get unique products (remove duplicates based on product ID)
    final allProductsMap = <String, Product>{};
    if (_homeData != null) {
      for (var product in _homeData!.newItems) {
        allProductsMap[product.id] = product;
      }
      for (var product in _homeData!.discountItems) {
        allProductsMap[product.id] = product;
      }
      for (var product in _homeData!.pickedItems) {
        allProductsMap[product.id] = product;
      }
      for (var product in _homeData!.mostSales) {
        allProductsMap[product.id] = product;
      }
      for (var product in _homeData!.mostPoints) {
        allProductsMap[product.id] = product;
      }
    }
    final allProducts = allProductsMap.values.toList();

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // Filters
        if (_homeData != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Brand Filter
                  PopupMenuButton<Brand?>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedBrandFilter != null 
                            ? const Color(0xFF316AE9) 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _selectedBrandFilter != null 
                              ? const Color(0xFF316AE9) 
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: _selectedBrandFilter != null 
                                ? Colors.white 
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedBrandFilter?.name ?? 'All Brands',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedBrandFilter != null 
                                  ? Colors.white 
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: _selectedBrandFilter != null 
                                ? Colors.white 
                                : Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<Brand?>(
                        value: null,
                        child: const Text('All Brands'),
                      ),
                      ...(_homeData!.brands.map((brand) => PopupMenuItem<Brand?>(
                        value: brand,
                        child: Text(brand.name),
                      )).toList()),
                    ],
                    onSelected: (brand) {
                      setState(() {
                        _selectedBrandFilter = brand;
                      });
                    },
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Type Filter
                  PopupMenuButton<ProductType?>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTypeFilter != null 
                            ? const Color(0xFF4CAF50) 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _selectedTypeFilter != null 
                              ? const Color(0xFF4CAF50) 
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: _selectedTypeFilter != null 
                                ? Colors.white 
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTypeFilter?.name ?? 'All Categories',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedTypeFilter != null 
                                  ? Colors.white 
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: _selectedTypeFilter != null 
                                ? Colors.white 
                                : Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<ProductType?>(
                        value: null,
                        child: const Text('All Categories'),
                      ),
                      ...(_homeData!.types.map((type) => PopupMenuItem<ProductType?>(
                        value: type,
                        child: Text(type.name),
                      )).toList()),
                    ],
                    onSelected: (type) {
                      setState(() {
                        _selectedTypeFilter = type;
                      });
                    },
                  ),
                  
                  // Clear Filters Button
                  if (_selectedBrandFilter != null || _selectedTypeFilter != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBrandFilter = null;
                          _selectedTypeFilter = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        
        Expanded(
          child: _buildProductsGrid(allProducts),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    // Apply filters
    var filteredProducts = products;
    
    // Apply brand filter
    if (_selectedBrandFilter != null) {
      filteredProducts = filteredProducts.where((product) => 
        product.brandId == _selectedBrandFilter!.id
      ).toList();
    }
    
    // Apply type filter
    if (_selectedTypeFilter != null) {
      filteredProducts = filteredProducts.where((product) => 
        product.typeId == _selectedTypeFilter!.id
      ).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (product.brandName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (product.categoryName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          'No products found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildShopProductCard(filteredProducts[index]);
      },
    );
  }

  Widget _buildShopProductCard(Product product) {
    final cartItem = _cartService.cartItems.cast<dynamic>().firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => null,
    );
    final inCart = cartItem != null;
    final quantity = inCart ? cartItem.quantity : 0;

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
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: const Color(0xFFF5F5F5),
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
                  if (product.categoryName != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.categoryName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.price}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF316AE9),
                            ),
                          ),
                          if (inCart)
                            Text(
                              'In cart: $quantity',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _cartService.addToCart(product);
                          setState(() {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: const Color(0xFF4CAF50),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
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

  // Cart view and other methods remain similar to original...
  Widget _buildCartView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'My Cart',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_cartService.cartItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text('Are you sure you want to remove all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await _cartService.clearCart();
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _cartService.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Start Shopping',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cartService.cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = _cartService.cartItems[index];
                    return _buildCartItem(cartItem);
                  },
                ),
        ),
        if (!_cartService.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_calculateTotalPoints() > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You\'ll earn ${_calculateTotalPoints()} points with this order!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_cartService.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _processCheckout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Checkout',
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
          ),
      ],
    );
  }

  Widget _buildCartItem(cartItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF5F5F5),
            ),
            child: cartItem.product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cartItem.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, color: Colors.grey);
                      },
                    ),
                  )
                : const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${cartItem.product.price}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _cartService.updateQuantity(cartItem.product.id, cartItem.quantity - 1);
                      setState(() {});
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () async {
                      await _cartService.updateQuantity(cartItem.product.id, cartItem.quantity + 1);
                      setState(() {});
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  await _cartService.removeFromCart(cartItem.product.id);
                  setState(() {});
                },
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateTotalPoints() {
    int totalPoints = 0;
    for (var item in _cartService.cartItems) {
      totalPoints += (item.product.pointsEarnedAsInt * item.quantity).toInt();
    }
    return totalPoints;
  }

  Future<void> _processCheckout() async {
    if (_cartService.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );

    try {
      if (_currentUser == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to place an order'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final orderResponse = await _orderService.createOrder(
        userId: _currentUser!.id,
        cartItems: _cartService.cartItems,
        pointsUsed: 0,
        status: 'pending',
      );

      Navigator.of(context).pop();
      _cartService.clearCart();
      await _loadData();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            orderResponse: orderResponse,
            totalAmount: (orderResponse['total_amount'] ?? 0).toDouble(),
            totalPointsEarned: orderResponse['points_earned'] ?? 0,
          ),
        ),
      );

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF316AE9),
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart),
              if (_cartService.totalItems > 0)
                Positioned(
                  right: -6,
                  top: -6,
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
                      '${_cartService.totalItems}',
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
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Points Shop',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

