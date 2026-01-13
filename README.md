# testing_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Configuration Supabase (auth)

- Copiez `.env.example` en `.env` à la racine du projet.
- Remplissez `SUPABASE_URL` et `SUPABASE_ANON_KEY` avec vos valeurs Supabase.
- Exécutez `flutter pub get` pour installer les dépendances (`supabase_flutter`, `flutter_dotenv`).

Remarque (macOS / builds) : si votre app est empaquetée (macOS / Windows / release), le répertoire courant peut ne pas être la racine du projet — dans ce cas ajoutez `.env` aux assets dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - .env
```

Ensuite vous pouvez laisser `dotenv.load()` ou le laisser en fallback (lib gère aussi `loadFromString`).

Important: ne commitez jamais `.env` contenant des clés privées.

