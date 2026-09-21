import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/shamsi_helper.dart';
import '../utils/app_colors.dart';
import '../widgets/post_card.dart';
import '../widgets/grid_item.dart';
import 'connection_screen.dart';
import 'post_detail_screen.dart';

enum ViewMode { agenda, grid }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String? _serverUrl;
  ViewMode _viewMode = ViewMode.agenda;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _serverUrl = await StorageService.getServerUrl();
    if (_serverUrl != null) {
      _isConnected = await ApiService.testConnection(_serverUrl!);
    }

    final fetchedPosts = await ApiService.fetchPosts();

    // Schedule reminders for upcoming posts
    for (final post in fetchedPosts) {
      if (!post.isPosted && post.scheduledDate.isAfter(DateTime.now())) {
        NotificationService.schedulePostReminder(post);
      }
    }

    if (mounted) {
      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePostStatus(Post post, bool newStatus) async {
    setState(() => post.isPosted = newStatus);
    final updated = await ApiService.togglePostedStatus(post.id);
    if (updated != null) {
      _loadData();
    }
  }

  void _openDetail(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          post: post,
          onPostUpdated: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayShamsi = ShamsiHelper.formatShort(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isConnected ? AppColors.emerald : Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقویم محتوا ($todayShamsi)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isConnected ? 'متصل به سرور کامپیوتر' : 'حالت آفلاین (مستقل)',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isConnected ? AppColors.emeraldLight : Colors.amber.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Switch between Agenda & Grid View
          IconButton(
            icon: Icon(
              _viewMode == ViewMode.agenda
                  ? Icons.grid_view_rounded
                  : Icons.view_agenda_rounded,
              color: Colors.white,
            ),
            tooltip: _viewMode == ViewMode.agenda
                ? 'نمای گرید اینستاگرام'
                : 'نمای تقویم و فهرست',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.agenda
                    ? ViewMode.grid
                    : ViewMode.agenda;
              });
            },
          ),

          // Reconnect / Server Settings
          IconButton(
            icon: const Icon(Icons.sync_alt_rounded, color: Colors.white70),
            tooltip: 'تنظیمات اتصال سرور',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectionScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFE1306C),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE1306C)),
              )
            : _posts.isEmpty
                ? _buildEmptyState()
                : _viewMode == ViewMode.agenda
                    ? _buildAgendaView()
                    : _buildGridView(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Center(
          child: Icon(Icons.video_library_outlined, size: 64, color: Colors.white24),
        ),
        const SizedBox(height: 16),
        const Text(
          'هنوز پستی ثبت نشده است',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'در داشبورد کامپیوتر پست اضافه کنید یا ویدیوها را در watch_folder بریزید.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('بروزرسانی مجدد'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.pinkAccent),
          ),
        ),
      ],
    );
  }

  /// 3x3 Instagram Profile Grid View
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GridItem(
          post: post,
          onTap: () => _openDetail(post),
        );
      },
    );
  }

  /// Daily Agenda List View grouped by Date
  Widget _buildAgendaView() {
    final todayPosts = _posts.filter((p) => p.isToday && !p.isPosted).toList();
    final tomorrowPosts =
        _posts.filter((p) => p.isTomorrow && !p.isPosted).toList();
    final upcomingPosts =
        _posts.filter((p) => p.isUpcoming && !p.isPosted).toList();
    final pastPendingPosts =
        _posts.filter((p) => p.isPast && !p.isPosted).toList();
    final postedPosts = _posts.filter((p) => p.isPosted).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (todayPosts.isNotEmpty) ...[
          _buildSectionHeader('🔥 پست‌های امروز', todayPosts.length, Colors.pinkAccent),
          ...todayPosts.map((p) => PostCard(
                post: p,
                onTap: () => _openDetail(p),
                onTogglePosted: (val) => _togglePostStatus(p, val),
              )),
        ],

        if (tomorrowPosts.isNotEmpty) ...[
          _buildSectionHeader('📅 پست‌های فردا', tomorrowPosts.length, Colors.cyanAccent),
          ...tomorrowPosts.map((p) => PostCard(
                post: p,
                onTap: () => _openDetail(p),
                onTogglePosted: (val) => _togglePostStatus(p, val),
              )),
        ],

        if (upcomingPosts.isNotEmpty) ...[
          _buildSectionHeader('⏳ در روزهای آینده', upcomingPosts.length, Colors.amberAccent),
          ...upcomingPosts.map((p) => PostCard(
                post: p,
                onTap: () => _openDetail(p),
                onTogglePosted: (val) => _togglePostStatus(p, val),
              )),
        ],

        if (pastPendingPosts.isNotEmpty) ...[
          _buildSectionHeader('⚠️ معوقه (گذشته)', pastPendingPosts.length, Colors.redAccent),
          ...pastPendingPosts.map((p) => PostCard(
                post: p,
                onTap: () => _openDetail(p),
                onTogglePosted: (val) => _togglePostStatus(p, val),
              )),
        ],

        if (postedPosts.isNotEmpty) ...[
          _buildSectionHeader('✅ منتشر شده در اینستاگرام', postedPosts.length, AppColors.emeraldLight),
          ...postedPosts.map((p) => PostCard(
                post: p,
                onTap: () => _openDetail(p),
                onTogglePosted: (val) => _togglePostStatus(p, val),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ShamsiHelper.toPersianDigits(count.toString()),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension PostListFilter on List<Post> {
  Iterable<Post> filter(bool Function(Post) test) sync* {
    for (final item in this) {
      if (test(item)) yield item;
    }
  }
}
