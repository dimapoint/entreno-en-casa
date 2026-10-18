# Entreno en casa

App Flutter (web + Android) para seguir el plan de entrenamiento en casa de 13 semanas: fuerza A y B, cardio, progreso y guía. Los datos se guardan en el dispositivo y se sincronizan con un Worker de Cloudflare (D1).

## Usarla

URL: https://entreno-en-casa.dimarioagus.workers.dev

- **PC:** abrí la URL en el navegador.
- **Celular:** abrí la URL en Chrome y elegí "Agregar a la pantalla de inicio" (o "Instalar app"). Queda como una app más.
- **Sincronizar:** en Ajustes de cada dispositivo pegá el mismo código de sincronización y tocá Guardar. Sin código la app funciona igual, pero cada dispositivo guarda lo suyo.

El código está en `.secretos/codigo-sync.txt` (carpeta ignorada por git). Es el secreto `TOKEN` del Worker: quien lo tenga puede leer y escribir tus datos.

## Desarrollo

```bash
flutter pub get
dart analyze
flutter test
flutter build web
```

Estructura: `lib/domain` (plan y reglas), `lib/data` (servicios y repositorio con sync), `lib/ui` (MVVM por pantalla), `api/` (Worker + D1), `test/`.

## Publicar cambios

```bash
flutter build web
cd api && bunx wrangler deploy
```

El Worker sirve la web (`build/web`) y la API (`/api/registros`) desde el mismo origen. Para cambiar el código de sincronización:

```bash
cd api && bunx wrangler secret put TOKEN
```

Después hay que cargar el código nuevo en cada dispositivo.

## Pendiente

- APK de Android: hoy se usa la web instalada. Compilar el APK pide las cmdline-tools del SDK y un JDK compatible con Gradle.
- Calentamiento y vuelta a la calma en cardio suave (el PDF dice que cada sesión los lleva).
- Escalera de progresión del PDF (velocidad antes de subir de nivel) y borrador de la sesión en curso.
