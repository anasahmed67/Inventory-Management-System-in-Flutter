/// Dashboard Screen
///
/// The main landing page after a successful login.
/// It acts as a shell providing the main navigation menu (sidebar on web/desktop,
/// bottom nav on mobile) and displays an overview of stock health and analytics.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/neo_card.dart';
import '../widgets/animated_counter.dart';
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
    // Fetch initial data right after the widget builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // UI adapts based on the user's role (e.g., hiding 'Products' CRUD from non-admins)
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

    // ── Item 5: Page Transitions ──
    final animatedContent = AnimatedSwitcher(
      duration: AppTheme.normalAnim,
      switchInCurve: AppTheme.defaultCurve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_selectedIndex), child: content),
    );

    if (isWide) {
      // ── Desktop: persistent sidebar ──
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(navItems, authProvider),
            Expanded(child: animatedContent),
          ],
        ),
      );
    } else {
      // ── Mobile: drawer + bottom nav ──
      return Scaffold(
        appBar: AppBar(
          title: Text(
            currentLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [_buildThemeToggle(), _buildLogoutButton(authProvider)],
        ),
        body: animatedContent,
        bottomNavigationBar: _buildBottomNav(navItems),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Theme Toggle Button
  // ════════════════════════════════════════════════════════════════
  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return IconButton(
          onPressed: themeProvider.toggleTheme,
          icon: AnimatedSwitcher(
            duration: AppTheme.quickAnim,
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              key: ValueKey(themeProvider.isDark),
            ),
          ),
          tooltip: themeProvider.isDark ? 'Switch to Light' : 'Switch to Dark',
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Sidebar (Desktop)
  // ════════════════════════════════════════════════════════════════
  Widget _buildSidebar(List<_NavItem> items, AuthProvider authProvider) {
    final role = authProvider.role?.toUpperCase() ?? 'STAFF';
    final isDark = AppTheme.isDark(context);
    final sidebarBgColor = AppTheme.sidebarColor(context);

    return Container(
      width: AppTheme.sidebarWidth,
      decoration: BoxDecoration(
        color: sidebarBgColor,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.black,
            width: AppTheme.borderWidth,
          ),
        ),
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
                    'Stockify',
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

          // ── Dark mode toggle in sidebar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: themeProvider.toggleTheme,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingMd - 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceVariant
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            themeProvider.isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Text(
                            themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

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
      indicatorColor: AppTheme.primary.withAlpha(30),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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

  /// Builds the default homepage showing high-level stats, charts, and shortcuts.
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

    final isDark = AppTheme.isDark(context);

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
            SizedBox(
              width: double.infinity,
              child: Wrap(
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
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: isWide ? 28 : 22,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s your inventory overview',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                      border: Border.all(
                        color: AppTheme.borderColor(context),
                        width: 2,
                      ),
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
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Item 2 & 3: Staggered Stat Cards with Animated Counters ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                final cards = [
                  _StaggeredEntry(
                    index: 0,
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.inventory_2_rounded,
                      iconColor: AppTheme.primary,
                      iconBg: AppTheme.surfaceVariantColor(context),
                      label: 'Total Products',
                      value: totalProducts,
                      width: isWide ? null : double.infinity,
                    ),
                  ),
                  _StaggeredEntry(
                    index: 1,
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppTheme.danger,
                      iconBg: isDark
                          ? const Color(0xFF3D1F1F)
                          : AppTheme.dangerLight,
                      label: 'Low Stock',
                      value: lowStockCount,
                      subtitle: lowStockCount > 0
                          ? 'Needs attention'
                          : 'All good',
                      width: isWide ? null : double.infinity,
                    ),
                  ),
                  _StaggeredEntry(
                    index: 2,
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.payments_rounded,
                      iconColor: AppTheme.success,
                      iconBg: isDark
                          ? const Color(0xFF1A3D2E)
                          : AppTheme.successLight,
                      label: 'Total Value',
                      value: totalValue.toInt(),
                      prefix: AppTheme.currencySymbol,
                      width: isWide ? null : double.infinity,
                    ),
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
              _StaggeredEntry(
                index: 3,
                child: _buildAlertBanner(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  text:
                      '$lowStockCount product${lowStockCount > 1 ? 's' : ''} below stock threshold',
                  color: AppTheme.danger,
                  bgColor: isDark
                      ? const Color(0xFF3D1F1F)
                      : AppTheme.dangerLight,
                ),
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
                                child: _StaggeredEntry(
                                  index: 4,
                                  child: _buildChartCard(
                                    context: context,
                                    title: 'Stock Health',
                                    child: StockStatusChart(
                                      summary: analytics.stockSummary,
                                    ),
                                    height: 300,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingLg),
                              Expanded(
                                child: _StaggeredEntry(
                                  index: 5,
                                  child: _buildChartCard(
                                    context: context,
                                    title: 'Top 5 Products (Qty)',
                                    child: TopProductsChart(
                                      products: analytics.topProducts,
                                    ),
                                    height: 300,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _StaggeredEntry(
                            index: 4,
                            child: _buildChartCard(
                              context: context,
                              title: 'Stock Health',
                              child: StockStatusChart(
                                summary: analytics.stockSummary,
                              ),
                              height: 250,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          _StaggeredEntry(
                            index: 5,
                            child: _buildChartCard(
                              context: context,
                              title: 'Top 5 Products (Qty)',
                              child: TopProductsChart(
                                products: analytics.topProducts,
                              ),
                              height: 250,
                            ),
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

  // ── Item 3: Stat Card with Animated Counter ──
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required int value,
    String? subtitle,
    String prefix = '',
    double? width,
  }) {
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);
    final secondaryCol = AppTheme.secondaryTextColor(context);

    return NeoCard(
      width: width,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: borderCol, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedCounter(
                  value: value.toString(),
                  prefix: prefix,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondaryCol,
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
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    final borderCol = AppTheme.borderColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
        boxShadow: AppTheme.adaptiveSoftShadow(context),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textColor(context),
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
          children: actions
              .asMap()
              .entries
              .map(
                (entry) => _StaggeredEntry(
                  index: 6 + entry.key,
                  child: _buildQuickActionCard(entry.value),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return NeoCard(
      onTap: action.onTap,
      color: action.color,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
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
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.black,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required Widget child,
    required double height,
  }) {
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
        boxShadow: AppTheme.adaptiveShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              // ── Item 8: Full Legend Labels ──
              if (title == 'Stock Health') _buildLegend(context),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── Item 8: Full legend labels ──
  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendItem(context, AppTheme.success, 'Healthy'),
        const SizedBox(width: 12),
        _legendItem(context, AppTheme.warning, 'Low'),
        const SizedBox(width: 12),
        _legendItem(context, AppTheme.danger, 'Out'),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.borderColor(context),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.secondaryTextColor(context),
            fontWeight: FontWeight.w700,
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
// Item 2: Staggered Entry Animation Widget
// ═══════════════════════════════════════════════════════════════════
class _StaggeredEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
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
