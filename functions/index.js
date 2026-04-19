const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const modelName = "gemini-3-flash-preview";
const bangkokOffsetMs = 7 * 60 * 60 * 1000;
const maxSingleFoodCalories = 5000;
const maxSingleMacroGrams = 500;
const maxDailyCaloriesIn = 20000;
const maxDailyCaloriesOut = 10000;
const maxWaterGlasses = 40;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

exports.estimateFood = onRequest({ secrets: [geminiApiKey] }, async (req, res) => {
  if (req.method === "OPTIONS") {
    return res.status(204).set(corsHeaders).send("");
  }
  res.set(corsHeaders);

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const foodName = `${req.body?.foodName || ""}`.trim();
  if (!foodName) {
    return res.status(400).json({ error: "foodName is required" });
  }

  const prompt = `You are a nutrition expert.
Estimate the nutrition for "${foodName}" (1 serving) and respond in exactly 4 lines:
calories: <integer>
protein: <integer>
carbs: <integer>
fat: <integer>

Rules:
- use only integers
- use a typical Thai serving size
- no markdown
- no explanation`;

  try {
    const result = await callGeminiForNutrition({
      prompt,
      apiKey: geminiApiKey.value(),
    });
    return res.json(result);
  } catch (error) {
    logger.error("estimateFood failed", error);
    return res.status(500).json({ error: `${error}` });
  }
});

exports.analyzeFoodImage = onRequest(
  { secrets: [geminiApiKey] },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      return res.status(204).set(corsHeaders).send("");
    }
    res.set(corsHeaders);

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const imageBase64 = `${req.body?.imageBase64 || ""}`.trim();
    if (!imageBase64) {
      return res.status(400).json({ error: "imageBase64 is required" });
    }

    const prompt = `You are a nutrition expert.
Analyze this food image and respond in exactly 5 lines:
name: <food name in Thai>
calories: <integer>
protein: <integer>
carbs: <integer>
fat: <integer>

Rules:
- use only integers
- per 1 serving
- no markdown
- no explanation
- if uncertain, still estimate the closest common Thai dish`;

    try {
      const result = await callGeminiForNutrition({
        prompt,
        imageBase64,
        apiKey: geminiApiKey.value(),
      });
      return res.json(result);
    } catch (error) {
      logger.error("analyzeFoodImage failed", error);
      return res.status(500).json({ error: `${error}` });
    }
  }
);

exports.askCoach = onRequest({ secrets: [geminiApiKey] }, async (req, res) => {
  if (req.method === "OPTIONS") {
    return res.status(204).set(corsHeaders).send("");
  }
  res.set(corsHeaders);

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const message = `${req.body?.message || ""}`.trim();
  const history = Array.isArray(req.body?.history) ? req.body.history : [];
  if (!message) {
    return res.status(400).json({ error: "message is required" });
  }

  const historyContext = history
    .filter(
      (entry) =>
        entry &&
        typeof entry.role === "string" &&
        typeof entry.content === "string"
    )
    .slice(-10)
    .map((entry) => `${entry.role === "user" ? "User" : "Coach"}: ${entry.content}`)
    .join("\n");

  const prompt = `You are a friendly Thai health coach for an app called Foodcal.
Reply only in Thai. Keep the advice practical, concise, and safe.
If the user asks about a plateau, overeating, low protein, low water intake, or consistency, give 3-5 actionable suggestions.
Avoid medical diagnosis and tell the user to seek a professional if symptoms sound dangerous.

${historyContext ? `Previous conversation:\n${historyContext}\n\n` : ""}User: ${message}`;

  try {
    const reply = await callGeminiForText({
      prompt,
      apiKey: geminiApiKey.value(),
      temperature: 0.7,
      maxOutputTokens: 512,
    });
    return res.json({ reply });
  } catch (error) {
    logger.error("askCoach failed", error);
    return res.status(500).json({ error: `${error}` });
  }
});

exports.recordDailyVisit = onCall(async (request) => {
  const uid = requireAuth(request);
  const now = new Date();
  const todayKey = getBangkokDateKey(now);
  const userRef = db.collection("users").doc(uid);

  // Check user exists BEFORE the transaction so HttpsError is not swallowed
  // by Firestore internals and re-thrown as [internal].
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }

  const result = await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(userRef);
    const userData = snap.data() || {};
    const currentStreak = toPositiveInt(userData.streak, 0);
    const lastLoginDate = parseDate(userData.lastLoginDate);
    const lastLoginKey = lastLoginDate ? getBangkokDateKey(lastLoginDate) : null;

    if (lastLoginKey === todayKey) {
      return {
        streak: currentStreak,
        dateKey: todayKey,
        unchanged: true,
      };
    }

    let nextStreak = 1;
    if (lastLoginKey && differenceInDays(lastLoginKey, todayKey) === 1) {
      nextStreak = currentStreak > 0 ? currentStreak + 1 : 1;
    }

    transaction.update(userRef, {
      streak: nextStreak,
      lastLoginDate: now.toISOString(),
    });

    return {
      streak: nextStreak,
      dateKey: todayKey,
      unchanged: false,
    };
  });

  return result;
});

exports.appendFood = onCall(async (request) => {
  const uid = requireAuth(request);
  const food = normalizeFood(request.data?.food);
  const todayKey = getBangkokDateKey(new Date());
  const logRef = getDailyLogRef(uid, todayKey);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(logRef);
    if (!snapshot.exists) {
      transaction.set(logRef, {
        date: todayKey,
        caloriesIn: food.calories,
        caloriesOut: 0,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
        waterGlasses: 0,
        foods: [food],
        workouts: [],
        lastUpdated: FieldValue.serverTimestamp(),
      });
      return;
    }

    const data = snapshot.data() || {};
    const foods = Array.isArray(data.foods) ? data.foods.slice() : [];
    const caloriesIn = toPositiveInt(data.caloriesIn, 0) + food.calories;
    if (caloriesIn > maxDailyCaloriesIn) {
      throw new HttpsError("failed-precondition", "Daily calories exceed the allowed limit.");
    }

    foods.push(food);
    transaction.update(logRef, {
      caloriesIn,
      protein: toPositiveInt(data.protein, 0) + food.protein,
      carbs: toPositiveInt(data.carbs, 0) + food.carbs,
      fat: toPositiveInt(data.fat, 0) + food.fat,
      foods,
      lastUpdated: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

exports.updateWater = onCall(async (request) => {
  const uid = requireAuth(request);
  const delta = Number(request.data?.delta);
  if (![1, 2, 6, -1].includes(delta)) {
    throw new HttpsError("invalid-argument", "Unsupported water delta.");
  }

  const todayKey = getBangkokDateKey(new Date());
  const logRef = getDailyLogRef(uid, todayKey);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(logRef);
    if (!snapshot.exists) {
      if (delta <= 0) return;

      transaction.set(logRef, {
        date: todayKey,
        caloriesIn: 0,
        caloriesOut: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        waterGlasses: delta,
        foods: [],
        workouts: [],
        lastUpdated: FieldValue.serverTimestamp(),
      });
      return;
    }

    const data = snapshot.data() || {};
    let nextWater = toPositiveInt(data.waterGlasses, 0) + delta;
    if (nextWater < 0) nextWater = 0;
    if (nextWater > maxWaterGlasses) {
      throw new HttpsError("failed-precondition", "Daily water exceeds the allowed limit.");
    }

    transaction.update(logRef, {
      waterGlasses: nextWater,
      lastUpdated: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

exports.startWorkoutSession = onCall(async (request) => {
  const uid = requireAuth(request);
  const workoutId = toPositiveInt(request.data?.workoutId, 0);
  const minutes = toPositiveInt(request.data?.minutes, 0);

  if (workoutId <= 0 || minutes <= 0 || minutes > 180) {
    throw new HttpsError("invalid-argument", "Invalid workout session payload.");
  }

  const todayKey = getBangkokDateKey(new Date());
  const sessionRef = db
    .collection("users")
    .doc(uid)
    .collection("workout_sessions")
    .doc(String(workoutId));

  await sessionRef.set(
    {
      workoutId,
      minutes,
      dateKey: todayKey,
      startedAt: new Date().toISOString(),
      completed: false,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { success: true, dateKey: todayKey };
});

exports.finishWorkout = onCall(async (request) => {
  const uid = requireAuth(request);
  const workout = normalizeWorkout(request.data?.workout);
  const todayKey = getBangkokDateKey(new Date());
  const logRef = getDailyLogRef(uid, todayKey);
  const sessionRef = db
    .collection("users")
    .doc(uid)
    .collection("workout_sessions")
    .doc(String(workout.id));

  await db.runTransaction(async (transaction) => {
    const [logSnap, sessionSnap] = await Promise.all([
      transaction.get(logRef),
      transaction.get(sessionRef),
    ]);

    if (!sessionSnap.exists) {
      throw new HttpsError("failed-precondition", "Workout session has not been started.");
    }

    const session = sessionSnap.data() || {};
    const sessionDateKey = session.dateKey;
    const startedAt = parseDate(session.startedAt);
    if (sessionDateKey !== todayKey || !startedAt) {
      throw new HttpsError("failed-precondition", "Workout session is no longer valid.");
    }

    const requiredMinutes = Math.min(
      workout.minutes,
      Math.max(1, Math.ceil(workout.minutes * 0.6))
    );
    const elapsedMinutes = Math.floor((Date.now() - startedAt.getTime()) / 60000);
    if (elapsedMinutes < requiredMinutes) {
      throw new HttpsError(
        "failed-precondition",
        `Workout needs at least ${requiredMinutes} minutes before completion.`
      );
    }

    const burned = burnedCaloriesForWorkout(workout);
    if (!logSnap.exists) {
      transaction.set(logRef, {
        date: todayKey,
        caloriesIn: 0,
        caloriesOut: burned,
        protein: 0,
        carbs: 0,
        fat: 0,
        waterGlasses: 0,
        foods: [],
        workouts: [{ ...workout, completedAt: new Date().toISOString() }],
        lastUpdated: FieldValue.serverTimestamp(),
      });
    } else {
      const data = logSnap.data() || {};
      const workouts = Array.isArray(data.workouts) ? data.workouts.slice() : [];
      if (workouts.some((item) => Number(item?.id) === workout.id)) {
        transaction.update(sessionRef, {
          completed: true,
          completedAt: new Date().toISOString(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const nextCaloriesOut = toPositiveInt(data.caloriesOut, 0) + burned;
      if (nextCaloriesOut > maxDailyCaloriesOut) {
        throw new HttpsError(
          "failed-precondition",
          "Daily workout calories exceed the allowed limit."
        );
      }

      workouts.push({ ...workout, completedAt: new Date().toISOString() });
      transaction.update(logRef, {
        caloriesOut: nextCaloriesOut,
        workouts,
        lastUpdated: FieldValue.serverTimestamp(),
      });
    }

    transaction.update(sessionRef, {
      completed: true,
      completedAt: new Date().toISOString(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

exports.setAdminRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await db.collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can change roles.");
  }

  const { targetUid, role } = request.data;
  if (typeof targetUid !== "string" || !targetUid) {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }
  if (role !== "admin" && role !== "user") {
    throw new HttpsError("invalid-argument", "role must be 'admin' or 'user'.");
  }

  await db.collection("users").doc(targetUid).update({ role });
  logger.info(`Admin ${callerUid} set role='${role}' for user ${targetUid}`);
  return { success: true };
});

exports.deleteUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await db.collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can delete accounts.");
  }

  const { targetUid } = request.data;
  if (typeof targetUid !== "string" || !targetUid) {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }
  if (targetUid === callerUid) {
    throw new HttpsError("invalid-argument", "You cannot delete your own account here.");
  }

  try {
    await getAuth().deleteUser(targetUid);
    await db.collection("users").doc(targetUid).delete();
    logger.info(`Admin ${callerUid} deleted user ${targetUid}`);
    return { success: true };
  } catch (error) {
    logger.error(`Failed to delete user ${targetUid}`, error);
    throw new HttpsError("internal", "Failed to delete user account.");
  }
});

function requireAuth(request) {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  return request.auth.uid;
}

function getBangkokDateKey(date) {
  return new Date(date.getTime() + bangkokOffsetMs).toISOString().slice(0, 10);
}

function differenceInDays(fromKey, toKey) {
  const from = new Date(`${fromKey}T00:00:00.000Z`);
  const to = new Date(`${toKey}T00:00:00.000Z`);
  return Math.round((to.getTime() - from.getTime()) / (24 * 60 * 60 * 1000));
}

function parseDate(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function toPositiveInt(value, fallback) {
  const parsed = Number.parseInt(`${value ?? ""}`, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}

function getDailyLogRef(uid, dateKey) {
  return db.collection("users").doc(uid).collection("daily_logs").doc(dateKey);
}

function normalizeFood(raw) {
  const food = {
    name: `${raw?.name || ""}`.trim(),
    calories: toPositiveInt(raw?.calories, -1),
    protein: toPositiveInt(raw?.protein, 0),
    carbs: toPositiveInt(raw?.carbs, 0),
    fat: toPositiveInt(raw?.fat, 0),
    time: parseDate(raw?.time)?.toISOString() || new Date().toISOString(),
    mealType: `${raw?.mealType || "Snack"}`.trim(),
  };

  if (!food.name) {
    throw new HttpsError("invalid-argument", "Food name is required.");
  }
  if (
    food.calories < 0 ||
    food.calories > maxSingleFoodCalories ||
    food.protein > maxSingleMacroGrams ||
    food.carbs > maxSingleMacroGrams ||
    food.fat > maxSingleMacroGrams
  ) {
    throw new HttpsError("invalid-argument", "Food values are out of range.");
  }
  if (!["Breakfast", "Lunch", "Dinner", "Snack"].includes(food.mealType)) {
    throw new HttpsError("invalid-argument", "Invalid meal type.");
  }

  return food;
}

function normalizeWorkout(raw) {
  const workout = {
    id: toPositiveInt(raw?.id, 0),
    title: `${raw?.title || ""}`.trim(),
    level: `${raw?.level || ""}`.trim(),
    duration: `${raw?.duration || ""}`.trim(),
    minutes: toPositiveInt(raw?.minutes, 0),
    type: `${raw?.type || ""}`.trim(),
  };

  if (
    workout.id <= 0 ||
    !workout.title ||
    !["Beginner", "Intermediate", "Expert"].includes(workout.level) ||
    workout.minutes < 1 ||
    workout.minutes > 180 ||
    !workout.type
  ) {
    throw new HttpsError("invalid-argument", "Invalid workout payload.");
  }

  return workout;
}

function burnedCaloriesForWorkout(workout) {
  if (workout.level === "Intermediate") return workout.minutes * 7;
  if (workout.level === "Expert") return workout.minutes * 10;
  return workout.minutes * 5;
}

async function callGeminiForNutrition({ prompt, imageBase64, apiKey }) {
  const payload = {
    contents: [
      {
        parts: [
          { text: prompt },
          ...(imageBase64
            ? [
                {
                  inline_data: {
                    mime_type: "image/jpeg",
                    data: imageBase64,
                  },
                },
              ]
            : []),
        ],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      maxOutputTokens: imageBase64 ? 256 : 128,
    },
  };

  const response = await callGeminiApi(payload, apiKey);
  const text = extractCandidateText(response);
  const parsed = parseNutritionResponse(text);
  if (!parsed) {
    throw new Error(`Unable to parse Gemini response: ${text}`);
  }
  return parsed;
}

async function callGeminiForText({
  prompt,
  apiKey,
  temperature = 0.7,
  maxOutputTokens = 512,
}) {
  const payload = {
    contents: [
      {
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature,
      maxOutputTokens,
    },
  };

  const response = await callGeminiApi(payload, apiKey);
  const text = extractCandidateText(response).trim();
  if (!text) {
    throw new Error("Gemini returned empty text.");
  }
  return text;
}

async function callGeminiApi(payload, apiKey) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini ${response.status}: ${text}`);
  }

  return response.json();
}

function extractCandidateText(data) {
  return (
    data?.candidates?.[0]?.content?.parts?.find((part) => typeof part?.text === "string")
      ?.text || ""
  );
}

function parseNutritionResponse(text) {
  if (!text || typeof text !== "string") return null;

  const jsonMatch = text.trim().match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      return normalizeNutritionResult(JSON.parse(jsonMatch[0]));
    } catch (_) {}
  }

  const result = {};
  for (const rawLine of text.replace(/\r/g, "").split("\n")) {
    const line = rawLine.trim();
    if (!line) continue;

    const match = line.match(/^([A-Za-z_ ]+)\s*:\s*(.+)$/);
    if (!match) continue;

    const key = match[1].trim().toLowerCase().replace(/\s+/g, "");
    const value = match[2].trim();

    if (key === "name") {
      result.name = value;
      continue;
    }

    const numberMatch = value.match(/-?\d+/);
    if (!numberMatch) continue;
    const number = Number.parseInt(numberMatch[0], 10);
    if (Number.isNaN(number)) continue;

    if (key.includes("calorie")) result.calories = number;
    if (key === "protein") result.protein = number;
    if (key === "carbs" || key === "carb") result.carbs = number;
    if (key === "fat") result.fat = number;
  }

  return normalizeNutritionResult(result);
}

function normalizeNutritionResult(result) {
  const calories = toInt(result?.calories);
  const protein = toInt(result?.protein);
  const carbs = toInt(result?.carbs);
  const fat = toInt(result?.fat);

  if ([calories, protein, carbs, fat].some((value) => value == null)) {
    return null;
  }

  const normalized = { calories, protein, carbs, fat };
  const name = `${result?.name || ""}`.trim();
  if (name) normalized.name = name;
  return normalized;
}

function toInt(value) {
  if (typeof value === "number" && Number.isFinite(value)) return Math.round(value);
  if (value == null) return null;
  const match = `${value}`.match(/-?\d+/);
  return match ? Number.parseInt(match[0], 10) : null;
}
