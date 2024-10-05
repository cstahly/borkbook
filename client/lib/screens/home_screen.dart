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
  final List<String> _daysOfWeek = ['M', 'T', 'W', 'Th', 'F', 'S', 'S'];
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeals();

    // Set the initial page to today's index (Monday = 0, Sunday = 6)
    _currentPageIndex = DateTime.now().weekday - 1; // Monday = 0, Sunday = 6
    _pageController = PageController(initialPage: _currentPageIndex);
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

  // Helper to get the week starting on Monday for the current date
  DateTime _getMonday(DateTime currentDate) {
    int daysToSubtract =
        currentDate.weekday - 1; // Monday is 1, so subtract to get Monday
    return currentDate.subtract(Duration(days: daysToSubtract));
  }

  // Helper to get the formatted date label (e.g., Monday: 09/30/24)
  String _getDayLabel(DateTime currentDay) {
    return "${DateFormat('EEEE').format(currentDay)}: ${DateFormat('MM/dd/yy').format(currentDay)}";
  }

  @override
  Widget build(BuildContext context) {
    DateTime monday = _getMonday(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borkbook'),
      ),
      body: Column(
        children: [
          _buildWeekBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : Consumer<MealProvider>(
                        builder: (context, mealProvider, _) {
                          return PageView.builder(
                            controller: _pageController,
                            itemCount: _daysOfWeek.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              DateTime dayToShow =
                                  monday.add(Duration(days: index));
                              final currentDayLabel = _getDayLabel(dayToShow);
                              return _buildDayView(
                                  mealProvider, currentDayLabel, dayToShow);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_daysOfWeek.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentPageIndex = index;
              _pageController.jumpToPage(index);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color:
                  _currentPageIndex == index ? Colors.blue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              _daysOfWeek[index],
              style: TextStyle(
                color: _currentPageIndex == index ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
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
                    offset: Offset(0, 3),
                  ),
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
