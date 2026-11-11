#!/bin/bash
# Usage : depuis le dossier recherche_coran, lance  ./setup.sh
set -e
mkdir -p ../_tmp_flutter && cd ../_tmp_flutter
flutter create --org com.tonnom --project-name recherche_coran .
cd ../recherche_coran
cp -r ../_tmp_flutter/android ../_tmp_flutter/ios ../_tmp_flutter/web . 2>/dev/null || true
cp ../_tmp_flutter/analysis_options.yaml . 2>/dev/null || true
mkdir -p test
rm -rf ../_tmp_flutter
flutter pub get
echo "Termine. Lance maintenant :  flutter run"
