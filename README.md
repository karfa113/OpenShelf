<div align="center">

# 📚 OpenShelf

**A personal library tracker built with Flutter & Firebase**

*Track what you've read. Plan what's next. Own your reading life.*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=flat-square&logo=firebase)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

</div>

---

## ✨ Features

- **Library** — Add books with title, author, publisher, pages, genres, and notes
- **TBR (To Be Read)** — Separate shelf for books you plan to read
- **Read tracking** — Mark books as read with a date, unmark anytime
- **Stats dashboard** — Total books, pages read, books read this month
- **Search & filter** — Filter by author, publisher, genre, read status, or this month
- **Sort** — By date added, name, or page count
- **PDF export** — Generate a beautifully typeset library manual as a PDF
- **Import / Export** — Back up and restore your library as JSON
- **Cloud sync** — Data syncs across devices via Firebase Firestore
- **Auth** — Email/password and Google Sign-In
- **Dark & light theme**

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State management | Provider |
| Database | Cloud Firestore |
| Auth | Firebase Auth + Google Sign-In |
| PDF generation | `pdf` + `printing` |
| Fonts | Space Grotesk · Inter (Google Fonts) |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.12.0`
- A Firebase project with Firestore and Authentication enabled

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/your-username/openshelf.git
cd openshelf
```

**2. Configure Firebase**

Install the FlutterFire CLI and run:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This generates `lib/firebase_options.dart` and `android/app/google-services.json`.

**3. Set Firestore security rules**

In the Firebase Console → Firestore → Security tab:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**4. Install dependencies & run**
```bash
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
lib/
├── models/         # Book data model
├── providers/      # LibraryProvider, AuthProvider, ThemeProvider
├── screens/        # Home, Library, TBR, BookDetail, AddBook, Settings, Login
├── services/       # Firestore & local storage, auth
├── widgets/        # BookTile, GenreChipInput, FilterSheet, StatTile
├── theme/          # Colors & theme
└── main.dart
```

---

## 📄 License

MIT © 2026 OpenShelf
