import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_widgets.dart';
import 'product_list_screen.dart';
import 'stock_adjust_screen.dart';
import 'transaction_history_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    // Build the list of nav destinations based on role
    final List<_NavItem> navItems = [
      const _NavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        activeIcon: Icons.dashboard_rounded,
      ),
      if (isAdmin)
        const _NavItem(
          icon: Icons.inventory_2_outlined,
          label: 'Products',
          activeIcon: Icons.inventory_2_rounded,
        ),
      const _NavItem(
        icon: Icons.swap_vert_rounded,
        label: 'Stock Adjust',
        activeIcon: Icons.swap_vert_rounded,
      ),
      const _NavItem(
        icon: Icons.receipt_long_outlined,
        label: 'Transactions',
        activeIcon: Icons.receipt_long_rounded,
      ),
      if (isAdmin)
        const _NavItem(
          icon: Icons.bar_chart_outlined,
          label: 'Reports',
          activeIcon: Icons.bar_chart_rounded,
        ),
    ];

    // Clamp selected index
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    // Build the content for the selected index
    Widget content;
    final currentLabel = navItems[_selectedIndex].label;
    switch (currentLabel) {
      case 'Products':
        content = const ProductListScreen();
        break;
      case 'Stock Adjust':
        content = const StockAdjustScreen();
        break;
      case 'Transactions':
        content = TransactionHistoryScreen();
        break;
      case 'Reports':
        content = const ReportsScreen();
        break;
      default:
        content = _buildDashboardContent(context, authProvider, isWide);
    }

    if (isWide) {
      // ── Desktop: persistent sidebar ──
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(navItems, authProvider),
            Expanded(child: content),
          ],
        ),
      );
    } else {
      // ── Mobile: drawer + bottom nav ──
      return Scaffold(
        appBar: AppBar(
          title: Text(currentLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
          actions: [_buildLogoutButton(authProvider)],
        ),
        body: content,
        bottomNavigationBar: _buildBottomNav(navItems),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Sidebar (Desktop)
  // ════════════════════════════════════════════════════════════════
  Widget _buildSidebar(List<_NavItem> items, AuthProvider authProvider) {
    final role = authProvider.role?.toUpperCase() ?? 'STAFF';
    return Container(
      width: AppTheme.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(right: BorderSide(color: Colors.black, width: AppTheme.borderWidth)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingLg),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                const Expanded(
                  child: Text(
                    'InvenTrack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingMd - 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: isActive 
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive
                                  ? Colors.black
                                  : AppTheme.sidebarText,
                              size: 22,
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.black
                                      : AppTheme.sidebarText,
                                  fontWeight: isActive
                                      ? FontWeight.w900
                                      : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom: user role badge + logout
          Container(
            margin: const EdgeInsets.all(AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    role[0],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        'LOGGED IN',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  onTap: () => _confirmLogout(authProvider),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Bottom Navigation (Mobile)
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNav(List<_NavItem> items) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      backgroundColor: AppTheme.surface,
      indicatorColor: AppTheme.primary.withAlpha(30),
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon, color: AppTheme.primary),
              label: item.label,
            ),
          )
          .toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Dashboard Home Content
  // ════════════════════════════════════════════════════════════════
  Widget _buildDashboardContent(
    BuildContext context,
    AuthProvider authProvider,
    bool isWide,
  ) {
    final productProvider = Provider.of<ProductProvider>(context);
    final role = authProvider.role?.toUpperCase() ?? 'STAFF';
    final totalProducts = productProvider.products.length;
    final lowStockCount = productProvider.lowStockProducts.length;

    // Calculate total value
    double totalValue = 0;
    for (final p in productProvider.products) {
      final qty = (p['quantity'] ?? 0) as num;
      final price = double.tryParse(p['price'].toString()) ?? 0;
      totalValue += qty * price;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await productProvider.fetchProducts();
        if (context.mounted) {
          await Provider.of<AnalyticsProvider>(
            context,
            listen: false,
          ).fetchAnalytics();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Header ──
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900, fontSize: isWide ? 28 : 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s your inventory overview',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Stat Cards ──
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 700
                    ? null
                    : double.infinity;
                final isWide = constraints.maxWidth > 700;

                final cards = [
                  _buildStatCard(
                    icon: Icons.inventory_2_rounded,
                    iconColor: AppTheme.primary,
                    iconBg: AppTheme.surfaceVariant,
                    label: 'Total Products',
                    value: NumberFormat('#,###').format(totalProducts),
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.danger,
                    iconBg: AppTheme.dangerLight,
                    label: 'Low Stock',
                    value: NumberFormat('#,###').format(lowStockCount),
                    subtitle: lowStockCount > 0
                        ? 'Needs attention'
                        : 'All good',
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    icon: Icons.payments_rounded,
                    iconColor: AppTheme.success,
                    iconBg: AppTheme.successLight,
                    label: 'Total Value',
                    value:
                        '${AppTheme.currencySymbol}${NumberFormat('#,###').format(totalValue.toInt())}',
                    width: cardWidth,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards
                        .map(
                          (c) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: cards.last == c ? 0 : AppTheme.spacingMd,
                              ),
                              child: c,
                            ),
                          ),
                        )
                        .toList(),
                  );
                } else {
                  return Column(
                    children: cards
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingMd,
                            ),
                            child: c,
                          ),
                        )
                        .toList(),
                  );
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Low Stock Alert ──
            if (lowStockCount > 0) ...[
              _buildAlertBanner(
                icon: Icons.warning_amber_rounded,
                text:
                    '$lowStockCount product${lowStockCount > 1 ? 's' : ''} below stock threshold',
                color: AppTheme.danger,
                bgColor: AppTheme.dangerLight,
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // ── Analytics Section ──
            Consumer<AnalyticsProvider>(
              builder: (context, analytics, _) {
                if (analytics.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;

                    return Column(
                      children: [
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildChartCard(
                                  title: 'Stock Health',
                                  child: StockStatusChart(
                                    summary: analytics.stockSummary,
                                  ),
                                  height: 300,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingLg),
                              Expanded(
                                child: _buildChartCard(
                                  title: 'Top 5 Products (Qty)',
                                  child: TopProductsChart(
                                    products: analytics.topProducts,
                                  ),
                                  height: 300,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildChartCard(
                            title: 'Stock Health',
                            child: StockStatusChart(
                              summary: analytics.stockSummary,
                            ),
                            height: 250,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          _buildChartCard(
                            title: 'Top 5 Products (Qty)',
                            child: TopProductsChart(
                              products: analytics.topProducts,
                            ),
                            height: 250,
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingLg),
                      ],
                    );
                  },
                );
              },
            ),

            // ── Quick Actions ──
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildQuickActions(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    String? subtitle,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.black, width: AppTheme.borderWidth),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(icon, color: Colors.black, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.black, width: AppTheme.borderWidth),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthProvider authProvider) {
    final isAdmin = authProvider.role == 'admin';

    final actions = <_QuickAction>[
      if (isAdmin)
        _QuickAction(
          icon: Icons.inventory_2_rounded,
          label: 'Manage Products',
          color: AppTheme.primary,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
      _QuickAction(
        icon: Icons.swap_vert_rounded,
        label: 'Stock Adjustment',
        color: AppTheme.success,
        onTap: () => setState(() => _selectedIndex = isAdmin ? 2 : 1),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Transaction Logs',
        color: const Color(0xFFE17055),
        onTap: () => setState(() => _selectedIndex = isAdmin ? 3 : 2),
      ),
      if (isAdmin)
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'View Reports',
          color: const Color(0xFF6C5CE7),
          onTap: () => setState(() => _selectedIndex = 4),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 450
                ? 2
                : 1;
        final aspectRatio = constraints.maxWidth > 800
            ? 2.5
            : constraints.maxWidth > 450
                ? 2.0
                : 3.5;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacingMd,
          crossAxisSpacing: AppTheme.spacingMd,
          childAspectRatio: aspectRatio,
          children: actions.map((a) => _buildQuickActionCard(a)).toList(),
        );
      },
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: action.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Colors.black, width: AppTheme.borderWidth),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(action.icon, color: Colors.black, size: 22),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Widget child,
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.black, width: AppTheme.borderWidth),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (title == 'Stock Health') _buildLegend(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendItem(AppTheme.success, 'H'),
        const SizedBox(width: 8),
        _legendItem(AppTheme.warning, 'L'),
        const SizedBox(width: 8),
        _legendItem(AppTheme.danger, 'O'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Helpers
  // ════════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(AuthProvider authProvider) {
    return IconButton(
      onPressed: () => _confirmLogout(authProvider),
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'Logout',
    );
  }

  void _confirmLogout(AuthProvider authProvider) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'LOGOUT',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
            ),
            content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.black,
                ),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) authProvider.logout();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Data classes
// ═══════════════════════════════════════════════════════════════════
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.activeIcon,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
