import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/work_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/work_card.dart';
import 'add_work_screen.dart';
import 'work_list_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatHours(double hours) {
    int totalMinutes = (hours * 60).round();
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Consumer<WorkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentEntries = provider.workEntries.take(5).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern Sliver Header
              SliverAppBar.large(
                expandedHeight: 160,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: isDark ? const Color(0xFF0F0F0F) : theme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', height: 24, width: 24, 
                        errorBuilder: (_, __, ___) => const Icon(Icons.work_rounded, color: Colors.white, size: 20)),
                      const SizedBox(width: 8),
                      const Text('Office Buddy', 
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)
                      ),
                    ],
                  ),
                  background: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.blur_on_rounded, size: 250, color: Colors.white.withOpacity(0.05)),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Good ${DateTime.now().hour < 12 ? 'Morning' : DateTime.now().hour < 17 ? 'Afternoon' : 'Evening'}!',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            Text(
                              '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Summary
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'Monthly Total',
                              value: _formatHours(provider.totalMonthlyHours),
                              icon: Icons.timer_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1565C0)]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SummaryCard(
                              title: 'Projects',
                              value: '${provider.totalProjects}',
                              icon: Icons.folder_copy_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: "Today's Work",
                              value: '${provider.todayEntries} Logs',
                              icon: Icons.edit_calendar_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFE65100)]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SummaryCard(
                              title: 'Monthly Logs',
                              value: '${provider.getEntriesForMonth(DateTime.now().year, DateTime.now().month).length}',
                              icon: Icons.calendar_month_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Primary Actions
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildActionBtn(context, 'Add Work', Icons.add_task_rounded, Colors.blue, const AddWorkScreen()),
                          const SizedBox(width: 12),
                          _buildActionBtn(context, 'History', Icons.history_rounded, Colors.green, const WorkListScreen()),
                          const SizedBox(width: 12),
                          _buildActionBtn(context, 'Analytics', Icons.analytics_rounded, Colors.orange, const AnalyticsScreen()),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Recent Work Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (recentEntries.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkListScreen())),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              label: const Text('See All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recentEntries.isEmpty)
                        _buildEmptyState(context)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentEntries.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = recentEntries[index];
                            return WorkCard(
                              entry: entry, 
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddWorkScreen(entry: entry)),
                              ),
                              onDelete: () => _deleteEntry(context, provider, entry),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWorkScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Work'),
        elevation: 4,
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context, WorkProvider provider, dynamic entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Entry?'),
        content: const Text('This will permanently remove this work log.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteWorkEntry(entry.id);
    }
  }

  Widget _buildActionBtn(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text('No recent work history', 
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Tap "Add Work" to get started', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
