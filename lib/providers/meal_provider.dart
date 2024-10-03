import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealProvider with ChangeNotifier {
  List<MealModel> meals = [];

  // Fetch meal data from the backend
  Future<void> fetchMeals() async {
    final url =
        'http://freepuppyservices.com:4444/meals'; // Replace with your backend URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      meals = data.entries
          .map((entry) => MealModel.fromJson(entry.key, entry.value))
          .toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load meals');
    }
  }

  // Update a meal's status
  Future<void> updateMeal(
      String dogName, String day, String meal, bool fed) async {
    final url = 'http://freepuppyservices.com:4444/meals';
    final body = json.encode({
      'dog': dogName,
      'day': day,
      'meal': meal,
      'fed': fed,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      fetchMeals(); // Refresh the meal data after update
    } else {
      throw Exception(
          'Failed to update meal: ' + response.statusCode.toString());
    }
  }
}
