import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kidsapp/services/interaction_service.dart';
import 'package:kidsapp/theme/app_theme.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = InteractionService.getMyReports();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _createReport() async {
    final reasonController = TextEditingController(text: 'General');
    final descController = TextEditingController();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        final bottom = MediaQuery.of(c).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report a problem',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    final desc = descController.text.trim();
                    if (reason.isEmpty && desc.isEmpty) return;
                    await InteractionService.submitReport(
                      null,
                      reason.isEmpty ? 'General' : reason,
                      desc,
                    );
                    if (!c.mounted) return;
                    Navigator.pop(c, true);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit'),
                ),
              ),
            ],
          ),
        );
      },
    );

    reasonController.dispose();
    descController.dispose();

    if (created == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report submitted')));
      await _refresh();
    }
  }

  void _openDetails(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReportProblemDetailScreen(reportId: report['id'] as int),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'Report a problem',
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _createReport,
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'New report',
          ),
          IconButton(
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <Map<String, dynamic>>[];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Could not load reports.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  Text(
                    'No reports yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Tap + to submit a report.'),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = items[index];
                final status = (r['status'] ?? 'open').toString();
                final reason = (r['reason'] ?? 'Report').toString();
                final createdAt = r['created_at'] == null
                    ? null
                    : DateTime.tryParse(r['created_at'].toString());

                final subtitle = [
                  'Status: $status',
                  if (createdAt != null)
                    'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal())}',
                ].join(' • ');

                return ListTile(
                  leading: const Icon(
                    Icons.bug_report_rounded,
                    color: AppColors.primaryRed,
                  ),
                  title: Text(
                    reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDetails(r),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ReportProblemDetailScreen extends StatefulWidget {
  final int reportId;

  const ReportProblemDetailScreen({super.key, required this.reportId});

  @override
  State<ReportProblemDetailScreen> createState() =>
      _ReportProblemDetailScreenState();
}

class _ReportProblemDetailScreenState extends State<ReportProblemDetailScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = InteractionService.getReportById(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'Report details',
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final r = snapshot.data;
          if (r == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Report not found.'),
            );
          }

          final status = (r['status'] ?? 'open').toString();
          final reason = (r['reason'] ?? '').toString();
          final description = (r['description'] ?? '').toString();
          final response = (r['response'] ?? '').toString().trim();
          final createdAt = r['created_at'] == null
              ? null
              : DateTime.tryParse(r['created_at'].toString());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _kv('Status', status),
              _kv(
                'Submitted',
                createdAt == null
                    ? '—'
                    : DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(createdAt.toLocal()),
              ),
              const SizedBox(height: 12),
              _kv('Problem', reason.isEmpty ? '—' : reason),
              const SizedBox(height: 12),
              _kv('Description', description.isEmpty ? '—' : description),
              const SizedBox(height: 12),
              _kv(
                'Kids Konnect response',
                response.isEmpty ? 'Waiting for response…' : response,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(v),
        ],
      ),
    );
  }
}
