import '../models/nutrition_models.dart';

const MacroTotals kDailyGoals = MacroTotals(
  calories: 2200,
  protein: 165,
  carbs: 250,
  fats: 70,
);

const MacroTotals kConsumed = MacroTotals(
  calories: 1650,
  protein: 120,
  carbs: 180,
  fats: 52,
);

const List<ExtraNutrient> kExtraNutrients = <ExtraNutrient>[
  ExtraNutrient(name: 'Glucosa', value: 85, unit: 'mg/dL'),
  ExtraNutrient(name: 'Azúcares', value: 45, unit: 'g', max: 50),
  ExtraNutrient(name: 'Sodio', value: 1800, unit: 'mg', max: 2300),
];

const List<Meal> kMeals = <Meal>[
  Meal(
    id: 1,
    name: 'Desayuno',
    time: '08:00',
    calories: 450,
    protein: 30,
    carbs: 50,
    fats: 15,
    foods: <Food>[
      Food(name: 'Avena', quantity: 80, unit: 'g'),
      Food(name: 'Plátano', quantity: 1, unit: 'unidad'),
      Food(name: 'Proteína whey', quantity: 30, unit: 'g'),
      Food(name: 'Almendras', quantity: 20, unit: 'g'),
    ],
  ),
  Meal(
    id: 2,
    name: 'Almuerzo',
    time: '13:30',
    calories: 650,
    protein: 50,
    carbs: 70,
    fats: 20,
    foods: <Food>[
      Food(name: 'Pechuga de pollo', quantity: 200, unit: 'g'),
      Food(name: 'Arroz integral', quantity: 150, unit: 'g'),
      Food(name: 'Brócoli', quantity: 100, unit: 'g'),
      Food(name: 'Aguacate', quantity: 50, unit: 'g'),
    ],
  ),
  Meal(
    id: 3,
    name: 'Merienda',
    time: '17:00',
    calories: 250,
    protein: 20,
    carbs: 30,
    fats: 8,
    foods: <Food>[
      Food(name: 'Yogurt griego', quantity: 150, unit: 'g'),
      Food(name: 'Frutos rojos', quantity: 80, unit: 'g'),
      Food(name: 'Miel', quantity: 10, unit: 'g'),
    ],
  ),
  Meal(
    id: 4,
    name: 'Cena',
    time: '20:00',
    calories: 300,
    protein: 20,
    carbs: 30,
    fats: 9,
    foods: <Food>[
      Food(name: 'Salmón', quantity: 150, unit: 'g'),
      Food(name: 'Ensalada mixta', quantity: 200, unit: 'g'),
      Food(name: 'Aceite de oliva', quantity: 10, unit: 'ml'),
    ],
  ),
];