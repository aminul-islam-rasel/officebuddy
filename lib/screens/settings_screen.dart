import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/work_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await context.read<WorkProvider>().exportData();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text('Export Success', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your monthly report has been generated successfully.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          filePath.split('/').last,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(filePath)], text: 'My Work Report');
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Report'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await context.read<WorkProvider>().createBackup();
      if (mounted) {
        await Share.shareXFiles([XFile(filePath)], text: 'Office Buddy Data Backup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && (result.files.single.path != null || result.files.single.bytes != null)) {
        setState(() => _isLoading = true);
        
        String content;
        if (result.files.single.bytes != null) {
          content = utf8.decode(result.files.single.bytes!);
        } else {
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        }
        
        if (mounted) {
          await context.read<WorkProvider>().restoreBackup(content);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data restored successfully!'), 
              behavior: SnackBarBehavior.floating, 
              backgroundColor: Colors.green
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Restore error detail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore failed: Invalid file or data'), 
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete all your work history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await context.read<WorkProvider>().clearAllData();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F0F0F) : theme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Icon(Icons.settings_suggest_rounded, size: 220, color: Colors.white.withOpacity(0.05)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Preference'),
                  _buildCard([
                    _buildTile(
                      icon: Icons.palette_outlined,
                      color: Colors.indigo,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark themes',
                      trailing: Consumer<ThemeProvider>(
                        builder: (context, tp, _) => Switch.adaptive(
                          value: tp.isDarkMode,
                          onChanged: (v) => tp.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                          activeColor: theme.primaryColor,
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 28),
                  _buildSectionLabel('Data & Reports'),
                  _buildCard([
                    _buildTile(
                      icon: Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent,
                      title: 'Export PDF Report',
                      subtitle: 'Generate summary for this month',
                      onTap: _isLoading ? null : _exportData,
                    ),
                    const Divider(indent: 70, height: 1, endIndent: 20),
                    _buildTile(
                      icon: Icons.backup_rounded,
                      color: Colors.blue,
                      title: 'Backup to Cloud/Local',
                      subtitle: 'Save your data as a JSON file',
                      onTap: _isLoading ? null : _createBackup,
                    ),
                    const Divider(indent: 70, height: 1, endIndent: 20),
                    _buildTile(
                      icon: Icons.restore_rounded,
                      color: Colors.teal,
                      title: 'Restore Backup',
                      subtitle: 'Import data from a previous backup',
                      onTap: _isLoading ? null : _restoreBackup,
                    ),
                  ]),

                  const SizedBox(height: 28),
                  _buildSectionLabel('Danger Zone'),
                  _buildCard([
                    _buildTile(
                      icon: Icons.delete_forever_rounded,
                      color: Colors.red,
                      title: 'Clear All Records',
                      titleColor: Colors.red,
                      subtitle: 'This cannot be undone',
                      onTap: _isLoading ? null : _clearAllData,
                    ),
                  ], borderColor: Colors.red.withOpacity(0.1)),

                  const SizedBox(height: 48),
                  _buildAboutSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading ? const LinearProgressIndicator() : null,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {Color? borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
    );
  }

  Widget _buildAboutSection() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 48,
              width: 48,
              errorBuilder: (_, __, ___) => Icon(Icons.work_rounded, color: Theme.of(context).primaryColor, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Office Buddy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text('Version $_appVersion', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Made with ❤️ for Professionals', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
