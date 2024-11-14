import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentDayIndex = (DateTime.now().weekday - 1 % 7);

  // Weekdays labels
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

  // Define the color palette
  final Color _backgroundColor =
      const Color(0xFFFAF9F6); // Off-white/light gray
  final Color _appBarColor = const Color(0xFF5D4037); // Brown
  final Color _tabBarColor = const Color(0xFF8D6E63); // Lighter brown
  final Color _accentColor = const Color.fromARGB(255, 116, 49, 47); // Fuchsia
  final Color _activeTabTextColor = Colors.white;
  final Color _inactiveTabTextColor = Colors.white70;
  final Color _cardColor = const Color(0xFFEEEEEE); // Light gray for cards
  final Color _textColor = const Color(0xFF3E2723); // Dark brown for text

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: _weekDays.length, vsync: this);
    _tabController.index = _currentDayIndex;

    _tabController.addListener(() {
      setState(() {
        _refreshMeals();
        _currentDayIndex = _tabController.index;
      });
    });

    // Automatically refresh meals on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMeals();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  // Refresh meals when the app is resumed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMeals();
    }
  }

  Future<void> _refreshMeals() async {
    try {
      await Provider.of<MealProvider>(context, listen: false).fetchMeals();
    } catch (error) {
      print('Error refreshing meals: $error');
      // Error handling is managed in the UI
    }
  }

  Future<bool> showAlertDialog(BuildContext context, String message) async {
    // Set up the buttons
    Widget cancelButton = ElevatedButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );
    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
        Provider.of<MealProvider>(context, listen: false).resetWeek();
        Navigator.of(context).pop(true);
      },
    );
    // Set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Do you want to continue?"),
      content: Text(message),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // Show the dialog
    final result = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
    return result ?? false;
  }

  Future<void> sendNotification() async {
    String? token = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse('https://freepuppyservices.com:4444/send-notification'),
      headers: {
        'Content-Type': 'application/json',
        'Sender-Token': token ?? '',
      },
      body: jsonEncode({'message': 'Have the dogs been fed?'}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send notification')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Set the background color
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Redesigned Drawer Header
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _appBarColor,
                image: DecorationImage(
                  image:
                      const AssetImage('assets/drawer_header_background.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    _appBarColor.withOpacity(0.6),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'BorkBook',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 1.0,
                        color: Colors.black45,
                        offset: Offset(3.0, 3.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.pets, color: _cardColor),
              title: InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await sendNotification();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Have the dogs been fed?",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                      color: _cardColor,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: _accentColor),
              title: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  showAlertDialog(
                      context, "Reset the current week of dog meals");
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Reset week",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                      color: _accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Container(
          height: 150,
          decoration: BoxDecoration(
            color: _appBarColor,
            image: DecorationImage(
              image: const AssetImage('assets/sad_dog.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                _appBarColor.withOpacity(0.6),
                BlendMode.dstATop,
              ),
            ),
          ),
          child: const Center(
            child: Text(
              'BorkBook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 1.0,
                    color: Colors.black45,
                    offset: Offset(3.0, 3.0),
                  ),
                ],
              ),
            ),
          ),
        ),
        //),
        centerTitle: true,
        backgroundColor: _appBarColor, // Brown AppBar
        leading: Builder(builder: (BuildContext context) {
          return IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              });
        }),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: _tabBarColor, // Lighter brown for TabBar background
            child: TabBar(
              controller: _tabController,
              indicatorColor: _accentColor,
              labelColor: _activeTabTextColor,
              unselectedLabelColor: _inactiveTabTextColor,
              tabs: List.generate(_weekDays.length, (index) {
                bool isToday = index == (DateTime.now().weekday - 1 % 7);
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekDays[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          return _buildMealsForDay(context, index);
        }),
      ),
    );
  }

  // Helper function to display meals for a given day
  Widget _buildMealsForDay(BuildContext context, int dayIndex) {
    return Consumer<MealProvider>(
      builder: (context, mealProvider, _) {
        if (mealProvider.error != null) {
          return Center(
            child: GestureDetector(
              onTap: () {
                _refreshMeals();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/sad_dog.png', width: 100, height: 100),
                  const SizedBox(height: 20),
                  Text(
                    mealProvider.error ?? 'An error occurred',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  const Text('Tap the dog to retry'),
                ],
              ),
            ),
          );
        }

        if (mealProvider.meals.isEmpty) {
          return const Center(
            child: Text('No meals available'),
          );
        }

        // Get meals for the current day
        String currentDay = _fullWeekDays[dayIndex];
        Map<String, Map<String, bool>> mealsForDay = {};

        // Extract meals for this specific day
        for (var meal in mealProvider.meals) {
          mealsForDay[meal.dogName] = meal.days[currentDay] ?? {};
        }

        // return Container(
        //   color: _backgroundColor,
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background_image.png'),
              fit: BoxFit
                  .cover, // Scales to fit the ListView but may overflow to avoid shrinking
              alignment:
                  Alignment.center, // Centers the image in case of overflow
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: ['Breakfast', 'Lunch', 'Dinner'].map((mealType) {
              final dogsFed = {
                'Precious': mealsForDay['Precious']?[mealType] ?? false,
                'Tucker': mealsForDay['Tucker']?[mealType] ?? false,
              };

              final preciousFed = dogsFed['Precious'] ?? false;
              final tuckerFed = dogsFed['Tucker'] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardColor, // Light gray for cards
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5), // Soft shadow
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                    title: Center(
                      child: Text(
                        mealType,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _textColor, // Dark brown for text
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
          ),
        );
      },
    );
  }

  // Helper function to build the dog icon with gradient and shading
  Widget _buildDogIcon(String dogName, bool isFed, VoidCallback onTap) {
    String assetPath =
        dogName == 'Precious' ? 'assets/precious.png' : 'assets/tucker.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        foregroundDecoration: BoxDecoration(
          color: isFed ? Colors.transparent : Colors.grey,
          backgroundBlendMode: BlendMode.saturation,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isFed
                ? const Color(0xFFFFD700)
                : const Color.fromARGB(255, 85, 85, 85),
            width: 3,
          ),
          gradient: isFed
              ? const RadialGradient(
                  colors: [
                    Colors.white,
                    Color.fromRGBO(255, 243, 175, 1),
                  ],
                  center: Alignment(-0.5, -0.6),
                  radius: 0.6,
                )
              : const RadialGradient(
                  colors: [Colors.blueGrey, Colors.grey],
                  center: Alignment(-0.5, -0.6),
                  radius: 0.6,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5.0,
              offset: const Offset(0, 3),
            ),
          ],
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
