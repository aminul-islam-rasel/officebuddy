import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../providers/work_provider.dart';
import '../widgets/work_card.dart';
import 'add_work_screen.dart';

class WorkListScreen extends StatefulWidget {
  const WorkListScreen({super.key});

  @override
  State<WorkListScreen> createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedProject = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatHours(double hours) {
    int h = hours.toInt();
    int m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  List<WorkEntry> _getFilteredEntries(WorkProvider provider) {
    List<WorkEntry> entries = provider.workEntries;

    entries = entries
        .where((entry) =>
            entry.date.month == _selectedMonth &&
            entry.date.year == _selectedYear)
        .toList();

    if (_selectedProject != 'All') {
      entries = entries
          .where((entry) => entry.projectName == _selectedProject)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      entries = entries
          .where((entry) =>
              entry.projectName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              entry.details.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Consumer<WorkProvider>(
        builder: (context, provider, child) {
          final filteredEntries = _getFilteredEntries(provider);
          final availableProjects = ['All', ...provider.availableProjects];
          final totalHours = filteredEntries.fold(0.0, (sum, item) => sum + item.workedHours);

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
                  title: const Text('Work History', 
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                  background: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Icon(Icons.history_rounded, size: 160, color: Colors.white.withOpacity(0.05)),
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
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddWorkScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    children: [
                      _buildSummaryCard(totalHours, filteredEntries.length, theme),
                      const SizedBox(height: 24),
                      _buildSearchAndFilters(isDark, theme, availableProjects),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              filteredEntries.isEmpty
                  ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(context))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WorkCard(
                                entry: filteredEntries[index],
                                onEdit: () => _editEntry(filteredEntries[index]),
                                onDelete: () => _deleteEntry(filteredEntries[index]),
                              ),
                            );
                          },
                          childCount: filteredEntries.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double hours, int count, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Time', _formatHours(hours), Icons.access_time_filled_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('Logs Found', count.toString(), Icons.fact_check_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDark, ThemeData theme, List<String> projects) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search projects or notes...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFilterBox(
              child: DropdownButton<int>(
                value: _selectedMonth,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                items: List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(DateFormat.MMM().format(DateTime(2023, i + 1)), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
            const SizedBox(width: 10),
            _buildFilterBox(
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                items: List.generate(5, (i) {
                  final year = DateTime.now().year - i;
                  return DropdownMenuItem(value: year, child: Text(year.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
                }),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
            ),
            const SizedBox(width: 10),
            _buildFilterBox(
              flex: 2,
              child: DropdownButton<String>(
                value: _selectedProject,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedProject = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBox({required Widget child, int flex = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!),
        ),
        child: DropdownButtonHideUnderline(child: child),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          const Text('No records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try changing the filters or search term', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _editEntry(WorkEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddWorkScreen(entry: entry)),
    );
  }

  Future<void> _deleteEntry(WorkEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Entry?'),
        content: const Text('This will permanently remove this work log from your history.'),
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
      await context.read<WorkProvider>().deleteWorkEntry(entry.id);
    }
  }
}
