import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController; // Use a nullable type
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
    // Initialize the TabController in initState
    _tabController = TabController(length: _weekDays.length, vsync: this);
    _tabController!.index = _currentDayIndex; // Set the initial day index

    _tabController!.addListener(() {
      setState(() {
        _currentDayIndex = _tabController!.index;
      });
    });

    // Automatically refresh meals on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMeals();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
    if (_tabController == null) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), // Show loading indicator while TabController is being initialized
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BorkBook'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue, // Default indicator color
          labelColor: const Color.fromARGB(255, 0, 0, 0), // Active tab color
          unselectedLabelColor:
              const Color.fromARGB(153, 101, 101, 101), // Inactive tab color
          tabs: List.generate(_weekDays.length, (index) {
            return Tab(
              text: _weekDays[index],
            );
          }),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMeals,
        child: Column(
          children: [
            // Expanded widget containing the TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(7, (index) {
                  return _buildMealsForDay(context, index);
                }),
              ),
            ),
          ],
        ),
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
