import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:news_app/controllers/news_controller.dart';
import 'package:news_app/routes/app_pages.dart';
import 'package:news_app/utils/app_colors.dart';
import 'package:news_app/widgets/news_card.dart';
import 'package:news_app/widgets/category_chip.dart';
import 'package:news_app/widgets/loading_shimmer.dart';
import 'package:news_app/widgets/dynamic_clock.dart';
import 'package:news_app/widgets/weather_panel.dart';

class _SliverCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _SliverCategoryHeaderDelegate({required this.height, required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_SliverCategoryHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}


class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

// PERBAIKAN: Menggunakan SingleTickerProviderStateMixin untuk Animasi (Walaupun animasi AppBar disederhanakan, ini penting untuk Shimmer)
class _HomeViewState extends State<HomeView> 
    with SingleTickerProviderStateMixin { 

  final NewsController controller = Get.find<NewsController>();
  final RxDouble _scrollPosition = 0.0.obs;

  // PERBAIKAN: Gunakan FocusNode dan State sederhana, hapus AnimationController/Animation yang menyebabkan LateError
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false; // State untuk toggle tampilan

  bool _isWeatherPanelVisible = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi TickerProvider yang diperlukan oleh LoadingShimmer (walaupun tidak digunakan di AppBar lagi)
    // NOTE: Logika _searchFocusNode.addListener dipindahkan ke _toggleSearch untuk kesederhanaan.
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollPosition.close();
    super.dispose();
  }

  void _toggleWeatherPanel() {
    setState(() {
      _isWeatherPanelVisible = !_isWeatherPanelVisible;
    });
  }

  void _scrollListener(ScrollNotification notification) {
    const double maxScroll = 200.0;
    if (notification.metrics.axis == Axis.vertical && notification.metrics.extentBefore >= 0) {
      double scrollOffset = notification.metrics.pixels.clamp(0.0, maxScroll);
      _scrollPosition.value = (scrollOffset / maxScroll).clamp(0.0, 1.0);
    }
  }

  // PERBAIKAN: Logika Toggle Search BARU
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        controller.refreshNews(); 
        _searchFocusNode.unfocus();
      } else {
        // Jika membuka search bar, fokuskan segera
        FocusScope.of(context).requestFocus(_searchFocusNode);
      }
    });
  }

  void _submitSearch(String query) {
    if (query.isNotEmpty) {
      controller.searchNews(query);
      // Biarkan _isSearching tetap true saat hasil ditampilkan
      FocusScope.of(context).unfocus(); 
    }
  }

  Widget _buildCategoryRow() {
    // ... (Kode _buildCategoryRow tetap sama)
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

  Widget _buildAnimatedWeatherPanel() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: Offset(0.0, -1.0), 
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        ));
        return ClipRect(
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: _isWeatherPanelVisible 
          ? WeatherPanel(key: ValueKey('open')) 
          : SizedBox.shrink(key: ValueKey('closed')), 
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ukuran logo saat terlihat (dihitung)
    const double _logoSize = 28.0;
    const double _logoMargin = 12.0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary, 
        automaticallyImplyLeading: false, 
        toolbarHeight: 60,

        // PERBAIKAN 4: Struktur AppBar Baru (Logo selalu terlihat, Search Bar di tengah)
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. LOGO APLIKASI (Selalu Ada, kecuali saat Search Terbuka Penuh)
            AnimatedContainer(
              duration: Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              width: _isSearching ? 0 : _logoSize,
              child: Opacity(
                opacity: _isSearching ? 0.0 : 1.0,
                child: Icon(
                  Icons.newspaper, 
                  size: _logoSize,
                  color: AppColors.accent,
                ),
              ),
            ),
            
            // Spasi antara Logo dan Search Bar
            SizedBox(width: _isSearching ? 0 : _logoMargin), 

            // 2. SEARCH BAR UTAMA (MELEBAR KE TENGAH/KIRI)
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                // Gunakan padding untuk mengisi ruang yang dikosongkan logo
                margin: EdgeInsets.only(right: _isSearching ? 12 : 0), 
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode, 
                  onSubmitted: _submitSearch,
                  // Teks dapat diketik kapan saja setelah toggle
                  enabled: true, 
                  style: TextStyle(color: AppColors.onPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: _isSearching ? 'Cari Berita di Sini...' : 'Cari Berita',
                    hintStyle: TextStyle(color: AppColors.onPrimary.withOpacity(0.7)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Ikon Search di kiri field input
                    prefixIcon: Icon(Icons.search, color: AppColors.accent, size: 20),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 3. ICON TOGGLE SEARCH
        actions: [
          // Gunakan tombol Search sebagai toggle (yang juga berfungsi sebagai Close jika sudah terbuka)
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search, 
              color: AppColors.onPrimary
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          _scrollListener(notification);
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.refreshNews,
          child: CustomScrollView(
            slivers: [
              // 1. BAR JAM (DynamicClock)
              SliverToBoxAdapter(
                child: Obx(() => DynamicClock(
                  scrollPosition: _scrollPosition.value,
                  onWeatherToggle: _toggleWeatherPanel, // Pass toggle cuaca
                )),
              ),
              
              // 2. KOTAK CUACA ANIMASI
              SliverToBoxAdapter(
                child: _buildAnimatedWeatherPanel(),
              ),

              // 3. FILTER KATEGORI (Sticky Header)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverCategoryHeaderDelegate(
                  height: 60.0,
                  child: _buildCategoryRow(),
                ),
              ),

              // 4. DAFTAR BERITA
              Obx(() {
                // ... (Logika daftar berita tetap sama)
                if (controller.isLoading) {
                  return SliverFillRemaining( 
                    child: LoadingShimmer(),
                  );
                }
                // ... (Error dan Empty widget tetap sama)
                
                if (controller.error.isNotEmpty) {
                  return SliverFillRemaining( 
                    hasScrollBody: false,
                    child: Center(child: _buildErrorWidget()),
                  );
                }
                if (controller.articles.isEmpty) {
                  return SliverFillRemaining( 
                    hasScrollBody: false,
                    child: Center(child: _buildEmptyWidget()),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                    final article = controller.articles[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: NewsCard(
                        article: article,
                        onTap: () => Get.toNamed(Routes.NEWS_DETAIL, arguments: article),
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
  
  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 48),
        SizedBox(height: 16),
        Text(
          'Gagal memuat berita',
          style: TextStyle(fontSize: 18, color: AppColors.onBackground),
        ),
        SizedBox(height: 8),
        Text(
          controller.error,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onBackground.withOpacity(0.7)),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: controller.refreshNews,
          icon: Icon(Icons.refresh),
          label: Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.article_outlined, color: Colors.grey, size: 48),
        SizedBox(height: 16),
        Text(
          'Tidak ada berita ditemukan',
          style: TextStyle(fontSize: 18, color: AppColors.onBackground),
        ),
        SizedBox(height: 8),
        Text(
          'Coba kata kunci lain atau pilih kategori berbeda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onBackground.withOpacity(0.7)),
        ),
      ],
    );
  }
}