import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../providers/work_provider.dart';

class AddWorkScreen extends StatefulWidget {
  final WorkEntry? entry;
  const AddWorkScreen({super.key, this.entry});

  @override
  State<AddWorkScreen> createState() => _AddWorkScreenState();
}

class _AddWorkScreenState extends State<AddWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late DateTime _selectedDate;
  final _detailsController = TextEditingController();
  final _customProjectController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minsController = TextEditingController();

  bool _isCustomProject = false;
  bool _isLoading = false;
  String _selectedProject = '';
  double _workedHours = 0.0;

  @override
  void initState() {
    super.initState();
    
    if (widget.entry != null) {
      _selectedDate = widget.entry!.date;
      _detailsController.text = widget.entry!.details;
      
      int h = widget.entry!.workedHours.toInt();
      int m = ((widget.entry!.workedHours - h) * 60).round();
      _hoursController.text = h > 0 ? h.toString() : '';
      _minsController.text = m > 0 ? m.toString() : '';
      _workedHours = widget.entry!.workedHours;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<WorkProvider>();
        if (provider.availableProjects.contains(widget.entry!.projectName)) {
          setState(() {
            _selectedProject = widget.entry!.projectName;
            _isCustomProject = false;
          });
        } else {
          setState(() {
            _customProjectController.text = widget.entry!.projectName;
            _isCustomProject = true;
          });
        }
      });
    } else {
      _selectedDate = DateTime.now();
      _hoursController.text = '';
      _minsController.text = '';
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final projects = context.read<WorkProvider>().availableProjects;
        if (projects.isEmpty) {
          setState(() => _isCustomProject = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _customProjectController.dispose();
    _hoursController.dispose();
    _minsController.dispose();
    super.dispose();
  }

  void _updateWorkedHours() {
    final h = double.tryParse(_hoursController.text) ?? 0.0;
    final m = double.tryParse(_minsController.text) ?? 0.0;
    setState(() {
      _workedHours = h + (m / 60.0);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _toggleCustomProject(bool value) {
    setState(() {
      _isCustomProject = value;
      if (!value) {
        _customProjectController.clear();
      } else {
        _selectedProject = '';
      }
    });
  }

  Future<void> _saveEntry() async {
    _updateWorkedHours();
    if (!_formKey.currentState!.validate()) return;
    
    if (_workedHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter work duration'), 
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final projectName = _isCustomProject ? _customProjectController.text.trim() : _selectedProject;
      
      final entry = WorkEntry(
        id: widget.entry?.id ?? _uuid.v4(),
        date: _selectedDate,
        projectName: projectName,
        workedHours: _workedHours,
        details: _detailsController.text.trim(),
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      );

      if (widget.entry != null) {
        await context.read<WorkProvider>().updateWorkEntry(entry);
      } else {
        await context.read<WorkProvider>().addWorkEntry(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry != null ? 'Work log updated!' : 'Work log saved!'), 
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            expandedHeight: 150,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0F0F0F) : theme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.entry != null ? 'Edit Work Log' : 'Add Work Log', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Stack(
                children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Icon(
                      widget.entry != null ? Icons.edit_note_rounded : Icons.add_task_rounded, 
                      size: 160, 
                      color: Colors.white.withOpacity(0.08)
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Work Details'),
                    const SizedBox(height: 16),
                    
                    // Date Card
                    _buildInputCard(
                      onTap: () => _selectDate(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.calendar_today_rounded, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // Duration Card
                    _buildInputCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.timer_rounded, color: Colors.orange, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Text('Time Spent', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeInput(
                                  controller: _hoursController,
                                  label: 'Hours',
                                  hint: '0',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeInput(
                                  controller: _minsController,
                                  label: 'Minutes',
                                  hint: '00',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // Project Card
                    Consumer<WorkProvider>(
                      builder: (context, provider, child) {
                        final projects = provider.availableProjects;
                        return _buildInputCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.folder_rounded, color: Colors.green, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('Project', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  if (projects.isNotEmpty)
                                    Row(
                                      children: [
                                        Text('New', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Switch.adaptive(
                                            value: _isCustomProject,
                                            onChanged: _toggleCustomProject,
                                            activeColor: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isCustomProject || projects.isEmpty)
                                TextFormField(
                                  controller: _customProjectController,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  decoration: _buildInputDecoration('Enter project name', Icons.edit_rounded),
                                  validator: (v) => (_isCustomProject || projects.isEmpty) && (v == null || v.isEmpty) ? 'Project name is required' : null,
                                )
                              else
                                DropdownButtonFormField<String>(
                                  value: _selectedProject.isEmpty ? null : _selectedProject,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  decoration: _buildInputDecoration('Select existing project', Icons.list_rounded),
                                  items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                                  onChanged: (v) => setState(() => _selectedProject = v ?? ''),
                                  validator: (v) => !_isCustomProject && (v == null || v.isEmpty) ? 'Please select a project' : null,
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    
                    // Notes Card
                    _buildInputCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.notes_rounded, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Text('Notes', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _detailsController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 15),
                            decoration: _buildInputDecoration('What did you work on?', Icons.description_outlined),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 8,
                            shadowColor: theme.primaryColor.withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.entry != null ? Icons.update_rounded : Icons.save_rounded),
                              const SizedBox(width: 12),
                              Text(widget.entry != null ? 'Update Work Log' : 'Save Work Log', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _updateWorkedHours(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            filled: true,
            fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildInputCard({required Widget child, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: child,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
      filled: true,
      fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
    );
  }
}
