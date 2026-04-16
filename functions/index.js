const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const modelName = "gemini-3-flash-preview";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

exports.estimateFood = onRequest(
  { secrets: [geminiApiKey] },
  async (req, res) => {
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
      const result = await callGemini({
        prompt,
        apiKey: geminiApiKey.value(),
      });
      return res.json(result);
    } catch (error) {
      logger.error("estimateFood failed", error);
      return res.status(500).json({ error: `${error}` });
    }
  }
);

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
      const result = await callGemini({
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

async function callGemini({ prompt, imageBase64, apiKey }) {
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

  const data = await response.json();
  const text = extractCandidateText(data);
  const parsed = parseNutritionResponse(text);

  if (!parsed) {
    throw new Error(`Unable to parse Gemini response: ${text}`);
  }

  return parsed;
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
      return normalizeResult(JSON.parse(jsonMatch[0]));
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

  return normalizeResult(result);
}

function normalizeResult(result) {
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

/**
 * setAdminRole — callable function (server-side only).
 * Lets an existing admin promote or demote another user's role.
 *
 * Request: { targetUid: string, role: 'admin' | 'user' }
 *
 * Security:
 *  - Caller must be authenticated.
 *  - Caller's Firestore document must have role == 'admin' (server-verified).
 *  - The role value is validated server-side; clients cannot forge it.
 */
exports.setAdminRole = onCall(async (request) => {
  // 1. Must be authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const callerUid = request.auth.uid;
  const db = getFirestore();

  // 2. Verify caller is an admin via Firestore (server-side check)
  const callerDoc = await db.collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can change roles.");
  }

  const { targetUid, role } = request.data;

  // 3. Validate inputs
  if (typeof targetUid !== "string" || !targetUid) {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }
  if (role !== "admin" && role !== "user") {
    throw new HttpsError("invalid-argument", "role must be 'admin' or 'user'.");
  }

  // 4. Write role using Admin SDK (bypasses Firestore security rules intentionally)
  await db.collection("users").doc(targetUid).update({ role });

  logger.info(`Admin ${callerUid} set role='${role}' for user ${targetUid}`);
  return { success: true };
});
