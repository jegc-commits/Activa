# Capturas para F-Droid

Coloca las capturas (PNG/JPG, 16:9 o 9:16) en:

- `fastlane/metadata/android/es-ES/images/phoneScreenshots/`
- `fastlane/metadata/android/en-US/images/phoneScreenshots/`

Nombres sugeridos (orden alfabético = orden de aparición):
1. `01_login.png`
2. `02_inicio_alumno.png`
3. `03_explorar.png`
4. `04_detalle_taller.png`
5. `05_mis_talleres.png`
6. `06_asistencia_instructor.png`
7. `07_panel_admin.png`

Recomendación: toma las capturas con la base demo cargada (`activa_datos_prueba.sqlite` → `~/Documentos/activa.db`) para que se vean datos reales.

## Cómo generar el APK (en una máquina con Android SDK)

```
flutter pub get
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

F-Droid re-firma el APK con su propia clave, así que no necesitas keystore propio.