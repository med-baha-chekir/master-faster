# master-faster 🎙️

Monorepo du projet **VoiceBridge** — une application mobile propulsée par IA qui permet aux personnes non-verbales de passer des appels téléphoniques grâce à un agent vocal intelligent.

---

## 📦 Structure du dépôt

```
master-faster/
├── voicebridge/              # Application Flutter (Android · iOS · Web)
└── voicebridge-backend/      # Serveur Node.js / Express (Ollama + ElevenLabs)
```

---

## 🌟 Présentation

**VoiceBridge** permet à des personnes souffrant de mutisme, d'anxiété sociale ou de handicaps moteurs de passer des appels sans jamais parler elles-mêmes.

Le flux est le suivant :
1. L'utilisateur choisit un scénario (commande, rendez-vous, urgence…)
2. L'agent IA **Sarra** appelle et parle à la place de l'utilisateur
3. L'utilisateur répond en tapant des **cartes de réponse** générées dynamiquement par l'IA
4. Un **résumé IA** de l'appel est produit à la fin

---

## 🏗️ Vue d'ensemble de l'architecture

```
┌─────────────────────────────────┐      HTTP / REST
│      Flutter App (client)       │ ◄──────────────────► voicebridge-backend
│  Android · iOS · Web            │                       Node.js + Express
└─────────────────────────────────┘                              │
          │                                                      │
          │ Firebase SDK                              ┌──────────┴──────────┐
          ▼                                          │   Ollama (LLM local)│
   Firebase Auth                                    │   qwen2.5:7b         │
   Cloud Firestore                                  └──────────────────────┘
                                                             │
                                                    ┌────────┴────────┐
                                                    │  ElevenLabs TTS │
                                                    └─────────────────┘
```

---

## 🚀 Démarrage rapide

### Prérequis

| Outil | Version minimale |
|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | ≥ 3.8.1 |
| [Node.js](https://nodejs.org/) | ≥ 18 |
| [Ollama](https://ollama.com/) | dernière version |
| Compte [Firebase](https://console.firebase.google.com/) | — |
| Compte [ElevenLabs](https://elevenlabs.io/) | — |

---

### 1. Backend (`voicebridge-backend`)

```bash
cd voicebridge-backend
npm install
```

Créer `.env` :

```env
PORT=3000
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=qwen2.5:7b
ELEVENLABS_API_KEY=your_elevenlabs_api_key
ELEVENLABS_AGENT_VOICE_ID=your_agent_voice_id
ELEVENLABS_CALLER_VOICE_ID=your_caller_voice_id
```

Démarrer Ollama et télécharger le modèle :

```bash
ollama pull qwen2.5:7b
```

Lancer le serveur :

```bash
node index.js
# → VoiceBridge backend v2.0 listening on port 3000
```

Vérifier :

```bash
curl http://localhost:3000/health
```

---

### 2. Application Flutter (`voicebridge`)

```bash
cd voicebridge
flutter pub get
```

Créer `.env` :

```env
BASE_URL=http://<votre-ip-locale>:3000
GEMINI_API_KEY=your_gemini_api_key
```

> 💡 Sur appareil physique, remplacez `<votre-ip-locale>` par l'adresse IP LAN de votre machine (ex : `192.168.1.42`).

Ajouter les fichiers Firebase :
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Lancer l'application :

```bash
flutter run
```

---

## 📡 API du backend

| Méthode | Endpoint | Rôle |
|---|---|---|
| `GET` | `/health` | État du serveur et d'Ollama |
| `GET` | `/` | Index des endpoints |
| `POST` | `/simulate-call-start` | Démarre une session d'appel simulé |
| `POST` | `/simulate-caller-response` | Traite le choix de l'utilisateur et génère la suite |
| `POST` | `/simulate-call-end` | Clôture une session |
| `POST` | `/simulate-summary` | Génère le résumé IA de l'appel |
| `POST` | `/generate-cards` | Génère des cartes de réponse (usage autonome) |
| `POST` | `/summarize` | Résumé d'un transcript (usage autonome) |
| `POST` | `/speak` | Synthèse vocale ElevenLabs → stream MP3 |

### Exemple — démarrer un appel

```bash
curl -X POST http://localhost:3000/simulate-call-start \
  -H "Content-Type: application/json" \
  -d '{
    "scenario": "Commander une pizza",
    "userName": "Sarra",
    "userAddress": "12 Rue de la Paix, Tunis",
    "language": "fr"
  }'
```

```json
{
  "sessionId": "lx4f9xk2a",
  "agentLine": "Bonjour, je suis Sarra, une assistante IA...",
  "receiverFirstReply": "Bien sûr, comment puis-je vous aider ?",
  "responseCards": ["Commander une pizza", "Voir le menu", "Heures d'ouverture"],
  "status": "active"
}
```

---

## 📱 Écrans de l'application Flutter

| # | Écran | Description |
|---|---|---|
| 1 | **Onboarding** | Saisie du profil : nom, adresse, langue, style vocal, contact d'urgence |
| 2 | **Accueil** | Grille de scénarios + bouton SOS rouge |
| 3 | **Configuration de l'appel** | Numéro, aperçu du script d'ouverture IA |
| 4 | **Appel en direct** ⭐ | Transcription temps réel + cartes de réponse dynamiques |
| 5 | **Résumé post-appel** | Récapitulatif IA + actions à suivre |
| 6 | **SOS Urgence** | Appel autonome plein écran vers les secours |
| 7 | **Historique** | Liste des appels passés avec résumés |
| 8 | **Paramètres** | Modification du profil et des préférences |

---

## 🛠️ Stack technique complète

### Flutter
| Package | Rôle |
|---|---|
| `flutter_riverpod` | Gestion d'état |
| `go_router` | Navigation |
| `firebase_core` / `firebase_auth` / `cloud_firestore` | Auth + BDD |
| `just_audio` | Lecture audio (mobile) |
| `flutter_dotenv` | Variables d'environnement |
| `http` | Appels REST vers le backend |
| `geolocator` | Géolocalisation (urgences) |
| `flutter_contacts` | Sélection de contacts |
| `record` | Enregistrement micro |
| `permission_handler` | Permissions système |

### Node.js backend
| Package | Rôle |
|---|---|
| `express` | Serveur HTTP |
| `ollama` | Client LLM local |
| `axios` | Requêtes ElevenLabs |
| `cors` | Cross-Origin Resource Sharing |
| `dotenv` | Chargement de la configuration |

---

## ♿ Accessibilité

- Police minimale **18sp** dans toute l'application
- Cibles tactiles ≥ **56×56dp**
- Support du **mode haut contraste** (détection système)
- **Lecteur d'écran** supporté (labels sémantiques sur tous les widgets)
- Zéro geste de balayage pendant un appel — **un seul tap** suffit
- Support **RTL** pour l'arabe

---

## 🎨 Design

| Élément | Valeur |
|---|---|
| Couleur primaire | `#534AB7` — violet foncé |
| Couleur accent | `#1D9E75` — sarcelle |
| Couleur urgence | `#E24B4A` — rouge |
| Fond | `#F8F8F8` — blanc cassé |
| Rayon des cartes | `16dp` |
| Système de design | **Material 3** |

---

## 👤 Auteur

**Med Baha Chekir** — [github.com/med-baha-chekir](https://github.com/med-baha-chekir)