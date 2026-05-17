import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/services/exhibition_service.dart';

class AdminExhibitionsScreen extends StatefulWidget {
  const AdminExhibitionsScreen({super.key});

  @override
  State<AdminExhibitionsScreen> createState() =>
      _AdminExhibitionsScreenState();
}

class _AdminExhibitionsScreenState extends State<AdminExhibitionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _boothSearchController = TextEditingController();
  String _selectedTab = 'All';
  final Map<String, String> _boothCountCache = {};
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.loadExhibitions();
      await provider.loadApplications();
      await provider.loadAllBooths();
      if (mounted) {
        setState(() {
          _pendingCount = provider.applications
              .where((a) => a.status == 'pending')
              .length;
        });
      }
      await _loadAllBoothCounts(provider.exhibitions);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _boothSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBoothCounts(List<ExhibitionModel> exhibitions) async {
    final service = ExhibitionService();
    for (final e in exhibitions) {
      final reserved = await service.getReservedBoothCount(e.id);
      final total = await service.getTotalBoothCount(e.id);
      if (mounted) {
        setState(() {
          _boothCountCache[e.id] = '$reserved / $total Booths Reserved';
        });
      }
    }
  }

  List<ExhibitionModel> _filterByTab(List<ExhibitionModel> all) {
    final now = DateTime.now();
    switch (_selectedTab) {
      case 'Published':
        return all.where((e) => e.isPublished).toList();
      case 'Past':
        return all.where((e) => e.endDate.isBefore(now)).toList();
      default:
        return all;
    }
  }

  Future<void> _deleteExhibition(ExhibitionModel exhibition) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exhibition'),
        content: Text(
            'Are you sure you want to delete "${exhibition.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AdminProvider>().deleteExhibition(exhibition.id);
      await _loadAllBoothCounts(
          context.read<AdminProvider>().exhibitions);
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[start.month]} ${start.day}–${end.day}, ${start.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final filtered = _filterByTab(provider.exhibitions);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF185FA5)),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text(
          'Exhibition Management',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 16),
            _buildTabAndSearch(provider),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Exhibitions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1C1E),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/admin/exhibitions/create');
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Create Exhibition',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No exhibitions found.',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
                ),
              )
            else
              ...filtered.map((e) => _buildExhibitionCard(e)),
            const SizedBox(height: 24),
            _buildBoothBreakdown(provider),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── INFO BANNER ──────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF6C757D)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Manage all exhibition events for all users, from creating and editing to publishing and deleting listings.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB + SEARCH ─────────────────────────────────────────
  Widget _buildTabAndSearch(AdminProvider provider) {
    return Row(
      children: [
        Row(
          children: ['All', 'Published', 'Past'].map((tab) {
            final isActive = _selectedTab == tab;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedTab = tab);
                provider.searchExhibitions(_searchController.text);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Text(
                      tab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isActive
                            ? const Color(0xFF1A1C1E)
                            : const Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isActive)
                      Container(
                        height: 2,
                        width: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF185FA5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        Container(
          width: 140,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              provider.searchExhibitions(val);
              setState(() {});
            },
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Search exhibitions',
              hintStyle:
              TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
              prefixIcon: Icon(Icons.search,
                  size: 16, color: Color(0xFF8E8E93)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  // ── EXHIBITION CARD ──────────────────────────────────────
  Widget _buildExhibitionCard(ExhibitionModel exhibition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: title + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exhibition.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPublishBadge(exhibition.isPublished),
              ],
            ),
            const SizedBox(height: 5),
            // Row 2: date
            Text(
              _formatDateRange(exhibition.startDate, exhibition.endDate),
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 3),
            // Row 3: venue
            Text(
              exhibition.venue,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 10),
            // Row 4: booth counter + actions
            Row(
              children: [
                Text(
                  _boothCountCache[exhibition.id] ??
                      '— / — Booths Reserved',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C757D)),
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => context.go(
                      '/admin/exhibitions/${exhibition.id}/edit'),
                ),
                _Divider(),
                _ActionButton(
                  label: 'View',
                  onTap: () => context.go(
                      '/admin/exhibitions/${exhibition.id}/booths'),
                ),
                _Divider(),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: const Color(0xFFDC3545),
                  onTap: () => _deleteExhibition(exhibition),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFD4EDDA)
            : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? 'Published' : 'Unpublished',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF155724)
              : const Color(0xFF495057),
        ),
      ),
    );
  }

  // ── BOOTH BREAKDOWN ──────────────────────────────────────
  Widget _buildBoothBreakdown(AdminProvider provider) {
    final booths = provider.booths;
    final filtered = booths.where((b) {
      final q = _boothSearchController.text.toLowerCase();
      return q.isEmpty ||
          b.boothNumber.toLowerCase().contains(q) ||
          b.type.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Total: ${booths.length} Booths',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C1E),
              ),
            ),
            const Spacer(),
            const _LegendDot(
                color: Color(0xFF888780), label: 'Standard'),
            const SizedBox(width: 8),
            const _LegendDot(
                color: Color(0xFF7F77DD), label: 'Premium'),
            const SizedBox(width: 8),
            const _LegendDot(
                color: Color(0xFFEF9F27), label: 'VIP'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: TextField(
            controller: _boothSearchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Search booths...',
              hintStyle:
              TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
              prefixIcon: Icon(Icons.search,
                  size: 16, color: Color(0xFF8E8E93)),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDEE2E6)),
            ),
            child: const Center(
              child: Text(
                'No booths yet. Tap View on an exhibition to load its booths.',
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
              ),
            ),
          )
        else
          _buildBoothTable(filtered),
      ],
    );
  }

  Widget _buildBoothTable(List<BoothModel> booths) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                SizedBox(
                    width: 48,
                    child: Text('Booth ID', style: _headerStyle)),
                SizedBox(width: 8),
                SizedBox(
                    width: 56,
                    child: Text('Type', style: _headerStyle)),
                SizedBox(width: 8),
                SizedBox(
                    width: 48,
                    child: Text('Size', style: _headerStyle)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('XY Coords', style: _headerStyle)),
                SizedBox(
                    width: 40,
                    child: Text('Action',
                        style: _headerStyle,
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDEE2E6)),
          ...booths.map((booth) => _buildBoothRow(booth)),
        ],
      ),
    );
  }

  Widget _buildBoothRow(BoothModel booth) {
    final typeColor = _boothTypeColor(booth.type);
    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  booth.boothNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(booth.type,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(booth.size,
                    style: const TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '(${booth.positionX.toInt()}, ${booth.positionY.toInt()})',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C757D)),
                ),
              ),
              SizedBox(
                width: 40,
                child: GestureDetector(
                  onTap: () => context.go(
                      '/admin/exhibitions/${booth.exhibitionId}/booths/${booth.id}/edit'),
                  child: const Text(
                    'Edit',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF185FA5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFDEE2E6)),
      ],
    );
  }

  // ── BOTTOM NAV ───────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDEE2E6))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Dashboard',
                onTap: () => context.go('/admin'),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Events',
                isActive: true,
                onTap: () {},
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _NavItem(
                    icon: Icons.description_outlined,
                    label: 'Applications',
                    onTap: () => context.go('/admin/applications'),
                  ),
                  if (_pendingCount > 0)
                    Positioned(
                      top: -2,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC3545),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_pendingCount',
                          style: const TextStyle(
                              fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                label: 'Booth Types',
                onTap: () => context.go('/admin/exhibitions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _boothTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'premium':
        return const Color(0xFF7F77DD);
      case 'vip':
        return const Color(0xFFEF9F27);
      default:
        return const Color(0xFF888780);
    }
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6C757D),
  );
}

// ── REUSABLE WIDGETS ─────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    this.icon,
    required this.label,
    this.color = const Color(0xFF1A1C1E),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
            ],
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: const Color(0xFFDEE2E6),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF6C757D))),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 22,
              color: isActive
                  ? const Color(0xFF185FA5)
                  : const Color(0xFF6C757D)),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive
                  ? const Color(0xFF185FA5)
                  : const Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    );
  }
}