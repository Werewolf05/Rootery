import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/app_models.dart';
import '../../services/batch_service.dart';
import '../../theme/rootery_theme.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/batch_card.dart';
import '../../widgets/loading_skeleton.dart';

class HydroBatchesScreen extends StatefulWidget {
  const HydroBatchesScreen({super.key});

  @override
  State<HydroBatchesScreen> createState() => _HydroBatchesScreenState();
}

class _HydroBatchesScreenState extends State<HydroBatchesScreen>
    with SingleTickerProviderStateMixin {
  final BatchService _batchService = BatchService();
  List<HydroBatch> _all = [];
  bool _loading = true;

  late final AnimationController _enterCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _batchService.getBatches();
    if (!mounted) return;
    setState(() {
      _all = rows;
      _loading = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    CropType crop = CropType.lettuce;
    DateTime planting = DateTime.now();
    int duration = 30;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            backgroundColor: RooteryTheme.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: RooteryTheme.borderLight),
            ),
            title: Text(
              'Create Hydro Batch',
              style: RooteryTheme.ui(22, weight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: RooteryTheme.ui(14),
                    decoration: const InputDecoration(labelText: 'Batch name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<CropType>(
                    value: crop,
                    items: CropType.values
                        .where((e) => e != CropType.custom)
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setLocal(() => crop = v ?? CropType.lettuce),
                    decoration: const InputDecoration(labelText: 'Crop type'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => duration = int.tryParse(v) ?? 30,
                    decoration: const InputDecoration(
                      labelText: 'Growth duration (days)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Planting date',
                        style: RooteryTheme.ui(14, color: RooteryTheme.textMid),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                            initialDate: planting,
                          );
                          if (d != null) {
                            setLocal(() => planting = d);
                          }
                        },
                        child: Text(
                          '${planting.year}-${planting.month}-${planting.day}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: RooteryTheme.ui(14, color: RooteryTheme.textMid),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RooteryTheme.green400,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                ),
                child: Text(
                  'Create',
                  style: RooteryTheme.ui(
                    14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (created == true) {
      final batch = HydroBatch(
        id: 'batch_${DateTime.now().millisecondsSinceEpoch}',
        batchName: nameCtrl.text.trim().isEmpty
            ? 'Unnamed Batch'
            : nameCtrl.text.trim(),
        cropType: crop,
        plantingDate: planting,
        expectedHarvestDate: planting.add(Duration(days: duration)),
        growthDurationDays: duration,
        status: planting.isAfter(DateTime.now())
            ? BatchStatus.upcoming
            : BatchStatus.active,
      );
      try {
        await _batchService.createBatch(batch);
        await _load();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not create batch. Check database connection/RLS.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(HydroBatch batch) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RooteryTheme.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: RooteryTheme.borderLight),
          ),
          title: Text(
            'Remove Batch?',
            style: RooteryTheme.ui(20, weight: FontWeight.w600),
          ),
          content: Text(
            'This will remove "${batch.batchName}" from your batch list.',
            style: RooteryTheme.ui(14, color: RooteryTheme.textMid),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: RooteryTheme.ui(14, color: RooteryTheme.textMid),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: RooteryTheme.redAlert,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Remove',
                style: RooteryTheme.ui(
                  14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _batchService.deleteBatch(batch.id);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Removed ${batch.batchName}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delete failed on server. Batch was not removed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _all.where((e) => e.status == BatchStatus.active).toList();
    final upcoming = _all
        .where((e) => e.status == BatchStatus.upcoming)
        .toList();
    final completed = _all
        .where((e) => e.status == BatchStatus.completed)
        .toList();

    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: RooteryTheme.bgSurface,
        title: Text(
          'Crop Batches',
          style: RooteryTheme.ui(22, weight: FontWeight.w600),
        ),
      ),
      floatingActionButton: _ScaleButton(
        onTap: _showCreateDialog,
        semanticsLabel: 'Create new crop batch',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: RooteryTheme.green400,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [RooteryTheme.cardShadow],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'New Batch',
                style: RooteryTheme.ui(
                  14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                LoadingSkeleton.text(width: 140, height: 14),
                SizedBox(height: 8),
                LoadingSkeleton.card(height: 110),
                SizedBox(height: 10),
                LoadingSkeleton.text(width: 170, height: 14),
                SizedBox(height: 8),
                LoadingSkeleton.card(height: 110),
                SizedBox(height: 10),
                LoadingSkeleton.text(width: 180, height: 14),
                SizedBox(height: 8),
                LoadingSkeleton.card(height: 110),
              ],
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: RefreshIndicator(
                  color: RooteryTheme.green400,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _section('Active Batches', active),
                      const SizedBox(height: 10),
                      _section('Upcoming Batches', upcoming),
                      const SizedBox(height: 10),
                      _section('Completed Batches', completed),
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _section(String title, List<HydroBatch> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: RooteryTheme.ui(
            13,
            weight: FontWeight.w500,
            color: RooteryTheme.textMid,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: RooteryTheme.cardDecoration(radius: 20),
            child: Text(
              'No batches in this category.',
              style: RooteryTheme.ui(14, color: RooteryTheme.textMid),
            ),
          ),
        AnimationLimiter(
          child: Column(
            children: List.generate(items.length, (index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                delay: const Duration(milliseconds: 60),
                child: SlideAnimation(
                  verticalOffset: 16,
                  child: FadeInAnimation(
                    child: BatchCard(
                      batch: items[index],
                      onDelete: () => _confirmAndDelete(items[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ScaleButton extends StatefulWidget {
  const _ScaleButton({
    required this.onTap,
    required this.child,
    required this.semanticsLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String semanticsLabel;

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapCancel: () => setState(() => _scale = 1),
        onTapUp: (_) => setState(() => _scale = 1),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
