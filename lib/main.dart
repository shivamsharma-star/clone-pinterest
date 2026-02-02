import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait orientation only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Clerk (commented for now, uncomment when you have credentials)
  // await Clerk.instance.setup(
  //   publishableKey: 'YOUR_CLERK_PUBLISHABLE_KEY',
  // );

  runApp(const ProviderScope(child: PinterestApp()));
}

// ============================================
// 1. APP CONFIGURATION
// ============================================

class PinterestApp extends ConsumerWidget {
  const PinterestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pinterest Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFFE60023),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Color(0xFF767676),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      routerConfig: router,
    );
  }
}

// ============================================
// 2. ROUTING WITH GO_ROUTER
// ============================================

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Home
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          // Search
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          // Create
          GoRoute(
            path: '/create',
            name: 'create',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CreateScreen()),
          ),
          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      // Pin Detail with hero animation
      GoRoute(
        path: '/pin/:id',
        name: 'pin-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final pin = state.extra as Pin?;
          return PinDetailScreen(pinId: id, pin: pin);
        },
      ),
      // Auth
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
    ],
  );
});

// Main Layout with Bottom Navigation
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  static const List<String> _routes = ['/', '/search', '/create', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          context.go(_routes[index]);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Icons.home_filled : Icons.home_outlined,
              size: 26,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1 ? Icons.search : Icons.search_outlined,
              size: 26,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2
                  ? Icons.add_circle
                  : Icons.add_circle_outlined,
              size: 26,
            ),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3 ? Icons.person : Icons.person_outlined,
              size: 26,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================
// 3. DATA LAYER WITH CLEAN ARCHITECTURE
// ============================================

// 3.1 Entities
class Pin {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String originalImageUrl;
  final int width;
  final int height;
  final String photographer;
  final String photographerUrl;
  final String photographerId;
  final String avgColor;
  final List<String> tags;
  bool isLiked;
  bool isSaved;
  int likes;

  Pin({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.originalImageUrl,
    required this.width,
    required this.height,
    required this.photographer,
    required this.photographerUrl,
    required this.photographerId,
    required this.avgColor,
    required this.tags,
    this.isLiked = false,
    this.isSaved = false,
    this.likes = 0,
  });

  factory Pin.fromPexelsJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>;
    final photographer = json['photographer'] as String? ?? 'Unknown';
    final alt = json['alt'] as String? ?? 'Beautiful Image';

    // Extract tags from alt text
    List<String> tags = [];
    if (alt.isNotEmpty) {
      final words = alt.toLowerCase().split(' ');
      tags = words.where((word) => word.length > 2).take(3).toList();
    }

    return Pin(
      id: json['id'].toString(),
      title: alt.length > 50 ? '${alt.substring(0, 50)}...' : alt,
      description: alt,
      imageUrl: src['medium'] as String,
      originalImageUrl: src['original'] as String,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      photographer: photographer,
      photographerUrl: json['photographer_url'] as String? ?? '',
      photographerId: json['photographer_id'].toString(),
      avgColor: json['avg_color'] as String? ?? '#000000',
      tags: tags,
      likes: json['likes'] as int? ?? 0,
    );
  }

  Pin copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? originalImageUrl,
    int? width,
    int? height,
    String? photographer,
    String? photographerUrl,
    String? photographerId,
    String? avgColor,
    List<String>? tags,
    bool? isLiked,
    bool? isSaved,
    int? likes,
  }) {
    return Pin(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      photographer: photographer ?? this.photographer,
      photographerUrl: photographerUrl ?? this.photographerUrl,
      photographerId: photographerId ?? this.photographerId,
      avgColor: avgColor ?? this.avgColor,
      tags: tags ?? this.tags,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      likes: likes ?? this.likes,
    );
  }
}

// 3.2 Data Source
class PexelsDataSource {
  final Dio _dio;

  static const String _baseUrl = 'https://api.pexels.com/v1';
  static const String _apiKey =
      '9ZJxJK2uwsrC7NDWO54sbW5cwLPDKDIFr1Gk4hGvOCsTIyai4vwT0DcH';

  PexelsDataSource(this._dio) {
    _dio.options.headers['Authorization'] = _apiKey;
  }

  Future<List<Pin>> getCuratedPhotos({int page = 1, int perPage = 30}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/curated',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      final photos = response.data['photos'] as List;
      return photos.map((json) => Pin.fromPexelsJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load photos: $e');
    }
  }

  Future<List<Pin>> searchPhotos({
    required String query,
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {'query': query, 'page': page, 'per_page': perPage},
      );

      final photos = response.data['photos'] as List;
      return photos.map((json) => Pin.fromPexelsJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search photos: $e');
    }
  }

  Future<List<Pin>> getPopularPhotos() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/popular',
        queryParameters: {'per_page': 30},
      );

      final photos = response.data['photos'] as List;
      return photos.map((json) => Pin.fromPexelsJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load popular photos: $e');
    }
  }
}

// 3.3 Repository
class PinRepository {
  final PexelsDataSource _dataSource;

  PinRepository(this._dataSource);

  Future<List<Pin>> getCuratedPins({int page = 1, int perPage = 30}) async {
    return await _dataSource.getCuratedPhotos(page: page, perPage: perPage);
  }

  Future<List<Pin>> searchPins({
    required String query,
    int page = 1,
    int perPage = 30,
  }) async {
    return await _dataSource.searchPhotos(
      query: query,
      page: page,
      perPage: perPage,
    );
  }

  Future<List<Pin>> getPopularPins() async {
    return await _dataSource.getPopularPhotos();
  }
}

// ============================================
// 4. PROVIDERS WITH RIVERPOD
// ============================================

// Dio Provider
final dioProvider = Provider<Dio>((ref) => Dio());

// Data Source Provider
final pexelsDataSourceProvider = Provider<PexelsDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PexelsDataSource(dio);
});

// Repository Provider
final pinRepositoryProvider = Provider<PinRepository>((ref) {
  final dataSource = ref.watch(pexelsDataSourceProvider);
  return PinRepository(dataSource);
});

// 4.1 Home Provider
class HomeState {
  final List<Pin> pins;
  final int page;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;

  const HomeState({
    this.pins = const [],
    this.page = 1,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
  });

  HomeState copyWith({
    List<Pin>? pins,
    int? page,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
  }) {
    return HomeState(
      pins: pins ?? this.pins,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final PinRepository _repository;

  HomeNotifier(this._repository) : super(const HomeState()) {
    loadPins();
  }

  Future<void> loadPins() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newPins = await _repository.getCuratedPins(page: state.page);

      state = state.copyWith(
        pins: [...state.pins, ...newPins],
        page: state.page + 1,
        isLoading: false,
        hasError: false,
        hasMore: newPins.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refreshPins() async {
    state = state.copyWith(pins: [], page: 1, hasMore: true);
    await loadPins();
  }

  void likePin(String pinId) {
    final updatedPins = state.pins.map((pin) {
      if (pin.id == pinId) {
        return pin.copyWith(
          isLiked: !pin.isLiked,
          likes: pin.isLiked ? pin.likes - 1 : pin.likes + 1,
        );
      }
      return pin;
    }).toList();

    state = state.copyWith(pins: updatedPins);
  }

  void savePin(String pinId) {
    final updatedPins = state.pins.map((pin) {
      if (pin.id == pinId) {
        return pin.copyWith(isSaved: !pin.isSaved);
      }
      return pin;
    }).toList();

    state = state.copyWith(pins: updatedPins);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(pinRepositoryProvider);
  return HomeNotifier(repository);
});

// 4.2 Search Provider
class SearchState {
  final List<Pin> searchResults;
  final String query;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final List<String> recentSearches;
  final List<String> popularSearches;

  const SearchState({
    this.searchResults = const [],
    this.query = '',
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.recentSearches = const [],
    this.popularSearches = const [],
  });

  SearchState copyWith({
    List<Pin>? searchResults,
    String? query,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    List<String>? recentSearches,
    List<String>? popularSearches,
  }) {
    return SearchState(
      searchResults: searchResults ?? this.searchResults,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      recentSearches: recentSearches ?? this.recentSearches,
      popularSearches: popularSearches ?? this.popularSearches,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final PinRepository _repository;
  Timer? _debounceTimer;

  SearchNotifier(this._repository) : super(const SearchState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final recent = ['Nature', 'Food', 'Travel', 'Art', 'Fashion', 'Home Decor'];
    final popular = [
      'Wallpaper',
      'Minimal',
      'Modern',
      'Vintage',
      'Abstract',
      'Landscape',
    ];

    state = state.copyWith(recentSearches: recent, popularSearches: popular);
  }

  Future<void> searchPhotos(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], query: query, isLoading: false);
      return;
    }

    state = state.copyWith(query: query, isLoading: true, hasError: false);

    try {
      final results = await _repository.searchPins(query: query);

      // Add to recent searches
      if (!state.recentSearches.contains(query)) {
        final newRecent = [query, ...state.recentSearches.take(4)];
        state = state.copyWith(recentSearches: newRecent);
      }

      state = state.copyWith(searchResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(searchResults: [], query: '');
  }

  void searchWithDebounce(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      searchPhotos(query);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final repository = ref.watch(pinRepositoryProvider);
  return SearchNotifier(repository);
});

// ============================================
// 5. PRESENTATION LAYER - SCREENS
// ============================================

// 5.1 HOME SCREEN - PIXEL PERFECT
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await ref.read(homeProvider.notifier).loadPins();

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pinterest',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined, size: 26),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refreshPins(),
        color: const Color(0xFFE60023),
        child: _buildContent(state),
      ),
    );
  }

  Widget _buildContent(HomeState state) {
    if (state.isLoading && state.pins.isEmpty) {
      return _buildShimmerGrid();
    }

    if (state.hasError && state.pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Failed to load pins',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(homeProvider.notifier).refreshPins(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE60023),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      controller: _scrollController,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(12),
      itemCount: state.pins.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.pins.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFE60023)),
            ),
          );
        }

        final pin = state.pins[index];
        return _buildPinCard(pin);
      },
    );
  }

  Widget _buildPinCard(Pin pin) {
    final height = (pin.height * 200 / pin.width).clamp(150, 400).toDouble();

    return GestureDetector(
      onTap: () {
        context.push('/pin/${pin.id}', extra: pin);
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'pin-${pin.id}',
                    child: CachedNetworkImage(
                      imageUrl: pin.imageUrl,
                      height: height,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: height,
                        color: _parseColor(pin.avgColor),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE60023),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: height,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.error_outline, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pin.title.isNotEmpty)
                          Text(
                            pin.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${pin.photographer}',
                          style: const TextStyle(
                            color: Color(0xFF767676),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(bottom: 60, right: 8, child: _buildPinActions(pin)),
              if (pin.tags.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Wrap(
                    spacing: 4,
                    children: pin.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinActions(Pin pin) {
    final notifier = ref.read(homeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              pin.isLiked ? Icons.favorite : Icons.favorite_border,
              color: pin.isLiked
                  ? const Color(0xFFE60023)
                  : const Color(0xFF767676),
              size: 20,
            ),
            onPressed: () => notifier.likePin(pin.id),
            splashRadius: 20,
          ),
          IconButton(
            icon: Icon(
              pin.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: pin.isSaved ? Colors.black : const Color(0xFF767676),
              size: 20,
            ),
            onPressed: () => notifier.savePin(pin.id),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100 + (index % 3) * 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey.shade200;
    }
  }
}

// 5.2 SEARCH SCREEN
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(searchProvider.notifier)
        .searchWithDebounce(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(state, notifier),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildSearchBar(SearchState state, SearchNotifier notifier) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search for ideas...',
          hintStyle: const TextStyle(color: Color(0xFF767676)),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF767676)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF767676),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    notifier.clearSearch();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.isLoading) {
      return _buildLoadingGrid();
    }

    if (state.searchResults.isNotEmpty) {
      return _buildSearchResults(state);
    }

    if (state.query.isNotEmpty && !state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Color(0xFF767676)),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Color(0xFF111111)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for something else',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return _buildSearchSuggestions(state);
  }

  Widget _buildSearchResults(SearchState state) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(12),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final pin = state.searchResults[index];
        final height = (pin.height * 200 / pin.width)
            .clamp(150, 400)
            .toDouble();

        return GestureDetector(
          onTap: () {
            context.push('/pin/${pin.id}', extra: pin);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: pin.imageUrl,
                height: height,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(height: height, color: _parseColor(pin.avgColor)),
                errorWidget: (context, url, error) => Container(
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSuggestions(SearchState state) {
    final notifier = ref.read(searchProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.recentSearches.isNotEmpty) ...[
            _buildSection('Recent Searches', state.recentSearches, notifier),
            const SizedBox(height: 24),
          ],
          _buildSection('Popular Searches', state.popularSearches, notifier),
          const SizedBox(height: 24),
          _buildCategories(notifier),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> items,
    SearchNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                _searchController.text = item;
                _searchFocusNode.unfocus();
                notifier.searchPhotos(item);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategories(SearchNotifier notifier) {
    final categories = [
      {'name': 'Home Decor', 'icon': Icons.home, 'color': Colors.blue.shade100},
      {
        'name': 'Fashion',
        'icon': Icons.checkroom,
        'color': Colors.pink.shade100,
      },
      {
        'name': 'Food & Drink',
        'icon': Icons.restaurant,
        'color': Colors.orange.shade100,
      },
      {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.green.shade100},
      {'name': 'Art', 'icon': Icons.palette, 'color': Colors.purple.shade100},
      {
        'name': 'Photography',
        'icon': Icons.camera_alt,
        'color': Colors.grey.shade100,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                _searchController.text = category['name'] as String;
                notifier.searchPhotos(category['name'] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: category['color'] as Color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category['icon'] as IconData, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        category['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.all(4),
            height: 100 + (index % 3) * 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey.shade200;
    }
  }
}

// 5.3 CREATE SCREEN
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Pin'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Next',
              style: TextStyle(
                color: Color(0xFFE60023),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload an image',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell everyone what your Pin is about',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Link (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a link',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE60023),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Publish',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5.4 PROFILE SCREEN
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE60023), Color(0xFFFF6B6B)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        'https://images.pexels.com/users/avatars/26735/justin-shaifer-587.jpeg',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '@johndoe',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Photographer & Travel Enthusiast\nCapturing moments around the world',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('1.2K', 'Followers'),
                      const SizedBox(width: 30),
                      _buildStatItem('356', 'Following'),
                      const SizedBox(width: 30),
                      _buildStatItem('89', 'Pins'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60023),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Pins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < state.pins.length) {
                  final pin = state.pins[index];
                  return GestureDetector(
                    onTap: () {
                      context.push('/pin/${pin.id}', extra: pin);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: pin.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              }, childCount: state.pins.length > 9 ? 9 : state.pins.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// 5.5 PIN DETAIL SCREEN
class PinDetailScreen extends StatefulWidget {
  final String pinId;
  final Pin? pin;

  const PinDetailScreen({super.key, required this.pinId, this.pin});

  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFollowing = false;
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.pin?.isLiked ?? false;
    _isSaved = widget.pin?.isSaved ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    if (pin == null) {
      return const Scaffold(body: Center(child: Text('Pin not found')));
    }

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          setState(() {
            _scrollPosition = notification.metrics.pixels;
          });
          return false;
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Hero(
                    tag: 'pin-${pin.id}',
                    child: CachedNetworkImage(
                      imageUrl: pin.originalImageUrl,
                      width: double.infinity,
                      height: 400,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 400,
                        color: _parseColor(pin.avgColor),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE60023),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          pin.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: CachedNetworkImageProvider(
                                'https://images.pexels.com/users/avatars/26735/justin-shaifer-587.jpeg',
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pin.photographer,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    'Professional Photographer',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isFollowing = !_isFollowing;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey.shade200
                                    : const Color(0xFFE60023),
                                foregroundColor: _isFollowing
                                    ? Colors.black
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        if (pin.tags.isNotEmpty) ...[
                          const Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: pin.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 30),
                        ],
                        const Text(
                          'Related Pins',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 120,
                                margin: EdgeInsets.only(
                                  right: index == 4 ? 0 : 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      pin.imageUrl,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Custom Back Button with fade effect
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: AnimatedOpacity(
                opacity: _scrollPosition > 100 ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.share_outlined, 'Share'),
                    _buildActionButton(Icons.download_outlined, 'Download'),
                    _buildActionButton(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      'Save',
                      isActive: _isSaved,
                      onTap: () => setState(() => _isSaved = !_isSaved),
                    ),
                    _buildActionButton(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      'Like',
                      isActive: _isLiked,
                      color: _isLiked ? const Color(0xFFE60023) : null,
                      onTap: () => setState(() => _isLiked = !_isLiked),
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

  Widget _buildActionButton(
    IconData icon,
    String label, {
    bool isActive = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color:
                color ??
                (isActive ? const Color(0xFF111111) : const Color(0xFF767676)),
          ),
          onPressed: onTap ?? () {},
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF111111) : const Color(0xFF767676),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey.shade200;
    }
  }
}

// 5.6 AUTH SCREEN
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Welcome to\nPinterest',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover ideas for all your projects',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF111111),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/124/124010.png',
                        height: 20,
                        width: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Facebook',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE60023),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Continue with Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'By continuing, you agree to Pinterest\'s Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/');
                  },
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// Timer class for debouncing
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _isActive = false;

  Timer(this.duration, this.callback) {
    _start();
  }

  void _start() {
    _isActive = true;
    Future.delayed(duration, () {
      if (_isActive) {
        callback();
      }
    });
  }

  void cancel() {
    _isActive = false;
  }

  bool get isActive => _isActive;
}
