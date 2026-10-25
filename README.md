<div align="center">

# 🎨 Artora

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

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/amazing-feature`
3. Follow the architecture and lint rules above, and run `flutter analyze` and `flutter test`
4. Commit using [Conventional Commits](https://www.conventionalcommits.org): `feat: add follow button`
5. Push the branch and open a Pull Request

## Contributors

Thanks to everyone who helps build Artora.

<a href="https://github.com/<your-username>/artora/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=<your-username>/artora" alt="Contributors" />
</a>

## License

No license has been chosen yet. Add a `LICENSE` file (for example MIT) and update the badge above.

---

<div align="center">
Made with ❤️ for independent artists.
</div>
