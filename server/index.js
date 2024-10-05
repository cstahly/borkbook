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
        "Monday": { "breakfast": true, "lunch": true, "dinner": true },
        "Tuesday": { "breakfast": true, "lunch": true, "dinner": true },
        "Wednesday": { "breakfast": true, "lunch": true, "dinner": true },
        "Thursday": { "breakfast": true, "lunch": true, "dinner": false },
        "Friday": { "breakfast": false, "lunch": false, "dinner": false },
      },
      "Tucker": {
        "Monday": { "breakfast": true, "lunch": true, "dinner": true },
        "Tuesday": { "breakfast": true, "lunch": true, "dinner": true },
        "Wednesday": { "breakfast": true, "lunch": true, "dinner": true },
        "Thursday": { "breakfast": true, "lunch": true, "dinner": false },
        "Friday": { "breakfast": false, "lunch": false, "dinner": false },
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
  res.json(meals);
});

// Route to update the meal data
app.post('/meals', async (req, res) => {
  const { dog, day, meal, fed } = req.body;

  if (meals[dog] && meals[dog][day] && typeof meals[dog][day][meal] !== 'undefined') {
    meals[dog][day][meal] = fed;

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

