import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import Anthropic from '@anthropic-ai/sdk';

initializeApp();
const db = getFirestore();

export const generateRecipes = onCall(
  {secrets: ['ANTHROPIC_KEY']},
  async (request) => {
    const anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_KEY,
    });
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be logged in');
    }

    const {ingredients, targets} = request.data;
    const userId = request.auth.uid;

    const today = new Date().toISOString().split('T')[0];
    const dayDoc = await db
      .collection('users')
      .doc(userId)
      .collection('mealLogs')
      .doc(today)
      .get();

    const logged = dayDoc.data() ?? {};
    const remainingCalories =
      (targets.calories ?? 500) - (logged.totalCalories ?? 0);
    const remainingProtein =
      (targets.protein ?? 40) - (logged.totalProtein ?? 0);
    const remainingCarbs =
      (targets.carbs ?? 50) - (logged.totalCarbs ?? 0);

    const prompt = `
      You are a nutrition-aware recipe assistant.

      The user has these ingredients available: ${ingredients.join(', ')}.

      Their remaining macro targets for today are:
      - Calories: ${Math.max(0, remainingCalories)} kcal
      - Protein: ${Math.max(0, remainingProtein)}g
      - Carbs: ${Math.max(0, remainingCarbs)}g

      Generate exactly 3 recipe suggestions that use some or all of
      the available ingredients and fit within the macro targets.

      Respond ONLY with a valid JSON array. No preamble, no markdown.
      Each recipe must have these exact fields:
      {
        "name": string,
        "cookTime": number (minutes),
        "calories": number,
        "protein": number (grams),
        "carbs": number (grams),
        "fat": number (grams),
        "ingredients": string[],
        "steps": string[]
      }
    `;

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 2000,
      messages: [{role: 'user', content: prompt}],
    });

    const text =
      response.content[0].type === 'text' ? response.content[0].text : '';
    const clean = text.replace(/```json|```/g, '').trim();

    return JSON.parse(clean);
  });
