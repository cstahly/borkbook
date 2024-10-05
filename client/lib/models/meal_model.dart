class MealModel {
  String dogName;
  Map<String, Map<String, bool>> days; // Mapping days to meals

  MealModel({
    required this.dogName,
    required this.days,
  });

  factory MealModel.fromJson(String dogName, Map<String, dynamic> json) {
    Map<String, Map<String, bool>> days = {};
    json.forEach((day, meals) {
      days[day] = Map<String, bool>.from(meals);
    });
    return MealModel(dogName: dogName, days: days);
  }

  Map<String, dynamic> toJson() {
    return days;
  }
}
