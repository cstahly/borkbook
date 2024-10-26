const express = require('express');
const cors = require('cors'); // Import cors middleware
const fs = require('fs').promises;
const app = express();
const port = 4444;

app.use(express.json());

// Use CORS middleware to allow cross-origin requests
app.use(cors({
  origin: '*', // You can specify a specific origin instead of '*' for more security
  methods: ['GET', 'POST'], // Allow only specific HTTP methods if needed
}));

const mealsFile = './meals.json';
let meals = {};
let lastUpdated = new Date(); // Track the last updated time

// Load meal data from the file at server startup
const loadMealsFromFile = async () => {
  try {
    const data = await fs.readFile(mealsFile, 'utf-8');
    meals = JSON.parse(data);
    console.log('Meal data loaded from file.');
  } catch (err) {
    console.error('Could not load meal data from file, initializing default data.', err);
    meals = {
      "Precious": {
        "Monday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Tuesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Wednesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Thursday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Friday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Saturday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Sunday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      },
      "Tucker": {
        "Monday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Tuesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Wednesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Thursday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Friday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Saturday": { "Breakfast": false, "Lunch": false, "Dinner": false },
        "Sunday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      }
    };
    await saveMealsToFile();
  }
};

// Save the current meal data to the file
const saveMealsToFile = async () => {
  try {
    await fs.writeFile(mealsFile, JSON.stringify(meals, null, 2), 'utf-8');
    console.log('Meal data saved to file.');
  } catch (err) {
    console.error('Error writing meal data to file:', err);
  }
};

// Route to get the meal data
app.get('/meals', (req, res) => {
  console.log(`Meal request: ${JSON.stringify(req.body)}`);
  res.json(meals);
});

// Route to get the last time the meals were updated
app.get('/last-updated', (req, res) => {
  console.log(`Last update request: ${JSON.stringify(req.body)}`);
  res.json({ last_updated: lastUpdated });
});

// Route to update the meal data
app.post('/meals', async (req, res) => {
  const { dog, day, meal, fed } = req.body;

  // console.log(`Meal update: ${JSON.stringify(req.body)}`);

  // console.log('meals[dog]: '+JSON.stringify(meals[dog]));
  // console.log('meals[dog][day]: '+JSON.stringify(meals[dog][day]));
  // console.log('typeof: ' + typeof meals[dog][day][meal]);

  const properMeal = meal.charAt(0).toUpperCase() + meal.slice(1);

  if (meals[dog] && meals[dog][day] ) { //&& typeof meals[dog][day][meal] !== 'undefined') {
    meals[dog][day][properMeal] = fed;
    lastUpdated = new Date();  // Update the last updated timestamp

    // Save the updated meal data to file
    await saveMealsToFile();

    return res.json({ message: 'Meal updated successfully!' });
  } else {
    return res.status(400).json({ message: 'Invalid data provided!' });
  }
});

// Load meal data before starting the server
loadMealsFromFile().then(() => {
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
});
