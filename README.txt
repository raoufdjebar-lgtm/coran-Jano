RECHERCHE CORAN - application Flutter
=====================================

Fonctions : recherche d'un mot (arabe), nombre de repetitions par sourate,
options : ignorer le tachkil, ignorer les points, mot entier / contient.

INSTALLATION (Windows, Mac ou Linux)
------------------------------------
1. Installe Flutter + Android Studio (flutter.dev) puis verifie : flutter doctor
2. Dezippe ce dossier.

Methode A (la plus simple) :
   flutter create --org com.tonnom recherche_coran_new
   Copie ensuite dans recherche_coran_new :
      - lib/main.dart       (remplace l'existant)
      - pubspec.yaml        (remplace l'existant)
   cd recherche_coran_new
   flutter pub get
   flutter run

Methode B (Mac/Linux) : ./setup.sh puis flutter run

3. Verifie que android/app/src/main/AndroidManifest.xml contient, juste
   avant <application :
      <uses-permission android:name="android.permission.INTERNET"/>
   (flutter create l'ajoute normalement pour les builds debug ; verifie-la
   avant de creer la version finale.)

CREER L'APK
-----------
   flutter build apk --release
   Fichier : build/app/outputs/flutter-apk/app-release.apk

PUBLIER SUR GOOGLE PLAY
-----------------------
   flutter build appbundle --release   (fichier .aab)
   Compte developpeur Google Play : 25 $ une seule fois.
   Change le nom de package (com.tonnom...) avant de publier.

SOURCE DES DONNEES : API Al-Quran Cloud (alquran.cloud), texte uthmani.
