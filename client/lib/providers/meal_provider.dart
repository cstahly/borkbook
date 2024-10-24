import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealProvider with ChangeNotifier {
  List<MealModel> meals = [];

  bool _isLoading = true; // Track loading state
  String? _error; // Track errors

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch meal data from the backend
  Future<void> fetchMeals() async {
    _isLoading = true; // Set loading to true when fetching starts
    _error = null; // Clear any previous errors
    notifyListeners(); // Notify listeners that loading has started

    const url =
        'http://freepuppyservices.com:4444/meals'; // Replace with your backend URL
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert each dog and their meal data into a MealModel object
        meals = data.entries.map((entry) {
          return MealModel(
            dogName: entry.key,
            days: (entry.value as Map<String, dynamic>)
                .map<String, Map<String, bool>>(
              (day, mealsMap) {
                return MapEntry(
                  day,
                  (mealsMap as Map<String, dynamic>).map<String, bool>(
                    (meal, value) => MapEntry(meal, value as bool),
                  ),
                );
              },
            ),
          );
        }).toList();

        notifyListeners();
      } else {
        _error = 'Failed to load meals: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Failed to load meals: $e';
    } finally {
      _isLoading = false; // Set loading to false once fetching is done
      notifyListeners(); // Notify listeners that fetching has finished
    }
  }

  // Method to get meals for a specific day
  Map<String, Map<String, bool>> getMealsForDay(String day) {
    Map<String, Map<String, bool>> mealsForDay = {};

    for (var meal in meals) {
      mealsForDay[meal.dogName] = meal.days[day] ?? {};
    }

    return mealsForDay;
  }

  // Update a meal's status
  Future<void> updateMeal(
      String dogName, String day, String meal, bool fed) async {
    const url = 'http://freepuppyservices.com:4444/meals';
    final body = json.encode({
      'dog': dogName,
      'day': day,
      'meal': meal,
      'fed': fed,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        await fetchMeals(); // Refresh the meal data after update
      } else {
        _error = 'Failed to update meal: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Failed to update meal: $e';
    } finally {
      notifyListeners();
    }
  }
}
