import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:news_app/controllers/news_controller.dart';
import 'package:news_app/routes/app_pages.dart';
import 'package:news_app/utils/app_colors.dart';
import 'package:news_app/widgets/news_card.dart';
import 'package:news_app/widgets/category_chip.dart';
import 'package:news_app/widgets/loading_shimmer.dart';
import 'package:news_app/widgets/dynamic_clock.dart';

// Helper class untuk membuat header menempel (Sticky Header)
class _SliverCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverCategoryHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.surface, child: child);
  }

  @override
  bool shouldRebuild(_SliverCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

// Mengubah menjadi StatefulWidget untuk menangani Scroll Notification
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final NewsController controller = Get.find<NewsController>();
  // Status untuk mengontrol animasi Jam
  final RxDouble _scrollPosition = 0.0.obs;

  // 💡 STATE BARU untuk mengontrol Search Bar
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ... (Logika Scroll Notification listener lainnya tetap sama)
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollPosition.close();
    super.dispose();
  }

  // Logika untuk mendeteksi scroll
  void _scrollListener(ScrollNotification notification) {
    const double maxScroll = 200.0;
    if (notification.metrics.axis == Axis.vertical && notification.metrics.extentBefore >= 0) {
      double scrollOffset = notification.metrics.pixels.clamp(0.0, maxScroll);
      _scrollPosition.value = (scrollOffset / maxScroll).clamp(0.0, 1.0);
    }
  }

  // MENTOGGLE SEARCH BAR
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        controller.refreshNews(); // Muat ulang berita jika pencarian ditutup
      }
    });
  }

  // Submit pencarian
  void _submitSearch(String query) {
    if (query.isNotEmpty) {
      controller.searchNews(query);
      FocusScope.of(context).unfocus(); // Sembunyikan keyboard
    }
  }

  // Helper: Baris Filter Kategori
  Widget _buildCategoryRow() {
    return Container(
      height: 60,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          return Obx(
            () => CategoryChip(
              label: category.capitalize ?? category,
              isSelected: controller.selectedCategory == category,
              onTap: () => controller.selectCategory(category),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
// Properti 'automaticallyImplyLeading' diatur ke false karena kita mengelola logo/tombol back sendiri
        automaticallyImplyLeading: false, 
        
        // 💡 JUDUL SEBAGAI CONTAINER SEARCH BAR PENUH
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. LOGO APLIKASI (SLIDE OUT/IN)
            // Animasi width dan opacity untuk efek geser keluar dan menghilang.
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // Lebar Icon (28) + Spasi (8) + Margin (4)
              width: _isSearching ? 0 : 40, 
              child: AnimatedOpacity(
                opacity: _isSearching ? 0.0 : 1.0,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Icon(
                    Icons.newspaper, 
                    size: 28,
                    color: AppColors.accent, 
                  ),
              ),
            ),
            
            // 2. SEARCH BAR UTAMA (Tengah)
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary, 
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _submitSearch,
                  enabled: _isSearching, // Hanya aktif saat mode mencari
                  autofocus: true,
                  style: TextStyle(color: AppColors.onPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari Berita...',
                    hintStyle: TextStyle(color: AppColors.onPrimary.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    isDense: true,
                    // Tombol X untuk clear dan menutup
                    suffixIcon: _isSearching 
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.onPrimary),
                            onPressed: () {
                              _searchController.clear();
                              _submitSearch('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // 3. ICON SEARCH TOGGLE (Expanded/Melebar)
        actions: [
          // Menggunakan AnimatedContainer untuk menganimasikan margin horizontal
          // agar terlihat "melebar" dan menyusut saat Logo di sisi kiri menghilang.
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // Lebar 16 saat tidak mencari (padding normal)
            // Lebar 40 saat mencari (menggantikan ruang logo yang hilang)
            margin: EdgeInsets.symmetric(horizontal: _isSearching ? 12.0 : 4.0),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search, 
                color: AppColors.onPrimary
              ),
              onPressed: _toggleSearch,
            ),
          ),
        ],
      ),
      // Menggunakan NotificationListener untuk mendengarkan guliran
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // Hanya pantau scroll pada CustomScrollView (Primary Scroll)
          if (notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentBefore >= 0) {
            // Batasi nilai guliran untuk normalisasi animasi antara 0.0 hingga 1.0
            double maxScroll = 200.0;
            double scrollOffset = notification.metrics.pixels.clamp(
              0.0,
              maxScroll,
            );
            _scrollPosition.value = (scrollOffset / maxScroll).clamp(0.0, 1.0);
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.refreshNews,
          child: CustomScrollView(
            slivers: [
              // 1. JAM DINAMIS
              SliverToBoxAdapter(
                child: Obx(
                  () => DynamicClock(scrollPosition: _scrollPosition.value),
                ),
              ),

              // 2. FILTER KATEGORI (Header Menempel/Sticky Header)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverCategoryHeaderDelegate(
                  height: 60.0,
                  child: _buildCategoryRow(),
                ),
              ),

              // 3. DAFTAR BERITA DINAMIS
              Obx(() {
                if (controller.isLoading) {
                  return SliverFillRemaining(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: LoadingShimmer(),
                    ),
                  );
                }

                if (controller.error.isNotEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorWidget(),
                  );
                }

                if (controller.articles.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyWidget(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final article = controller.articles[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: NewsCard(
                        article: article,
                        onTap: () =>
                            Get.toNamed(Routes.NEWS_DETAIL, arguments: article),
                      ),
                    );
                  }, childCount: controller.articles.length),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Metode Pembantu...
  Widget _buildErrorWidget() {
    /* ... kode error widget ... */
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: AppColors.error),
        SizedBox(height: 16),
        Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please check your internet connection',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        SizedBox(height: 24),
        ElevatedButton(onPressed: controller.refreshNews, child: Text('Retry')),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    /* ... kode empty widget ... */
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'No news available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search News'),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              controller.searchNews(value);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                controller.searchNews(searchController.text);
                Navigator.of(context).pop();
              }
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
}
