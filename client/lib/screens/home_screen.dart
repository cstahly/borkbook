import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // The current day selected (e.g., 0 for Monday, 1 for Tuesday, etc.)
  int _currentDayIndex = DateTime.now().weekday % 7;

  // Week days labels
  final List<String> _weekDays = ['M', 'T', 'W', 'Th', 'F', 'S', 'Su'];
  final List<String> _fullWeekDays = [
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
    // Automatically refresh meals on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMeals();
    });
  }

  Future<void> _refreshMeals() async {
    try {
      await Provider.of<MealProvider>(context, listen: false).fetchMeals();
    } catch (error) {
      print('Error refreshing meals: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BorkBook'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMeals,
        child: Column(
          children: [
            Spacer(flex: 1),
            // Week bar to display days of the week
            _buildWeekBar(),
            // Expanded widget containing a SingleChildScrollView
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      kToolbarHeight, // Adjust height
                  child: PageView.builder(
                    controller: PageController(initialPage: _currentDayIndex),
                    onPageChanged: (index) {
                      setState(() {
                        _currentDayIndex = index;
                      });
                    },
                    itemCount: 7, // 7 days in a week
                    itemBuilder: (context, index) {
                      return _buildMealsForDay(context, index);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper function to build the week bar
  Widget _buildWeekBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_weekDays.length, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentDayIndex = index;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              decoration: BoxDecoration(
                color: _currentDayIndex == index
                    ? Colors.brown[200]
                    : Colors.grey[300], // Tan for selected, gray for unselected
                borderRadius: BorderRadius.circular(12),
                boxShadow: _currentDayIndex == index
                    ? [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 00),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _weekDays[index],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _currentDayIndex == index
                      ? Colors.brown[800]
                      : Colors.black, // Darker brown for active day
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

// Helper function to display meals for a given day
  Widget _buildMealsForDay(BuildContext context, int dayIndex) {
    return Consumer<MealProvider>(
      builder: (context, mealProvider, _) {
        if (mealProvider.isLoading && mealProvider.meals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mealProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/tucker.png', width: 100, height: 100),
                const SizedBox(height: 20),
                Text(
                  mealProvider.error ?? 'An error occurred',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                const Text('Communication error, drag down to retry'),
              ],
            ),
          );
        }

        if (mealProvider.meals.isEmpty) {
          return const Center(
            child: Text('No meals available, drag down to refresh'),
          );
        }

        // Get meals for the current day
        String currentDay = _fullWeekDays[dayIndex];
        Map<String, Map<String, bool>> mealsForDay = {};

        // Look for meals for this specific day in the data
        for (var meal in mealProvider.meals) {
          mealsForDay[meal.dogName] = meal.days[currentDay] ?? {};
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: ['Breakfast', 'Lunch', 'Dinner'].map((mealType) {
            final dogsFed = {
              'Precious': mealsForDay['Precious']?[mealType] ?? false,
              'Tucker': mealsForDay['Tucker']?[mealType] ?? false,
            };

            final preciousFed = dogsFed['Precious'] ?? false;
            final tuckerFed = dogsFed['Tucker'] ?? false;

            return Padding(
              padding: const EdgeInsets.only(
                  bottom: 40.0), // Adds spacing between items
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Light gray/tan background color
                  borderRadius: BorderRadius.circular(15), // Curved corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), // Soft shadow
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  title: Center(
                    child: Text(
                      mealType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDogIcon(
                        'Precious',
                        preciousFed,
                        () {
                          mealProvider.updateMeal(
                              'Precious', currentDay, mealType, !preciousFed);
                        },
                      ),
                      _buildDogIcon(
                        'Tucker',
                        tuckerFed,
                        () {
                          mealProvider.updateMeal(
                              'Tucker', currentDay, mealType, !tuckerFed);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Helper function to build the dog icon with gradient and shading
  Widget _buildDogIcon(String dogName, bool isFed, VoidCallback onTap) {
    String assetPath = dogName == 'Precious'
        ? 'assets/precious.png'
        : 'assets/tucker.png'; // Choose the correct image

    return GestureDetector(
      onTap: onTap, // Make the icon clickable
      child: Container(
        width: 80, // Set the width of the circle
        height: 80, // Set the height of the circle
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isFed
                ? Colors.green
                : Colors.red, // Border color based on state
            width: 3, // Border thickness
          ),
          gradient: isFed
              ? const RadialGradient(
                  colors: [Colors.yellowAccent, Colors.orangeAccent],
                  center: Alignment(-0.5, -0.6),
                  radius: 0.6,
                )
              : const RadialGradient(
                  colors: [Colors.grey, Colors.white],
                  center: Alignment(-0.5, -0.6),
                  radius: 0.6,
                ),
          boxShadow: isFed
              ? [
                  const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 5.0,
                      offset: Offset(0, 3))
                ]
              : null, // Depressed shadow effect when checked
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
