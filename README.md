<div align="center">

# 🎨 Artora

<img width="125" height="125" alt="applogo" src="https://github.com/user-attachments/assets/7f73e378-e647-49e2-80b5-7b4799a79adc" />


**A home for independent artists to share their work, connect with peers, and grow together.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.5-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00B8D4)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#getting-started)
[![Status](https://img.shields.io/badge/Status-MVP%20in%20development-orange)](#roadmap)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)
[![License](https://img.shields.io/badge/License-TBD-blue.svg)](#license)

</div>

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Roadmap](#roadmap)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Contributing](#contributing)
- [Contributors](#contributors)
- [License](#license)

## About

Independent artists often work in isolation, and the big social platforms bury their work under algorithms built for everything except art. **Artora** is a focused community where artists publish their portfolios, discover fellow creators, and build a network that helps everyone improve and get noticed.

Longer term, Artora aims to become a place where artists can also earn from their craft: through commissions, direct sales, and royalties.

## Features

### MVP (current focus)

- 🖼️ **Share artwork**: upload and showcase your pieces in a personal portfolio
- 👤 **Artist profiles**: bio, portfolio and activity in one place
- 🤝 **Follow artists**: follow other creators and keep up with their latest work
- 🔐 **Authentication**: secure sign-up and sign-in powered by Supabase
- 🌍 **Localization**: English and Japanese out of the box
- 🌙 **Dark theme**: a single, art-first dark UI built on Material 3

### Future USPs

- 📝 **Artwork requests**: users can post requests and commission artists
- 💰 **Sell artwork**: artists can list and sell their work directly
- 👑 **Royalties for premium members**: premium artists receive royalties on their work

## Roadmap

- [x] Project scaffold, theming, routing, and localization
- [ ] Authentication and onboarding
- [ ] Artist profile and portfolio
- [ ] Artwork upload and feed
- [ ] Follow / unfollow artists
- [ ] Artwork requests (commissions)
- [ ] Marketplace: selling artwork
- [ ] Premium tier and royalties

## Tech Stack

| Area | Choice |
|------|--------|
| Framework | Flutter / Dart |
| Architecture | Feature-first |
| State management | Riverpod (manual providers, no codegen) |
| Navigation | go_router |
| Backend | Supabase (Auth, Postgres with RLS, Storage) |
| Networking | Dio |
| Local storage | Hive, SharedPreferences, Flutter Secure Storage |
| Localization | easy_localization (`en`, `ja`) |
| Responsive UI | flutter_screenutil |
| Config | flutter_dotenv |

## Architecture

Artora uses a **feature-first** layout. Each feature is self-contained and split into `data`, `domain` and `presentation` layers. Code shared across features lives only in `shared/`.

```text
lib/src/
├── features/<feature>/
│   ├── data/          # datasources, models, repository implementations
│   ├── domain/        # entities, repository contracts, use cases
│   └── presentation/  # screens, widgets, Riverpod providers
├── shared/            # cross-feature widgets and utilities
├── routing/           # central go_router configuration
├── services/          # singleton services (HTTP, storage, ...)
└── theme/             # design tokens and theme
```

Key conventions:

- Async UI state is modeled with sealed `RequestState<T>`; session state with sealed `SessionState`.
- All backend access goes through repositories and services, never from widgets.
- All routes are declared in `lib/src/routing/app_router.dart`.

See [architecture.md](architecture.md), [AGENTS.md](AGENTS.md) and [DESIGN.md](DESIGN.md) for more detail.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=3.5.0 <4.0.0`)
- A [Supabase](https://supabase.com) project (URL and anon key)
- Android Studio / Xcode for device emulators

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/artora.git
cd artora

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# then fill in your Supabase URL and anon key

# 4. Generate code (Hive adapters, etc.)
dart run build_runner build --delete-conflicting-outputs

# 5. Run the app
flutter run
```

> Never commit a `.env` file containing real secrets. Platform and console setup steps live in [SETUP.md](SETUP.md).

## Project Structure

| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry point and initialization order |
| `lib/src/features/` | Feature modules |
| `lib/src/shared/widgets/ui/` | Reusable `App*` UI kit |
| `lib/src/routing/app_router.dart` | Central route table |
| `assets/translations/` | Localization JSON files |
| `test/` | Unit and widget tests |

## Development Workflow

```bash
flutter analyze      # static analysis
flutter test         # run tests
dart format .        # format code
```

After editing translations in `assets/translations/*.json`:

```bash
flutter pub run easy_localization:generate -S assets/translations -O lib/src/core/i18n -o locale_keys.g.dart
```

## UI/UX
<img width="1536" height="1024" alt="mockup-3" src="https://github.com/user-attachments/assets/94e5910f-9d1f-410f-9042-c45cc8aaa0c9" />
<img width="1536" height="1024" alt="mockup-4" src="https://github.com/user-attachments/assets/dee11863-f215-4e6d-82ef-a602e3e95200" />
<img width="1536" height="1024" alt="mockup-5" src="https://github.com/user-attachments/assets/456b3b57-86b5-4b07-8979-14b99184ddbb" />
<img width="1536" height="1024" alt="mockup-6" src="https://github.com/user-attachments/assets/1b372229-24b0-4637-9258-17fe3064bbc4" />
<img width="1536" height="1024" alt="mockup-7" src="https://github.com/user-attachments/assets/fc371dd7-0a8f-4987-b692-4ecf838fb8be" />
<img width="1536" height="1024" alt="mockup-8" src="https://github.com/user-attachments/assets/55bb3866-08ba-49e8-9373-018813124b7a" />
<img width="1536" height="1024" alt="mockup-shared" src="https://github.com/user-attachments/assets/82422a74-a7ea-4a12-b773-8530bbd7a357" />
<img width="1536" height="1024" alt="mockup-1" src="https://github.com/user-attachments/assets/621f7566-314f-4c14-8583-1eb771cd0ecc" />
<img width="1536" height="1024" alt="mockup-2" src="https://github.com/user-attachments/assets/1378ca2a-f2ec-4985-b4e4-8fce6706656b" />


## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/amazing-feature`
3. Follow the architecture and lint rules above, and run `flutter analyze` and `flutter test`
4. Commit using [Conventional Commits](https://www.conventionalcommits.org): `feat: add follow button`
5. Push the branch and open a Pull Request

## Contributors

Thanks to everyone who helps build Artora.

<a href="https://github.com/Kuntal-Gain/artora/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Kuntal-Gain/artora" alt="Contributors" />
</a>

---

<div align="center">
Made with ❤️ for independent artists.
</div>
