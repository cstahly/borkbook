import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal_model.dart';
import 'package:intl/intl.dart'; // For formatting day names

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _currentDay = DateTime.now(); // Track the day being displayed
  bool _isLoading = true;
  String? _errorMessage;

  // Get the list of days in a week for cycling
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      await Provider.of<MealProvider>(context, listen: false).fetchMeals();
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load meals. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to rotate between days of the week (Sunday to Monday and vice versa)
  DateTime _addDays(DateTime date, int daysToAdd) {
    return date.add(Duration(days: daysToAdd));
  }

  String _getDayLabel(DateTime date) {
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime tomorrow = today.add(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(today)) {
      return "Today: ${DateFormat('MM/dd/yy').format(date)}";
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(yesterday)) {
      return "Yesterday: ${DateFormat('MM/dd/yy').format(date)}";
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(tomorrow)) {
      return "Tomorrow: ${DateFormat('MM/dd/yy').format(date)}";
    } else {
      return "${DateFormat('EEEE').format(date)}: ${DateFormat('MM/dd/yy').format(date)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BorkBook'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Consumer<MealProvider>(
                  builder: (context, mealProvider, _) {
                    return PageView.builder(
                      onPageChanged: (index) {
                        setState(() {
                          _currentDay = _addDays(DateTime.now(), index);
                        });
                      },
                      itemBuilder: (context, index) {
                        final dayToShow = _addDays(DateTime.now(), index % 7);
                        final currentDayLabel = _getDayLabel(dayToShow);
                        return _buildDayView(
                            mealProvider, currentDayLabel, dayToShow);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildDayView(
      MealProvider mealProvider, String dayLabel, DateTime currentDay) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMealSection(mealProvider, 'Breakfast', currentDay),
            const Divider(),
            _buildMealSection(mealProvider, 'Lunch', currentDay),
            const Divider(),
            _buildMealSection(mealProvider, 'Dinner', currentDay),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(
      MealProvider mealProvider, String mealType, DateTime currentDay) {
    final currentDayName = DateFormat('EEEE').format(currentDay);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          mealType,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDogCheckbox(
                mealProvider, 'Precious', currentDayName, mealType),
            _buildDogCheckbox(mealProvider, 'Tucker', currentDayName, mealType),
          ],
        ),
      ],
    );
  }

  Widget _buildDogCheckbox(MealProvider mealProvider, String dogName,
      String currentDayName, String mealType) {
    MealModel meal = mealProvider.meals.firstWhere(
      (meal) => meal.dogName == dogName,
      orElse: () => MealModel(
        dogName: dogName,
        days: {}, // Return an empty MealModel if not found
      ),
    );

    bool isChecked =
        meal.days[currentDayName]?[mealType.toLowerCase()] ?? false;

    // Choose the correct image based on the dog name
    String assetPath =
        dogName == 'Precious' ? 'assets/precious.png' : 'assets/tucker.png';

    return GestureDetector(
      onTap: () {
        Provider.of<MealProvider>(context, listen: false).updateMeal(
          dogName,
          currentDayName,
          mealType.toLowerCase(),
          !isChecked,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110, // Increased to accommodate the border
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isChecked
                ? Colors.yellow
                : Colors.grey, // Yellow when checked, gray when unchecked
            width: 4, // Thickness of the border
          ),
          boxShadow: isChecked
              ? [
                  const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 5.0,
                      offset: Offset(0, 3))
                ]
              : null, // Depressed shadow effect when checked
        ),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: isChecked
                ? const ColorFilter.mode(Colors.transparent,
                    BlendMode.multiply) // Normal color when checked
                : const ColorFilter.matrix(<double>[
                    0.33, 0.33, 0.33, 0, 0, // Apply grayscale when unchecked
                    0.33, 0.33, 0.33, 0, 0,
                    0.33, 0.33, 0.33, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover, // Ensures the image fills the circular area
            ),
          ),
        ),
      ),
    );
  }
}
