# VoiceBridge 🎙️

**VoiceBridge** est une application mobile Flutter conçue pour permettre aux personnes non-verbales ou souffrant d'anxiété sociale de passer des appels téléphoniques grâce à un agent IA qui parle en leur nom.

---

## 🌟 À propos du projet

VoiceBridge cible les utilisateurs qui ont des difficultés à communiquer vocalement :
- Personnes atteintes de **SLA, autisme, mutisme sélectif, paralysie cérébrale, laryngectomie**
- Personnes souffrant d'**anxiété sociale sévère**
- **Personnes âgées** trouvant les appels téléphoniques difficiles

L'utilisateur ne parle jamais directement. Il communique via des **cartes de réponse tactiles** affichées en temps réel, et l'agent IA parle à sa place.

---

## 🏗️ Architecture du projet

```
master-faster/
├── voicebridge/              # Application Flutter (mobile + web)
│   ├── lib/
│   │   ├── core/             # Thème, routeur
│   │   ├── features/         # Écrans de l'application
│   │   │   ├── onboarding/   # Configuration du profil utilisateur
│   │   │   ├── home/         # Sélection de scénario
│   │   │   ├── call_setup/   # Configuration de l'appel
│   │   │   ├── live_call/    # Écran d'appel en direct (cœur du projet)
│   │   │   ├── post_call/    # Résumé post-appel
│   │   │   ├── emergency/    # Flux SOS
│   │   │   ├── history/      # Historique des appels
│   │   │   └── settings/     # Paramètres et profil
│   │   └── services/         # Couche métier (TTS, IA, audio, Firestore...)
│   └── pubspec.yaml
└── voicebridge-backend/       # Serveur Node.js / Express (Ollama + Gemini)
    └── index.js
```

---

## ✨ Fonctionnalités principales

| Fonctionnalité | Description |
|---|---|
| 🤖 Agent IA parle à votre place | L'IA passe l'appel et parle entièrement en votre nom |
| 🃏 Cartes de réponse dynamiques | 2 à 4 cartes générées dynamiquement selon le contexte de l'appel |
| 📞 Simulation d'appel réaliste | Scénarios variés : restaurant, médecin, livraison, support client... |
| 🚨 Bouton SOS d'urgence | Appel d'urgence autonome avec localisation et profil médical |
| 📝 Résumé post-appel | Résumé IA de ce qui a été dit et des actions à suivre |
| 📜 Historique des appels | Consultation et relecture des appels passés |
| 🔊 Synthèse vocale multiplateforme | Fonctionne sur mobile (Android/iOS) et Web |
| 🌍 Multilingue | Prise en charge de l'arabe, du français et de l'anglais (RTL inclus) |
| ♿ Accessibilité avancée | Police min. 18sp, cibles tactiles 56dp, support lecteur d'écran |

---

## 🛠️ Stack technique

### Application Flutter
| Couche | Technologie |
|---|---|
| Framework | Flutter (Dart) |
| État | Riverpod |
| Navigation | GoRouter |
| Auth & base de données | Firebase Auth + Cloud Firestore |
| Synthèse vocale (mobile) | `just_audio` + service ElevenLabs |
| Synthèse vocale (web) | HTML Audio API |
| Contacts | `flutter_contacts` |
| Géolocalisation | `geolocator` |
| HTTP | `http` |
| Variables d'environnement | `flutter_dotenv` |

### Backend Node.js
| Couche | Technologie |
|---|---|
| Serveur | Node.js + Express |
| LLM (local) | Ollama |
| LLM (cloud, fallback) | Google Gemini API |
| TTS | ElevenLabs API |
| CORS | Package `cors` |

---

## 🚀 Démarrage rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.8.1
- [Node.js](https://nodejs.org/) ≥ 18
- Un projet Firebase (Firestore + Auth activés)
- Une clé API [Google Gemini](https://aistudio.google.com/) ou [Ollama](https://ollama.com/) installé localement
- Une clé API [ElevenLabs](https://elevenlabs.io/) (pour la synthèse vocale)

---

### 1. Configurer le backend

```bash
cd voicebridge-backend
npm install
```

Créer un fichier `.env` dans `voicebridge-backend/` :

```env
GEMINI_API_KEY=your_gemini_api_key
ELEVENLABS_API_KEY=your_elevenlabs_api_key
AGENT_VOICE_ID=your_elevenlabs_agent_voice_id
CALLER_VOICE_ID=your_elevenlabs_caller_voice_id
PORT=3000
```

Démarrer le serveur :

```bash
node index.js
```

---

### 2. Configurer l'application Flutter

```bash
cd voicebridge
flutter pub get
```

Créer un fichier `.env` dans `voicebridge/` :

```env
BASE_URL=http://<votre-ip-locale>:3000
GEMINI_API_KEY=your_gemini_api_key
```

> 💡 Remplacez `<votre-ip-locale>` par l'adresse IP de votre machine (ex: `192.168.1.10`) si vous testez sur un appareil physique.

Configurer Firebase en ajoutant votre `google-services.json` (Android) et `GoogleService-Info.plist` (iOS) dans les dossiers appropriés.

Lancer l'application :

```bash
flutter run
```

---

## 📱 Écrans de l'application

### 1. Onboarding
Configuration du profil : nom, adresse, langue préférée, contact d'urgence, style de voix IA.

### 2. Accueil — Sélection de scénario
Grille de scénarios préconçus : commander un repas, prendre un rendez-vous, service client... + bouton SOS rouge bien visible.

### 3. Configuration de l'appel
Saisie du numéro, sélection dans les contacts, aperçu du script d'ouverture de l'IA.

### 4. Appel en direct *(écran principal)*
- **Transcription en temps réel** (grande police, haut contraste)
- **Cartes de réponse** générées dynamiquement par l'IA
- Indicateur animé quand l'IA parle
- Bouton "Saisir une réponse personnalisée"
- Minuterie + bouton de fin d'appel

### 5. Résumé post-appel
Résumé IA de l'appel, informations confirmées, actions à suivre.

### 6. SOS d'urgence
Appel autonome en plein écran vers les secours, avec déclaration automatique du nom, de l'adresse et du type d'urgence.

### 7. Historique des appels
Liste des appels passés avec résumé et durée.

### 8. Paramètres
Modification du profil, changement de voix/langue, options d'accessibilité.

---

## 🔌 API du backend

### `POST /simulate-call-start`
Lance la simulation d'appel. Retourne la ligne d'ouverture de l'agent, la première réponse du correspondant et les cartes initiales.

```json
{
  "scenario": "Order food from a restaurant",
  "userName": "Sarra",
  "language": "French"
}
```

### `POST /simulate-caller-response`
Génère la réponse du correspondant suite à un choix de l'utilisateur.

```json
{
  "userChoice": "Livraison",
  "transcript": "...",
  "scenario": "...",
  "language": "French"
}
```

### `POST /simulate-call-end`
Clôture la simulation et génère le résumé de l'appel.

### `GET /tts`
Synthèse vocale via ElevenLabs, retourne un flux audio MP3.

```
GET /tts?text=Bonjour&voiceId=xyz
```

---

## ♿ Accessibilité

- Police minimale **18sp** sur toute l'application
- Cibles tactiles minimales **56×56dp**
- Support du **mode haut contraste** (détection système)
- Compatibilité **lecteur d'écran** (labels sémantiques sur tous les widgets)
- Zéro geste de balayage pendant un appel — tout se fait en **un seul tap**
- Support de la **mise en page RTL** pour l'arabe

---

## 🎨 Charte graphique

| Élément | Valeur |
|---|---|
| Couleur primaire | `#534AB7` (violet foncé) |
| Couleur accent | `#1D9E75` (sarcelle) |
| Couleur urgence | `#E24B4A` (rouge) |
| Fond | `#F8F8F8` (blanc cassé) |
| Rayon des cartes | `16dp` |
| Design système | Material 3 |

---

## 📄 Licence

Ce projet est développé à titre de prototype. Tous droits réservés.

---

## 👤 Auteur

**Med Baha Chekir** — [GitHub](https://github.com/med-baha-chekir)
