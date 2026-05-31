import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../providers/work_provider.dart';
import '../pdf/pdf_generator.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  String _formatHours(double hours) {
    int totalMinutes = (hours * 60).round();
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Consumer<WorkProvider>(
        builder: (context, provider, child) {
          final projectHours = provider.projectHours;

          if (projectHours.isEmpty) {
            return _buildEmptyState(context);
          }

          final totalHours = projectHours.values.fold(0.0, (a, b) => a + b);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                expandedHeight: 160,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: isDark ? const Color(0xFF0F0F0F) : theme.primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Insights & Analytics',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)
                  ),
                  background: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(Icons.insights_rounded, size: 180, color: Colors.white.withOpacity(0.05)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard(context, 'Total Time', _formatHours(totalHours), Icons.timer_rounded, Colors.blue),
                          _buildStatCard(context, 'Projects', '${projectHours.length}', Icons.folder_rounded, Colors.green),
                          _buildStatCard(context, 'Daily Avg', _formatHours(totalHours / 30), Icons.auto_graph_rounded, Colors.orange),
                          _buildStatCard(context, 'Top Focus', projectHours.entries.reduce((a, b) => a.value > b.value ? a : b).key, Icons.workspace_premium_rounded, Colors.purple),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Monthly Progress Bar Chart
                      _buildSectionHeader('Work Intensity (Last 30 Days)'),
                      const SizedBox(height: 16),
                      _buildDailyChartCard(context, provider.dailyHours),

                      const SizedBox(height: 32),

                      // Report Generation Card
                      _buildSectionHeader('Reports'),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        context,
                        title: 'Detailed PDF Reports',
                        subtitle: 'Generate professional work logs for clients',
                        icon: Icons.picture_as_pdf_rounded,
                        color: Colors.redAccent,
                        onTap: () => _showPDFOptions(context, provider),
                      ),

                      const SizedBox(height: 32),

                      // Distribution Chart
                      _buildSectionHeader('Time Allocation'),
                      const SizedBox(height: 16),
                      _buildDistributionChartCard(context, projectHours, totalHours),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChartCard(BuildContext context, Map<DateTime, double> dailyHours) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final now = DateTime.now();
    final last30Days = List.generate(30, (index) {
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - index));
    });

    double maxH = 8.0;
    for (var d in last30Days) {
      final h = dailyHours[d] ?? 0.0;
      if (h > maxH) maxH = h;
    }
    maxH = (maxH + 1).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxH,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: isDark ? const Color(0xFF333333) : Colors.white,
                    tooltipRoundedRadius: 12,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = last30Days[groupIndex];
                      return BarTooltipItem(
                        '${DateFormat('MMM d').format(date)}\n',
                        const TextStyle(color: Colors.grey, fontSize: 10),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toStringAsFixed(1)}h',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < last30Days.length) {
                          if (index % 7 == 0 || index == last30Days.length - 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(last30Days[index]),
                                style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: last30Days.asMap().entries.map((entry) {
                  final date = entry.value;
                  final hours = dailyHours[date] ?? 0.0;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        gradient: LinearGradient(
                          colors: [Colors.blue.withOpacity(0.6), Colors.blue],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChartCard(BuildContext context, Map<String, double> projectHours, double totalHours) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: _buildPieSections(projectHours, totalHours),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text(_formatHours(totalHours), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...projectHours.entries.map((entry) {
            final index = projectHours.keys.toList().indexOf(entry.key);
            final color = _getColor(index);
            final percentage = (entry.value / totalHours) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatHours(entry.value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> projectHours, double totalHours) {
    return projectHours.entries.map((entry) {
      final index = projectHours.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '',
        color: _getColor(index),
        radius: 25,
        badgeWidget: null,
      );
    }).toList();
  }

  Color _getColor(int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF3F51B5)
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          const Text('No data insights yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Log some work to unlock powerful analytics', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showPDFOptions(BuildContext context, WorkProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Generate Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose a report format to export', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildDialogTile(Icons.calendar_month_rounded, 'Monthly Summary', 'Complete log for current month', Colors.blue, () {
              Navigator.pop(context);
              _showMonthlyPDFOptions(context, provider);
            }),
            const SizedBox(height: 12),
            _buildDialogTile(Icons.folder_copy_rounded, 'Project-specific Logs', 'Detailed history for a single project', Colors.green, () {
              Navigator.pop(context);
              _showProjectPDFOptions(context, provider);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: color.withOpacity(0.05),
      leading: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
        child: Icon(icon, color: color)
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }

  void _showMonthlyPDFOptions(BuildContext context, WorkProvider provider) {
    final now = DateTime.now();
    final entries = provider.getEntriesForMonth(now.year, now.month);
    _showReportActionsDialog(context, 'Monthly Report', '${entries.length} entries for ${WorkProvider.getMonthName(now.month)}', () async {
      await PDFGenerator.previewMonthlyReport(context: context, entries: entries, year: now.year, month: now.month);
    }, () async {
      await PDFGenerator.shareMonthlyReport(context: context, entries: entries, year: now.year, month: now.month);
    });
  }

  void _showProjectPDFOptions(BuildContext context, WorkProvider provider) {
    final projectHours = provider.projectHours;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Select Project', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: projectHours.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final project = projectHours.keys.elementAt(index);
                  final List<WorkEntry> entries = provider.getEntriesForProject(project);
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: CircleAvatar(
                      backgroundColor: _getColor(index).withOpacity(0.1), 
                      radius: 20, 
                      child: Text(project[0].toUpperCase(), style: TextStyle(color: _getColor(index), fontWeight: FontWeight.bold))
                    ),
                    title: Text(project, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${entries.length} records'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportActionsDialog(context, project, '${entries.length} logs found', () async {
                        await PDFGenerator.previewProjectReport(context: context, entries: entries, projectName: project);
                      }, () async {
                        await PDFGenerator.shareProjectReport(context: context, entries: entries, projectName: project);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportActionsDialog(BuildContext context, String title, String subtitle, VoidCallback onPreview, VoidCallback onShare) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPreview, 
                    icon: const Icon(Icons.visibility_rounded), 
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  )
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShare, 
                    icon: const Icon(Icons.share_rounded), 
                    label: const Text('Share PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
