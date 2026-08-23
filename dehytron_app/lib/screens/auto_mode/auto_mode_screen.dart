import 'package:flutter/material.dart';
import '../../services/command_service.dart';
import '../../theme/rootery_theme.dart';

class CropPreset {
  final int index;
  final String name;
  final String category;
  final int temperature;
  final double airflow;
  final int timeMinutes;
  final IconData icon;

  CropPreset({
    required this.index,
    required this.name,
    required this.category,
    required this.temperature,
    required this.airflow,
    required this.timeMinutes,
    required this.icon,
  });
}

class AutoModeScreen extends StatefulWidget {
  const AutoModeScreen({super.key});

  @override
  State<AutoModeScreen> createState() => _AutoModeScreenState();
}

class _AutoModeScreenState extends State<AutoModeScreen> {
  final CommandService _commandService = CommandService();
  bool _multiSelectMode = false;
  final Set<int> _selectedCropIndexes = {};

  final List<CropPreset> _cropPresets = [
    // Vegetables (matching database order)
    CropPreset(
      index: 0,
      name: 'Tomato',
      category: 'Vegetables',
      temperature: 60,
      airflow: 2.0,
      timeMinutes: 180,
      icon: Icons.local_florist,
    ),
    CropPreset(
      index: 1,
      name: 'Carrot',
      category: 'Vegetables',
      temperature: 55,
      airflow: 1.5,
      timeMinutes: 150,
      icon: Icons.eco,
    ),
    CropPreset(
      index: 5,
      name: 'Onion',
      category: 'Vegetables',
      temperature: 55,
      airflow: 2.0,
      timeMinutes: 180,
      icon: Icons.circle_outlined,
    ),
    CropPreset(
      index: 6,
      name: 'Potato',
      category: 'Vegetables',
      temperature: 60,
      airflow: 2.5,
      timeMinutes: 200,
      icon: Icons.circle,
    ),
    CropPreset(
      index: 9,
      name: 'Beans',
      category: 'Vegetables',
      temperature: 55,
      airflow: 2.0,
      timeMinutes: 150,
      icon: Icons.grain,
    ),
    CropPreset(
      index: 16,
      name: 'Cauliflower',
      category: 'Vegetables',
      temperature: 60,
      airflow: 3.0,
      timeMinutes: 180,
      icon: Icons.cloud,
    ),
    CropPreset(
      index: 17,
      name: 'Cabbage',
      category: 'Vegetables',
      temperature: 55,
      airflow: 2.0,
      timeMinutes: 160,
      icon: Icons.grass,
    ),
    CropPreset(
      index: 18,
      name: 'Capsicum',
      category: 'Vegetables',
      temperature: 55,
      airflow: 2.5,
      timeMinutes: 150,
      icon: Icons.local_fire_department,
    ),
    CropPreset(
      index: 19,
      name: 'Peas',
      category: 'Vegetables',
      temperature: 50,
      airflow: 1.5,
      timeMinutes: 140,
      icon: Icons.circle_outlined,
    ),
    // Fruits
    CropPreset(
      index: 2,
      name: 'Apple',
      category: 'Fruits',
      temperature: 50,
      airflow: 1.0,
      timeMinutes: 200,
      icon: Icons.apple,
    ),
    CropPreset(
      index: 3,
      name: 'Banana',
      category: 'Fruits',
      temperature: 50,
      airflow: 2.5,
      timeMinutes: 160,
      icon: Icons.set_meal,
    ),
    CropPreset(
      index: 8,
      name: 'Mango',
      category: 'Fruits',
      temperature: 55,
      airflow: 3.5,
      timeMinutes: 220,
      icon: Icons.set_meal,
    ),
    CropPreset(
      index: 10,
      name: 'Orange',
      category: 'Fruits',
      temperature: 50,
      airflow: 1.5,
      timeMinutes: 180,
      icon: Icons.circle,
    ),
    CropPreset(
      index: 11,
      name: 'Pineapple',
      category: 'Fruits',
      temperature: 55,
      airflow: 2.5,
      timeMinutes: 210,
      icon: Icons.set_meal,
    ),
    CropPreset(
      index: 13,
      name: 'Lemon',
      category: 'Fruits',
      temperature: 45,
      airflow: 1.5,
      timeMinutes: 100,
      icon: Icons.circle,
    ),
    CropPreset(
      index: 14,
      name: 'Coconut',
      category: 'Fruits',
      temperature: 55,
      airflow: 3.0,
      timeMinutes: 240,
      icon: Icons.circle,
    ),
    CropPreset(
      index: 15,
      name: 'Papaya',
      category: 'Fruits',
      temperature: 55,
      airflow: 2.5,
      timeMinutes: 200,
      icon: Icons.set_meal,
    ),
    // Spices
    CropPreset(
      index: 4,
      name: 'Chilli',
      category: 'Spices',
      temperature: 55,
      airflow: 3.0,
      timeMinutes: 140,
      icon: Icons.local_fire_department,
    ),
    CropPreset(
      index: 7,
      name: 'Ginger',
      category: 'Spices',
      temperature: 50,
      airflow: 1.0,
      timeMinutes: 160,
      icon: Icons.spa,
    ),
    // Leafy
    CropPreset(
      index: 12,
      name: 'Spinach',
      category: 'Leafy',
      temperature: 45,
      airflow: 1.0,
      timeMinutes: 120,
      icon: Icons.local_florist,
    ),
  ];

  Future<void> _selectCrop(CropPreset crop) async {
    try {
      await _commandService.selectCrop(crop.index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âœ… ${crop.name} preset activated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('âŒ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _activateSelected() async {
    if (_selectedCropIndexes.isEmpty) return;
    final selected = _cropPresets.where((c) => _selectedCropIndexes.contains(c.index)).toList();
    try {
      for (var crop in selected) {
        await _commandService.selectCrop(crop.index);
        // small delay so commands are ordered and ESP32 has time to pick them up
        await Future.delayed(const Duration(milliseconds: 250));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('âœ… ${selected.length} presets activated'), backgroundColor: Colors.green),
        );
        setState(() {
          _selectedCropIndexes.clear();
          _multiSelectMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('âŒ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group crops by category
    final Map<String, List<CropPreset>> categorizedCrops = {};
    for (var crop in _cropPresets) {
      if (!categorizedCrops.containsKey(crop.category)) {
        categorizedCrops[crop.category] = [];
      }
      categorizedCrops[crop.category]!.add(crop);
    }

    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        title: const Text('Auto Mode - Crop Presets'),
        backgroundColor: RooteryTheme.card,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('Multi', style: TextStyle(color: Colors.white, fontSize: 12)),
                Switch(
                  value: _multiSelectMode,
                  activeColor: RooteryTheme.accentGreen,
                  onChanged: (v) => setState(() => _multiSelectMode = v),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
          itemCount: categorizedCrops.length,
        itemBuilder: (context, categoryIndex) {
          final category = categorizedCrops.keys.elementAt(categoryIndex);
          final crops = categorizedCrops[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 8,
                  left: 4,
                  right: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RooteryTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: RooteryTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category,
                      style: const TextStyle(
                        color: RooteryTheme.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${crops.length})',
                      style: TextStyle(
                        color: RooteryTheme.subText,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Crops in this category
              ...crops
                  .map(
                    (crop) {
                      final isSelected = _selectedCropIndexes.contains(crop.index);
                      return Card(
                        color: RooteryTheme.card,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? RooteryTheme.accentGreen.withOpacity(0.6)
                                : RooteryTheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                          if (_multiSelectMode) {
                            setState(() {
                              if (isSelected) _selectedCropIndexes.remove(crop.index);
                              else _selectedCropIndexes.add(crop.index);
                            });
                          } else {
                            _selectCrop(crop);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: RooteryTheme.accentGreen.withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      crop.icon,
                                      color: RooteryTheme.accentGreen,
                                      size: 28,
                                    ),
                                    if (_multiSelectMode && isSelected)
                                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Crop details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          crop.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: RooteryTheme.accentGreen
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '#${crop.index}',
                                            style: TextStyle(
                                              color: RooteryTheme.accentGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.thermostat,
                                          size: 16,
                                          color: RooteryTheme.subText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${crop.temperature}Â°C',
                                          style: const TextStyle(
                                            color: RooteryTheme.subText,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.air,
                                          size: 16,
                                          color: RooteryTheme.subText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${crop.airflow} m/s',
                                          style: const TextStyle(
                                            color: RooteryTheme.subText,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: RooteryTheme.subText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(crop.timeMinutes / 60).toStringAsFixed(1)}h',
                                          style: const TextStyle(
                                            color: RooteryTheme.subText,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow
                              Icon(
                                Icons.arrow_forward_ios,
                                color: RooteryTheme.subText,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  )
                  .toList(),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
      floatingActionButton: _multiSelectMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedCropIndexes.isNotEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                      onPressed: () => setState(() => _selectedCropIndexes.clear()),
                      child: const Text('Clear'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RooteryTheme.accentGreen,
                    ),
                    onPressed: _selectedCropIndexes.isEmpty ? null : _activateSelected,
                    child: Text('Activate (${_selectedCropIndexes.length})'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fruits':
        return Icons.apple;
      case 'Vegetables':
        return Icons.grass;
      case 'Herbs':
        return Icons.local_florist;
      case 'Proteins':
        return Icons.restaurant;
      case 'Grains':
        return Icons.grain;
      default:
        return Icons.category;
    }
  }
}

