import 'package:flutter/material.dart';
import '../../theme/rootery_theme.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  bool isAutoMode = true;
  bool isSingleCrop = true;
  String? selectedCrop;
  final TextEditingController cropWeightController = TextEditingController();

  // Multi-crop variables
  final TextEditingController numberOfProductsController =
      TextEditingController();
  List<Map<String, TextEditingController>> multiCropProducts = [];

  void _updateMultiCropCount() {
    final count = int.tryParse(numberOfProductsController.text) ?? 0;
    setState(() {
      if (count > multiCropProducts.length) {
        // Add more products
        for (int i = multiCropProducts.length; i < count; i++) {
          multiCropProducts.add({
            'crop': TextEditingController(),
            'weight': TextEditingController(),
          });
        }
      } else if (count < multiCropProducts.length) {
        // Remove excess products
        for (int i = multiCropProducts.length - 1; i >= count; i--) {
          multiCropProducts[i]['crop']?.dispose();
          multiCropProducts[i]['weight']?.dispose();
          multiCropProducts.removeAt(i);
        }
      }
    });
  }

  // Calculate adjusted drying time based on weight, initial moisture, and target moisture
  Map<String, dynamic> _getAdjustedRecommendations() {
    if (selectedCrop == null || !cropDatabase.containsKey(selectedCrop)) {
      return {};
    }

    final baseData = cropDatabase[selectedCrop]!;
    final weight = double.tryParse(cropWeightController.text) ?? 50.0;
    final initialMoisture =
        double.tryParse(initialMoistureController.text) ??
        baseData['initialMoisture'].toDouble();
    final targetMoisture =
        double.tryParse(targetMoistureController.text) ??
        baseData['targetMoisture'].toDouble();

    // Weight factor: Time increases by ~15% for every 10kg above 50kg, decreases by 10% for every 10kg below
    final weightFactor = weight / 50.0;
    final weightMultiplier =
        0.7 + (weightFactor * 0.3); // Min 0.7x, baseline 1.0x

    // Moisture difference factor: More moisture to remove = longer drying time
    // Calculate moisture removal percentage vs. baseline
    final baseMoistureRemoval =
        baseData['initialMoisture'] - baseData['targetMoisture'];
    final actualMoistureRemoval = initialMoisture - targetMoisture;
    final moistureMultiplier = actualMoistureRemoval / baseMoistureRemoval;

    // Combined time calculation
    final baseMinutes =
        (baseData['estimatedHours'] * 60) + baseData['estimatedMinutes'];
    final adjustedMinutes =
        (baseMinutes * weightMultiplier * moistureMultiplier).round();
    final adjustedHours = adjustedMinutes ~/ 60;
    final adjustedMins = adjustedMinutes % 60;

    // Airflow adjusts with weight (Â±10% max) and moisture content (higher moisture = more airflow)
    final airflowWeightAdjustment = ((weight - 50) / 100).clamp(-0.1, 0.1);
    final airflowMoistureAdjustment =
        ((initialMoisture - baseData['initialMoisture']) / 100).clamp(
          -0.05,
          0.05,
        );
    final adjustedAirflow =
        (baseData['airflow'] *
                (1 + airflowWeightAdjustment + airflowMoistureAdjustment))
            .round();

    // Temperature may increase slightly for higher moisture content (up to +3Â°C)
    final tempAdjustment =
        ((initialMoisture - baseData['initialMoisture']) / 20)
            .clamp(0, 3)
            .round();
    final adjustedTemp = baseData['temp'] + tempAdjustment;

    return {
      'temp': adjustedTemp,
      'airflow': adjustedAirflow,
      'hours': adjustedHours,
      'minutes': adjustedMins,
      'weight': weight,
      'initialMoisture': initialMoisture,
      'targetMoisture': targetMoisture,
    };
  }

  // Check compatibility of selected crops for multi-crop drying
  Map<String, dynamic> _analyzeMultiCropCompatibility() {
    if (multiCropProducts.isEmpty) {
      return {'compatible': true, 'message': '', 'suggestions': []};
    }

    List<String> selectedCrops = [];
    for (var product in multiCropProducts) {
      final cropName = product['crop']?.text;
      if (cropName != null &&
          cropName.isNotEmpty &&
          cropDatabase.containsKey(cropName)) {
        selectedCrops.add(cropName);
      }
    }

    if (selectedCrops.isEmpty) {
      return {'compatible': true, 'message': '', 'suggestions': []};
    }

    // Get temperature and drying time ranges
    int minTemp = 999, maxTemp = 0;
    int minTime = 999, maxTime = 0;
    double minMoisture = 999, maxMoisture = 0;
    List<String> categories = [];

    for (var crop in selectedCrops) {
      final data = cropDatabase[crop]!;
      final temp = data['temp'] as int;
      final time = (data['estimatedHours'] * 60) + data['estimatedMinutes'];
      final moisture = data['targetMoisture'] as int;

      minTemp = temp < minTemp ? temp : minTemp;
      maxTemp = temp > maxTemp ? temp : maxTemp;
      minTime = time < minTime ? time : minTime;
      maxTime = time > maxTime ? time : maxTime;
      minMoisture = moisture < minMoisture ? moisture.toDouble() : minMoisture;
      maxMoisture = moisture > maxMoisture ? moisture.toDouble() : maxMoisture;

      if (!categories.contains(data['category'])) {
        categories.add(data['category']);
      }
    }

    // Compatibility rules
    final tempDiff = maxTemp - minTemp;
    final timeDiff = maxTime - minTime;
    final moistureDiff = maxMoisture - minMoisture;

    bool compatible = true;
    String message = '';
    List<String> suggestions = [];

    // Check temperature compatibility (should be within 8Â°C)
    if (tempDiff > 8) {
      compatible = false;
      message =
          'âš ï¸ Temperature range too wide (${tempDiff}Â°C difference). May result in uneven drying.';
      suggestions.add('Consider grouping crops with similar temperatures');
      suggestions.add(
        'Remove: ${selectedCrops.where((c) => cropDatabase[c]!['temp'] == maxTemp || cropDatabase[c]!['temp'] == minTemp).join(", ")}',
      );
    }
    // Check drying time compatibility (should be within 3 hours)
    else if (timeDiff > 180) {
      compatible = false;
      message =
          'âš ï¸ Drying times vary significantly (${(timeDiff / 60).toStringAsFixed(1)}h difference). Some items may over-dry.';
      suggestions.add('Group crops with similar drying times');
    }
    // Check moisture compatibility
    else if (moistureDiff > 8) {
      compatible = false;
      message =
          'âš ï¸ Target moisture levels differ significantly (${moistureDiff.toStringAsFixed(1)}% difference).';
      suggestions.add('Separate items with very different moisture targets');
    }
    // Good compatibility
    else {
      message =
          'âœ… Crops are compatible for multi-drying! Estimated time: ${(maxTime / 60).toStringAsFixed(1)}h at ${((minTemp + maxTemp) / 2).round()}Â°C';
      suggestions.add(
        'Recommended settings: ${((minTemp + maxTemp) / 2).round()}Â°C, ${((minTime + maxTime) / 2 / 60).toStringAsFixed(1)}h',
      );

      // Suggest additional compatible crops
      List<String> compatibleAdditions = [];
      for (var crop in cropDatabase.keys) {
        if (!selectedCrops.contains(crop)) {
          final data = cropDatabase[crop]!;
          final temp = data['temp'] as int;
          final time = (data['estimatedHours'] * 60) + data['estimatedMinutes'];

          if ((temp - minTemp).abs() <= 5 &&
              (temp - maxTemp).abs() <= 5 &&
              (time - minTime).abs() <= 120 &&
              (time - maxTime).abs() <= 120) {
            compatibleAdditions.add(crop);
            if (compatibleAdditions.length >= 3) break;
          }
        }
      }

      if (compatibleAdditions.isNotEmpty) {
        suggestions.add('You can also add: ${compatibleAdditions.join(", ")}');
      }
    }

    return {
      'compatible': compatible,
      'message': message,
      'suggestions': suggestions,
      'avgTemp': ((minTemp + maxTemp) / 2).round(),
      'avgTime': ((minTime + maxTime) / 2 / 60).toStringAsFixed(1),
    };
  }

  // Get smart suggestions for multi-crop combinations
  List<Map<String, dynamic>> _getMultiCropSuggestions() {
    return [
      {
        'name': 'ðŸŽ Tropical Fruits Mix',
        'crops': ['Mangoes', 'Bananas', 'Pineapple', 'Papaya'],
        'description': '4 tropical fruits with similar drying profiles',
      },
      {
        'name': 'ðŸ¥— Salad Vegetables',
        'crops': ['Tomatoes', 'Bell Peppers', 'Carrots', 'Onions'],
        'description': 'Common vegetables for dried salad mixes',
      },
      {
        'name': 'ðŸ“ Berry Blend',
        'crops': ['Strawberries', 'Blueberries', 'Grapes'],
        'description': 'Sweet berries perfect for snacking',
      },
      {
        'name': 'ðŸŒ¿ Herb Garden',
        'crops': ['Basil', 'Oregano', 'Mint'],
        'description': 'Popular herbs for cooking',
      },
      {
        'name': 'ðŸŽ Apple & Grapes',
        'crops': ['Apples', 'Grapes'],
        'description': 'Two fruits with compatible settings',
      },
      {
        'name': 'ðŸ¥¬ Leafy Greens',
        'crops': ['Spinach', 'Kale', 'Basil'],
        'description': 'Nutrient-rich greens',
      },
    ];
  }

  void _applyMultiCropSuggestion(Map<String, dynamic> suggestion) {
    final crops = suggestion['crops'] as List<String>;
    numberOfProductsController.text = crops.length.toString();
    _updateMultiCropCount();

    setState(() {
      for (int i = 0; i < crops.length && i < multiCropProducts.length; i++) {
        multiCropProducts[i]['crop']?.text = crops[i];
        multiCropProducts[i]['weight']?.text = '50'; // Default weight
      }
    });
  }

  // Crop database with AI recommendations
  final Map<String, Map<String, dynamic>> cropDatabase = {
    'Mangoes': {
      'temp': 65,
      'airflow': 150,
      'targetMoisture': 12,
      'estimatedHours': 10,
      'estimatedMinutes': 0,
      'initialMoisture': 85,
      'category': 'Fruits',
    },
    'Tomatoes': {
      'temp': 60,
      'airflow': 120,
      'targetMoisture': 15,
      'estimatedHours': 8,
      'estimatedMinutes': 30,
      'initialMoisture': 90,
      'category': 'Vegetables',
    },
    'Bananas': {
      'temp': 55,
      'airflow': 140,
      'targetMoisture': 10,
      'estimatedHours': 9,
      'estimatedMinutes': 45,
      'initialMoisture': 75,
      'category': 'Fruits',
    },
    'Apples': {
      'temp': 63,
      'airflow': 145,
      'targetMoisture': 10,
      'estimatedHours': 11,
      'estimatedMinutes': 30,
      'initialMoisture': 84,
      'category': 'Fruits',
    },
    'Bell Peppers': {
      'temp': 58,
      'airflow': 130,
      'targetMoisture': 8,
      'estimatedHours': 7,
      'estimatedMinutes': 0,
      'initialMoisture': 92,
      'category': 'Vegetables',
    },
    'Carrots': {
      'temp': 62,
      'airflow': 135,
      'targetMoisture': 12,
      'estimatedHours': 9,
      'estimatedMinutes': 0,
      'initialMoisture': 88,
      'category': 'Vegetables',
    },
    'Pineapple': {
      'temp': 68,
      'airflow': 155,
      'targetMoisture': 15,
      'estimatedHours': 12,
      'estimatedMinutes': 0,
      'initialMoisture': 86,
      'category': 'Fruits',
    },
    'Onions': {
      'temp': 57,
      'airflow': 125,
      'targetMoisture': 10,
      'estimatedHours': 8,
      'estimatedMinutes': 0,
      'initialMoisture': 89,
      'category': 'Vegetables',
    },
    'Strawberries': {
      'temp': 54,
      'airflow': 135,
      'targetMoisture': 8,
      'estimatedHours': 10,
      'estimatedMinutes': 30,
      'initialMoisture': 90,
      'category': 'Berries',
    },
    'Blueberries': {
      'temp': 52,
      'airflow': 130,
      'targetMoisture': 10,
      'estimatedHours': 11,
      'estimatedMinutes': 0,
      'initialMoisture': 85,
      'category': 'Berries',
    },
    'Basil': {
      'temp': 45,
      'airflow': 110,
      'targetMoisture': 8,
      'estimatedHours': 4,
      'estimatedMinutes': 30,
      'initialMoisture': 92,
      'category': 'Herbs',
    },
    'Oregano': {
      'temp': 42,
      'airflow': 105,
      'targetMoisture': 10,
      'estimatedHours': 5,
      'estimatedMinutes': 0,
      'initialMoisture': 88,
      'category': 'Herbs',
    },
    'Mint': {
      'temp': 43,
      'airflow': 108,
      'targetMoisture': 9,
      'estimatedHours': 4,
      'estimatedMinutes': 45,
      'initialMoisture': 90,
      'category': 'Herbs',
    },
    'Mushrooms': {
      'temp': 50,
      'airflow': 115,
      'targetMoisture': 12,
      'estimatedHours': 6,
      'estimatedMinutes': 30,
      'initialMoisture': 92,
      'category': 'Vegetables',
    },
    'Grapes': {
      'temp': 60,
      'airflow': 140,
      'targetMoisture': 15,
      'estimatedHours': 18,
      'estimatedMinutes': 0,
      'initialMoisture': 81,
      'category': 'Fruits',
    },
    'Papaya': {
      'temp': 62,
      'airflow': 148,
      'targetMoisture': 12,
      'estimatedHours': 11,
      'estimatedMinutes': 30,
      'initialMoisture': 88,
      'category': 'Fruits',
    },
    'Green Beans': {
      'temp': 58,
      'airflow': 128,
      'targetMoisture': 10,
      'estimatedHours': 7,
      'estimatedMinutes': 30,
      'initialMoisture': 90,
      'category': 'Vegetables',
    },
    'Spinach': {
      'temp': 48,
      'airflow': 112,
      'targetMoisture': 8,
      'estimatedHours': 5,
      'estimatedMinutes': 30,
      'initialMoisture': 91,
      'category': 'Vegetables',
    },
    'Kale': {
      'temp': 50,
      'airflow': 115,
      'targetMoisture': 9,
      'estimatedHours': 6,
      'estimatedMinutes': 0,
      'initialMoisture': 89,
      'category': 'Vegetables',
    },
  };
  final TextEditingController initialMoistureController = TextEditingController(
    text: '85',
  );
  final TextEditingController targetMoistureController = TextEditingController(
    text: '15',
  );

  // Manual mode variables
  final TextEditingController temperatureController = TextEditingController(
    text: '65',
  );
  final TextEditingController airflowController = TextEditingController(
    text: '150',
  );
  final TextEditingController moistureTargetController = TextEditingController(
    text: '15',
  );
  final TextEditingController hoursController = TextEditingController(
    text: '8',
  );
  final TextEditingController minutesController = TextEditingController(
    text: '30',
  );
  final TextEditingController secondsController = TextEditingController(
    text: '0',
  );

  // Sample presets
  final List<Map<String, dynamic>> samplePresets = [
    {
      'name': 'Mangoes',
      'icon': 'ðŸ¥­',
      'temp': '65',
      'airflow': '150',
      'moisture': '12',
      'hours': '10',
      'minutes': '0',
    },
    {
      'name': 'Tomatoes',
      'icon': 'ðŸ…',
      'temp': '60',
      'airflow': '120',
      'moisture': '15',
      'hours': '8',
      'minutes': '30',
    },
    {
      'name': 'Bananas',
      'icon': 'ðŸŒ',
      'temp': '55',
      'airflow': '140',
      'moisture': '10',
      'hours': '9',
      'minutes': '45',
    },
    {
      'name': 'Apples',
      'icon': 'ðŸŽ',
      'temp': '63',
      'airflow': '145',
      'moisture': '10',
      'hours': '11',
      'minutes': '30',
    },
    {
      'name': 'Bell Peppers',
      'icon': 'ðŸ«‘',
      'temp': '58',
      'airflow': '130',
      'moisture': '8',
      'hours': '7',
      'minutes': '0',
    },
    {
      'name': 'Carrots',
      'icon': 'ðŸ¥•',
      'temp': '62',
      'airflow': '135',
      'moisture': '12',
      'hours': '9',
      'minutes': '0',
    },
    {
      'name': 'Strawberries',
      'icon': 'ðŸ“',
      'temp': '57',
      'airflow': '160',
      'moisture': '8',
      'hours': '8',
      'minutes': '0',
    },
    {
      'name': 'Basil',
      'icon': 'ðŸŒ¿',
      'temp': '38',
      'airflow': '110',
      'moisture': '10',
      'hours': '4',
      'minutes': '0',
    },
    {
      'name': 'Mushrooms',
      'icon': 'ðŸ„',
      'temp': '52',
      'airflow': '125',
      'moisture': '12',
      'hours': '6',
      'minutes': '30',
    },
  ];

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      temperatureController.text = preset['temp'];
      airflowController.text = preset['airflow'];
      moistureTargetController.text = preset['moisture'];
      hoursController.text = preset['hours'];
      minutesController.text = preset['minutes'];
      secondsController.text = '0';
    });
  }

  @override
  void dispose() {
    cropWeightController.dispose();
    numberOfProductsController.dispose();
    for (var product in multiCropProducts) {
      product['crop']?.dispose();
      product['weight']?.dispose();
    }
    temperatureController.dispose();
    airflowController.dispose();
    moistureTargetController.dispose();
    hoursController.dispose();
    minutesController.dispose();
    secondsController.dispose();
    initialMoistureController.dispose();
    targetMoistureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: RooteryTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Control Panel'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Toggle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isAutoMode = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAutoMode
                            ? RooteryTheme.accentGreen
                            : Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isAutoMode
                                ? RooteryTheme.accentGreen
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      child: const Text('Auto Mode'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isAutoMode = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isAutoMode
                            ? RooteryTheme.accentGreen
                            : Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: !isAutoMode
                                ? RooteryTheme.accentGreen
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      child: const Text('Manual Mode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Conditional rendering based on mode
              if (isAutoMode)
                ..._buildAutoModeContent()
              else
                ..._buildManualModeContent(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAutoModeContent() {
    return [
      // Auto Mode Setup Title
      const Text(
        'Auto Mode Setup',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Enter your crop details to get an AI-powered drying plan.',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 32),

      // Select Drying Mode
      const Text(
        'Select Drying Mode',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => isSingleCrop = true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isSingleCrop
                      ? RooteryTheme.accentGreen
                      : Colors.grey.shade700,
                  width: 2,
                ),
                backgroundColor: isSingleCrop
                    ? RooteryTheme.accentGreen.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: const Text(
                'Single Crop Drying',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => isSingleCrop = false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: !isSingleCrop
                      ? RooteryTheme.accentGreen
                      : Colors.grey.shade700,
                  width: 2,
                ),
                backgroundColor: !isSingleCrop
                    ? RooteryTheme.accentGreen.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: const Text(
                'Multi-Crop Drying',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),

      // Quick Presets (show for both single and multi-crop)
      const Text(
        'Quick Start Presets',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Text(
        'Tap a preset to auto-fill settings for popular crops',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      ),
      const SizedBox(height: 12),
      Container(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: samplePresets.length,
          itemBuilder: (context, index) {
            final preset = samplePresets[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  if (isSingleCrop) {
                    // For single crop, set the dropdown to this crop
                    setState(() {
                      selectedCrop = preset['name'];
                      if (cropDatabase.containsKey(selectedCrop)) {
                        final data = cropDatabase[selectedCrop]!;
                        initialMoistureController.text = data['initialMoisture']
                            .toString();
                        targetMoistureController.text = data['targetMoisture']
                            .toString();
                      }
                    });
                  } else {
                    // For multi-crop, can be used in manual mode
                    _applyPreset(preset);
                  }
                },
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: RooteryTheme.accentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        preset['icon'] ?? 'ðŸŒ±',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${preset['temp']}Â°C',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
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
      const SizedBox(height: 24),

      // Multi-Crop Configuration (only show if multi-crop mode)
      if (!isSingleCrop) ...[
        // AI Suggestions Dropdown
        const Text(
          'AI Suggested Combinations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber.shade300, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Quick Start with Pre-configured Mixes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                hint: const Text('Select a suggested combination...'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                ),
                dropdownColor: RooteryTheme.card,
                items: _getMultiCropSuggestions().asMap().entries.map((entry) {
                  final index = entry.key;
                  final suggestion = entry.value;
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suggestion['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          suggestion['description'],
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (int? index) {
                  if (index != null) {
                    _applyMultiCropSuggestion(
                      _getMultiCropSuggestions()[index],
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Number of Products',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: numberOfProductsController,
          keyboardType: TextInputType.number,
          onChanged: (value) => _updateMultiCropCount(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            hintText: 'Enter number of products (e.g., 3)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RooteryTheme.accentGreen,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic product fields
        if (multiCropProducts.isNotEmpty) ...[
          const Text(
            'Product Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ...multiCropProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product ${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: RooteryTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      hint: const Text('Select crop type'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black38,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                      ),
                      dropdownColor: RooteryTheme.card,
                      items: cropDatabase.keys.map((String crop) {
                        return DropdownMenuItem<String>(
                          value: crop,
                          child: Text(
                            crop,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          product['crop']?.text = value;
                          setState(() {}); // Trigger compatibility check
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: product['weight'],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black38,
                        hintText: 'Weight (kg)',
                        prefixIcon: const Icon(Icons.monitor_weight, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),

          // Compatibility Analysis
          () {
            final analysis = _analyzeMultiCropCompatibility();
            if (analysis['message'].toString().isEmpty) {
              return const SizedBox.shrink();
            }

            final isCompatible = analysis['compatible'] as bool;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompatible
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompatible
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompatible ? Icons.check_circle : Icons.warning,
                        color: isCompatible
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Compatibility Analysis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis['message'],
                    style: TextStyle(
                      color: isCompatible
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                      fontSize: 13,
                    ),
                  ),
                  if ((analysis['suggestions'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Suggestions:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...(analysis['suggestions'] as List).map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'â€¢ ',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }(),
          const SizedBox(height: 24),
        ],
      ],

      // Select Crop Type (only show for single crop)
      if (isSingleCrop) ...[
        const Text(
          'Select Crop Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedCrop,
          hint: const Text('Search or select a crop...'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RooteryTheme.accentGreen,
                width: 2,
              ),
            ),
          ),
          dropdownColor: RooteryTheme.card,
          items: cropDatabase.keys.map((String crop) {
            final data = cropDatabase[crop]!;
            return DropdownMenuItem<String>(
              value: crop,
              child: Row(
                children: [
                  Icon(
                    data['category'] == 'Fruits'
                        ? Icons.apple
                        : data['category'] == 'Herbs'
                        ? Icons.spa
                        : data['category'] == 'Berries'
                        ? Icons.local_florist
                        : Icons.eco,
                    color: data['category'] == 'Fruits'
                        ? Colors.red
                        : data['category'] == 'Herbs'
                        ? Colors.purple
                        : data['category'] == 'Berries'
                        ? Colors.pink
                        : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(crop, style: const TextStyle(color: Colors.white)),
                      Text(
                        data['category'],
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedCrop = newValue;
              if (selectedCrop != null &&
                  cropDatabase.containsKey(selectedCrop)) {
                final data = cropDatabase[selectedCrop]!;
                initialMoistureController.text = data['initialMoisture']
                    .toString();
                targetMoistureController.text = data['targetMoisture']
                    .toString();
              }
            });
          },
        ),
        const SizedBox(height: 24),

        // Enter Total Crop Weight
        const Text(
          'Enter Total Crop Weight (kg)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: cropWeightController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {}); // Trigger recalculation
          },
          decoration: InputDecoration(
            hintText: 'e.g., 50',
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RooteryTheme.accentGreen,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Moisture Inputs
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Avg. Initial Moisture (%)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: initialMoistureController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Avg. Target Moisture (%)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: targetMoistureController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],

      // AI Recommended Settings (show for single crop with selected crop)
      if (isSingleCrop && selectedCrop != null) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.stars, color: Color(0xFFFFD700)),
                  SizedBox(width: 8),
                  Text(
                    'AI Recommended Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (selectedCrop != null &&
                  cropDatabase.containsKey(selectedCrop)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRecommendationCard(
                      icon: Icons.thermostat,
                      value:
                          '${_getAdjustedRecommendations()['temp'] ?? cropDatabase[selectedCrop]!['temp']}Â°C',
                      label: 'Temperature',
                      color: Colors.orange,
                    ),
                    _buildRecommendationCard(
                      icon: Icons.air,
                      value:
                          '${_getAdjustedRecommendations()['airflow'] ?? cropDatabase[selectedCrop]!['airflow']} mÂ³/h',
                      label: 'Airflow',
                      color: Colors.cyan,
                    ),
                    _buildRecommendationCard(
                      icon: Icons.timer,
                      value:
                          '${_getAdjustedRecommendations()['hours'] ?? cropDatabase[selectedCrop]!['estimatedHours']}h ${_getAdjustedRecommendations()['minutes'] ?? cropDatabase[selectedCrop]!['estimatedMinutes']}m',
                      label: 'Est. Time',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade300,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cropWeightController.text.isNotEmpty
                              ? 'Settings adjusted for ${_getAdjustedRecommendations()['weight']?.toStringAsFixed(1) ?? '50.0'} kg, '
                                    '${_getAdjustedRecommendations()['initialMoisture']?.toStringAsFixed(1) ?? ''}% â†’ '
                                    '${_getAdjustedRecommendations()['targetMoisture']?.toStringAsFixed(1) ?? ''}% moisture'
                              : 'Enter weight and moisture levels for customized recommendations',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a crop to see AI recommendations',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Drying Profile Curve',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(painter: CurvePainter(), child: Container()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Start Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Auto drying cycle started!'),
                  backgroundColor: RooteryTheme.accentGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RooteryTheme.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Auto Cycle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],

      // Start button for multi-crop mode
      if (!isSingleCrop) ...[
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (multiCropProducts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please add products first'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Multi-crop drying started with ${multiCropProducts.length} products!',
                  ),
                  backgroundColor: RooteryTheme.accentGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RooteryTheme.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Multi-Crop Drying',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildManualModeContent() {
    return [
      // Status Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Status: ',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Idle',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Sample Presets
      const Text(
        'Quick Presets',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: samplePresets.map((preset) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: () => _applyPreset(preset),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  side: BorderSide(color: RooteryTheme.accentGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      preset['icon'] ?? 'ðŸŒ±',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${preset['temp']}Â°C Â· ${preset['airflow']} mÂ³/h',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 24),

      // Temperature Input
      _buildInputCard(
        label: 'Set Temperature (Â°C)',
        controller: temperatureController,
        hint: 'e.g., 65',
        unit: 'Â°C',
      ),
      const SizedBox(height: 24),

      // Airflow Input
      _buildInputCard(
        label: 'Set Airflow (mÂ³/h)',
        controller: airflowController,
        hint: 'e.g., 150',
        unit: 'mÂ³/h',
      ),
      const SizedBox(height: 24),

      // Set Duration
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTimeInputField('Hours', hoursController)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeInputField('Minutes', minutesController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeInputField('Seconds', secondsController),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Final Moisture Target
      _buildInputCard(
        label: 'Final Moisture Target (%)',
        controller: moistureTargetController,
        hint: 'e.g., 15',
        unit: '%',
      ),
      const SizedBox(height: 24),

      // Live Data
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Current Temp.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '-- Â°C',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Current Humidity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '-- %',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),

      // Start Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Manual dehydration started!'),
                backgroundColor: RooteryTheme.accentGreen,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: RooteryTheme.accentGreen,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.play_arrow, size: 28),
              SizedBox(width: 8),
              Text(
                'Start Dehydration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              suffixText: unit,
              suffixStyle: TextStyle(
                fontSize: 18,
                color: RooteryTheme.accentGreen,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: RooteryTheme.accentGreen,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RooteryTheme.accentGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 8,
            ),
          ),
        ),
      ],
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RooteryTheme.accentGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4,
      size.width * 0.9,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.9),
      axisPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.1, size.height * 0.9),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

