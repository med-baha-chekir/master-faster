# VoiceBridge Backend

Node.js/Express backend for the VoiceBridge Flutter app. Provides AI-powered response card generation and call summarization using the Google Gemini API.

## Prerequisites

- Node.js 18+
- A Google Gemini API key (free tier available at [Google AI Studio](https://aistudio.google.com))

## Setup

```bash
npm install
```

## Environment Variables

Create a `.env` file in this directory with the following variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google Gemini API key | ✅ Yes |
| `PORT` | HTTP server port (default: 3000) | No |

## Running

```bash
node index.js
```

## Endpoints

### `POST /generate-cards`

Generates 3 short tap-to-reply response cards based on the latest call transcript.

**Request:**
```json
{ "transcript": "Will that be pickup or delivery?" }
```

**Response:**
```json
{ "cards": ["Pickup", "Delivery", "Ask for details"] }
```

### `POST /summarize`

Generates a concise 2-3 sentence summary of the full call transcript.

**Request:**
```json
{ "transcript": "Customer ordered a pizza for delivery." }
```

**Response:**
```json
{ "summary": "A pizza was ordered for delivery..." }
```

## Rate Limiting

An in-memory guard limits Gemini calls to 8 per minute to stay within the free-tier limit of 10 RPM. When the limit is reached, fallback values are returned instead of calling the API.
