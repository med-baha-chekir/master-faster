require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { Ollama } = require('ollama');

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
  if (req.method === 'OPTIONS') return res.status(200).end();
  next();
});

// ─── Request logger ────────────────────────────────────────────────────────
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(`${req.method} ${req.path} ${res.statusCode} ${Date.now() - start}ms`);
  });
  next();
});

const ollama = new Ollama({ host: process.env.OLLAMA_HOST || 'http://localhost:11434' });
const PORT   = process.env.PORT  || 3000;
const MODEL  = process.env.OLLAMA_MODEL || 'qwen2.5:7b';

// ─── In-memory session store ───────────────────────────────────────────────
const sessions = {};

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

function cleanJson(text) {
  if (!text) return '[]';
  return text
    .replace(/```json\s*/gi, '')
    .replace(/```\s*/gi, '')
    .replace(/^\s*[\r\n]/gm, '')
    .trim();
}

// Build a readable transcript block for injection into prompts
function formatTranscript(transcript) {
  return transcript
    .map(t => {
      const speaker = t.speaker === 'agent' ? 'Sarra (agent)' : 'Receiver';
      return `${speaker}: ${t.text}`;
    })
    .join('\n');
}

// Core LLM call — all model calls go through here
async function callOllama(systemPrompt, userPrompt, expectJson = false) {
  const response = await ollama.chat({
    model: MODEL,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user',   content: userPrompt   },
    ],
    options: {
      temperature:  expectJson ? 0.1 : 0.5,
      num_predict:  expectJson ? 180 : 350,
      repeat_penalty: 1.1,
      stop: expectJson ? ['\n\n', '```'] : ['```'],
    },
  });

  let text = response.message.content.trim();

  // Strip surrounding quotes that the model sometimes adds
  text = text.replace(/^["']|["']$/g, '');

  if (expectJson) {
    text = cleanJson(text);
    // Extract first JSON array found
    const arrayMatch = text.match(/\[[\s\S]*?\]/);
    if (arrayMatch) text = arrayMatch[0];
  }

  return text;
}

// Safe JSON parse with fallback
function safeParseArray(text, fallback) {
  try {
    const parsed = JSON.parse(text);
    if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    return fallback;
  } catch {
    // Try to extract quoted strings
    const matches = text.match(/"([^"]{1,40})"/g);
    if (matches && matches.length >= 2) {
      return matches.map(s => s.replace(/"/g, '')).slice(0, 4);
    }
    return fallback;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM PROMPTS  — centralised so personality is consistent everywhere
// ═══════════════════════════════════════════════════════════════════════════

function sarraSYS(session) {
  return (
    `You are Sarra, a professional and warm AI voice assistant. ` +
    `You are calling on behalf of a non-verbal person named ${session.userName} ` +
    `who cannot speak and uses an app to communicate. ` +
    `Your job is to speak clearly and politely to the receiver on their behalf. ` +
    `Always stay on topic: "${session.scenario}". ` +
    `Address the receiver respectfully. ` +
    `Speak in ${session.language}. ` +
    `Keep every sentence short and natural (1-2 sentences max). ` +
    `Never add stage directions, never use markdown or backticks. ` +
    `Return plain spoken text only.`
  );
}

function receiverSYS(session) {
  return (
    `You are a realistic person who just received a phone call. ` +
    `The caller is an AI assistant named Sarra helping a non-verbal person named ${session.userName}. ` +
    `The topic of the call is: "${session.scenario}". ` +
    `React naturally — you are willing to help but you ask the questions a real person would ask. ` +
    `Speak in ${session.language}. ` +
    `Keep replies short (1-2 sentences). ` +
    `Never break character. Never use markdown or backticks. ` +
    `Return plain spoken text only. ` +
    `Only add the exact tag [CALL_COMPLETE] at the very end of your reply when ` +
    `the main request is FULLY resolved AND at least 4 conversation turns have happened. ` +
    `Do NOT add [CALL_COMPLETE] before turn 4.`
  );
}

function cardsSYS(language) {
  return (
    `You generate short tap-card reply options for a non-verbal person on a phone call. ` +
    `The options must be in ${language}. ` +
    `Rules: exactly 3 or 4 options, each option maximum 6 words, ` +
    `options must be direct and actionable (not vague), ` +
    `always include at least one affirmative and one negative option when relevant, ` +
    `return ONLY a valid JSON array of strings — no explanation, no markdown, no extra text. ` +
    `Example: ["Oui s'il vous plaît","Non merci","Pouvez-vous répéter","Demain matin"]`
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GET /health
// ═══════════════════════════════════════════════════════════════════════════
app.get('/health', async (req, res) => {
  let ollamaStatus = 'not running';
  let availableModels = [];
  try {
    const list = await ollama.list();
    availableModels = list.models.map(m => m.name);
    ollamaStatus = 'running';
  } catch { /* ignore */ }

  res.json({
    status: 'ok',
    timestamp: new Date(),
    llm: 'ollama',
    model: MODEL,
    ollama: ollamaStatus,
    availableModels,
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// GET /  (root — Railway health check)
// ═══════════════════════════════════════════════════════════════════════════
app.get('/', (req, res) => {
  res.json({
    app: 'VoiceBridge Backend',
    version: '2.0.0',
    status: 'running',
    endpoints: [
      'GET  /health',
      'POST /simulate-call-start',
      'POST /simulate-caller-response',
      'POST /simulate-call-end',
      'POST /simulate-summary',
      'POST /generate-cards',
      'POST /summarize',
      'POST /speak',
    ],
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /simulate-call-start
// ═══════════════════════════════════════════════════════════════════════════
app.post('/simulate-call-start', async (req, res) => {
  const { scenario, userName, userAddress, language = 'fr' } = req.body;

  if (!scenario || !userName || !userAddress) {
    return res.status(400).json({
      error: 'Missing required fields: scenario, userName, userAddress',
    });
  }

  const sessionId =
    Date.now().toString(36) + Math.random().toString(36).substr(2);

  sessions[sessionId] = {
    scenario,
    userName,
    userAddress,
    language,
    transcript: [],
    turn: 0,
    status: 'active',
  };

  const session = sessions[sessionId];

  // Sarra's structured opening — always the same pattern for clarity
  const openingPrompt =
    `The receiver just picked up the phone. ` +
    `Introduce yourself as Sarra, explain you are an AI assistant calling on behalf ` +
    `of a non-verbal person named ${userName}, and state the purpose of the call: "${scenario}". ` +
    `Ask if they can help. Keep it to 2 sentences maximum.`;

  try {
    const openingLine = await callOllama(sarraSYS(session), openingPrompt);
    session.transcript.push({
      speaker: 'agent',
      text: openingLine,
      timestamp: Date.now(),
    });

    // ── Immediately generate the receiver's first reply (picks up, says OK) ──
    const receiverInitPrompt =
      `Sarra just said: "${openingLine}"\n` +
      `You just picked up the phone. Respond politely — acknowledge you understand ` +
      `and are ready to help. 1 sentence only.`;

    const receiverFirstReply = await callOllama(
      receiverSYS(session),
      receiverInitPrompt
    );
    session.transcript.push({
      speaker: 'caller',
      text: receiverFirstReply,
      timestamp: Date.now(),
    });
    session.turn = 1;

    // ── Generate first response cards based on the receiver's reply ──
    const cardsPrompt =
      `Conversation so far:\n${formatTranscript(session.transcript)}\n\n` +
      `The receiver just said: "${receiverFirstReply}"\n` +
      `Generate 3-4 reply options for ${userName} to tap. ` +
      `Options must be relevant to "${scenario}" and the receiver's reply.`;

    const cardsRaw = await callOllama(cardsSYS(language), cardsPrompt, true);
    const fallbackCards =
      language === 'fr'
        ? ['Oui, allons-y', 'Non merci', 'Pouvez-vous répéter', 'Une question']
        : ['Yes please', 'No thank you', 'Can you repeat', 'I have a question'];
    const cards = safeParseArray(cardsRaw, fallbackCards).slice(0, 4);

    return res.json({
      sessionId,
      agentLine: openingLine,
      receiverFirstReply,
      responseCards: cards,
      status: 'active',
    });
  } catch (error) {
    console.error('Error in /simulate-call-start:', error.message);
    return res.status(500).json({ error: 'Failed to start simulated call' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /simulate-caller-response
// ═══════════════════════════════════════════════════════════════════════════
app.post('/simulate-caller-response', async (req, res) => {
  const { sessionId, userChoice } = req.body;

  if (!sessionId || !userChoice) {
    return res.status(400).json({
      error: 'sessionId and userChoice are required',
    });
  }

  const session = sessions[sessionId];
  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }
  if (session.status === 'ended') {
    return res.status(400).json({ error: 'Session already ended' });
  }

  try {
    const conversationSoFar = formatTranscript(session.transcript);

    // ── Step 1: Sarra converts the user's tap into a natural spoken sentence ──
    const sarraPrompt =
      `Here is the conversation so far:\n${conversationSoFar}\n\n` +
      `${session.userName} tapped the option: "${userChoice}".\n` +
      `Convert this into a natural, complete spoken sentence that Sarra says to the receiver. ` +
      `It must fit naturally after the last thing the receiver said. ` +
      `1 sentence maximum.`;

    const agentSentence = await callOllama(sarraSYS(session), sarraPrompt);
    session.transcript.push({
      speaker: 'agent',
      text: agentSentence,
      timestamp: Date.now(),
    });

    // ── Step 2: Receiver replies ───────────────────────────────────────────
    const updatedConversation = formatTranscript(session.transcript);
    const receiverPrompt =
      `Here is the full conversation so far:\n${updatedConversation}\n\n` +
      `Sarra just said: "${agentSentence}".\n` +
      `Respond naturally as the receiver. ` +
      `Stay on topic: "${session.scenario}". ` +
      `Current turn number: ${session.turn + 1}. ` +
      (session.turn < 3
        ? `Do NOT end the call yet — there are still things to discuss.`
        : `You may end the call if the request is fully resolved by adding [CALL_COMPLETE] at the end.`
      );

    let receiverReply = await callOllama(receiverSYS(session), receiverPrompt);

    // Extract call complete flag
    let callComplete = false;
    if (receiverReply.includes('[CALL_COMPLETE]')) {
      // Only honour it after turn 3
      if (session.turn >= 3) {
        callComplete = true;
      }
      receiverReply = receiverReply.replace('[CALL_COMPLETE]', '').trim();
    }

    session.transcript.push({
      speaker: 'caller',
      text: receiverReply,
      timestamp: Date.now(),
    });
    session.turn += 1;

    // ── Step 3: Generate next response cards (skip if call complete) ───────
    let cards = [];
    if (!callComplete) {
      const updatedConv2 = formatTranscript(session.transcript);
      const cardsPrompt =
        `Full conversation:\n${updatedConv2}\n\n` +
        `The receiver just said: "${receiverReply}"\n` +
        `Generate 3-4 specific reply options for ${session.userName} ` +
        `that make sense in context of "${session.scenario}". ` +
        `Options must be concrete and actionable — avoid generic answers like "Oui" alone.`;

      const cardsRaw = await callOllama(
        cardsSYS(session.language),
        cardsPrompt,
        true
      );
      const fallback =
        session.language === 'fr'
          ? ['Oui, c\'est correct', 'Non, autre chose', 'Pouvez-vous répéter', 'Merci beaucoup']
          : ['Yes, that\'s correct', 'No, something else', 'Please repeat', 'Thank you'];
      cards = safeParseArray(cardsRaw, fallback).slice(0, 4);
    } else {
      session.status = 'ended';
    }

    return res.json({
      agentSentence,
      callerReply: receiverReply,
      responseCards: cards,
      callComplete,
      transcript: session.transcript,
      turn: session.turn,
    });
  } catch (error) {
    console.error('Error in /simulate-caller-response:', error.message);
    return res.status(500).json({ error: 'Failed to process response' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /simulate-call-end
// ═══════════════════════════════════════════════════════════════════════════
app.post('/simulate-call-end', (req, res) => {
  const { sessionId } = req.body;
  if (!sessionId) return res.status(400).json({ error: 'sessionId required' });

  const session = sessions[sessionId];
  if (!session) return res.status(404).json({ error: 'Session not found' });

  session.status = 'ended';
  return res.json({ transcript: session.transcript });
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /simulate-summary
// ═══════════════════════════════════════════════════════════════════════════
app.post('/simulate-summary', async (req, res) => {
  const { sessionId } = req.body;
  if (!sessionId) return res.status(400).json({ error: 'sessionId required' });

  const session = sessions[sessionId];
  if (!session) return res.status(404).json({ error: 'Session not found' });

  const transcriptText = formatTranscript(session.transcript);

  const sysSummary =
    `You write clear, factual summaries of phone call transcripts. ` +
    `Write in ${session.language}. ` +
    `Structure: 2-3 sentences describing what happened, ` +
    `then any confirmed actions on separate lines starting with "Action:". ` +
    `No markdown, no backticks, plain text only.`;

  const userSummary =
    `Summarize this phone call made on behalf of ${session.userName}.\n` +
    `Call purpose: ${session.scenario}\n\n` +
    `Transcript:\n${transcriptText}`;

  try {
    const summary = await callOllama(sysSummary, userSummary, false);
    return res.json({ summary });
  } catch (error) {
    console.error('Error in /simulate-summary:', error.message);
    return res.status(500).json({ error: 'Failed to summarize' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /generate-cards  (standalone — used outside of simulated calls)
// ═══════════════════════════════════════════════════════════════════════════
app.post('/generate-cards', async (req, res) => {
  const { transcript, language = 'fr' } = req.body;
  if (!transcript) return res.status(400).json({ error: 'transcript is required' });

  const cardsPrompt = `The caller just said: "${transcript}"\nGenerate 3-4 reply options.`;

  try {
    const raw = await callOllama(cardsSYS(language), cardsPrompt, true);
    const fallback = ['Oui', 'Non', 'Répéter s\'il vous plaît'];
    const cards = safeParseArray(raw, fallback).slice(0, 4);
    return res.json({ cards });
  } catch (err) {
    console.error('Error in /generate-cards:', err.message);
    return res.json({ cards: ['Oui', 'Non', 'Répéter s\'il vous plaît'] });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /summarize  (standalone)
// ═══════════════════════════════════════════════════════════════════════════
app.post('/summarize', async (req, res) => {
  const { transcript, language = 'fr' } = req.body;
  if (!transcript) return res.status(400).json({ error: 'transcript is required' });

  const sys =
    `You write concise phone call summaries. ` +
    `Write in ${language}. Plain text only, no markdown.`;
  const usr =
    `Summarize this call in 2-3 sentences. ` +
    `List confirmed actions starting with "Action:".\n` +
    `Transcript: ${transcript}`;

  try {
    const summary = await callOllama(sys, usr, false);
    return res.json({ summary });
  } catch (err) {
    console.error('Error in /summarize:', err.message);
    return res.json({ summary: 'Appel terminé.' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /speak  (ElevenLabs TTS)
// ═══════════════════════════════════════════════════════════════════════════
app.post('/speak', async (req, res) => {
  const { text, language = 'fr', voiceId } = req.body;
  if (!text) return res.status(400).json({ error: 'text is required' });

  const API_KEY  = process.env.ELEVENLABS_API_KEY;
  const VOICE_ID = voiceId || process.env.ELEVENLABS_AGENT_VOICE_ID;

  if (!API_KEY || !VOICE_ID) {
    return res
      .status(500)
      .json({ error: 'ElevenLabs credentials not configured' });
  }

  try {
    const response = await axios.post(
      `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`,
      {
        text,
        model_id: 'eleven_multilingual_v2',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75,
          style: 0.0,
          use_speaker_boost: true,
        },
      },
      {
        headers: {
          'xi-api-key': API_KEY,
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
        },
        responseType: 'stream',
      }
    );

    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Transfer-Encoding', 'chunked');
    response.data.pipe(res);
  } catch (err) {
    console.error('ElevenLabs error:', err.message);
    return res.status(500).json({ error: 'TTS failed' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// Global error handler
// ═══════════════════════════════════════════════════════════════════════════
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// ═══════════════════════════════════════════════════════════════════════════
// Startup
// ═══════════════════════════════════════════════════════════════════════════
async function checkOllama() {
  try {
    const list = await ollama.list();
    const names = list.models.map(m => m.name);
    const found = names.some(n => n.startsWith('qwen2.5') || n === MODEL);
    if (found) {
      console.log(`✓ Ollama running — model: ${MODEL}`);
    } else {
      console.warn(`⚠  Model "${MODEL}" not found. Run: ollama pull ${MODEL}`);
      console.warn(`   Available: ${names.join(', ') || 'none'}`);
    }
  } catch {
    console.error('✗ Ollama not reachable at', process.env.OLLAMA_HOST || 'http://localhost:11434');
    console.error('  Start Ollama then run: ollama pull', MODEL);
  }
}

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`\nVoiceBridge backend v2.0 listening on port ${PORT}`);
  await checkOllama();
});