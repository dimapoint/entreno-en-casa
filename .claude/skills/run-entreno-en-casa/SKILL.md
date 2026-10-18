---
name: run-entreno-en-casa
description: Compilar, correr, probar y sacar capturas de la app Flutter "Entreno en casa" (web). Usar cuando pidan "correr la app", "levantar la web", "build web", "probar en el navegador", "screenshot" o "correr los tests".
---

App Flutter (web + Android) del plan de entrenamiento de 13 semanas. En web se compila con `flutter build web`, se sirve estático y se maneja desde el navegador integrado (`mcp__Claude_Browser__*`). Los comandos corren desde la raíz del proyecto (`entreno-en-casa/`), con Bash.

## Prerrequisitos
Flutter 3.47 / Dart 3.13 y Python (solo para servir estático). No hace falta Chrome aparte: se usa el navegador del panel.

## Build y tests
```bash
flutter pub get
dart analyze
flutter test
flutter build web
```
`flutter build web` tarda unos 40 s. Avisa de una fuente `CupertinoIcons` faltante: es ruido, se ignora.

## Correr (camino del agente)
```bash
(python -m http.server 8765 --directory build/web > /dev/null 2>&1 &)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8765/
```
Debe imprimir `200`. Después, con el navegador del panel: `navigate` a `http://localhost:8765/`, esperar 3 s y `screenshot`.

Apagar el servidor al terminar:
```bash
netstat -ano | grep ":8765 " | grep LISTENING | awk '{print $5}' | sort -u | xargs -I {} taskkill //F //PID {}
```

## Manejar la app
- Flutter web pinta en canvas: `read_page` y `find` solo ven el botón "Enable accessibility". Un clic simulado desde JavaScript no lo activa y el panel no lo activa con `ref`, así que el árbol de accesibilidad no se usa.
- **Teclado:** `key Tab` enfoca el primer control y `key Return` lo pulsa. Así se llegó de la bienvenida a "Faltan 2 días".
- **Coordenadas:** `screenshot` primero y después `left_click` con `coordinate`. Sin captura previa el clic falla.
- Estado inicial: sin fecha de inicio, la pestaña Hoy muestra "Arrancar el lunes …". El estado se guarda en `localStorage` del navegador; para empezar de cero, `localStorage.clear()` con `javascript_tool` y recargar.

## Gotchas
- En emulación `mobile` los clics con `coordinate` no llegan a los botones de Flutter (el marco de la captura cambia entre 469×1015 y 750×1624). Se maneja solo con teclado: `Tab` (varias veces en una sola llamada, por ejemplo `Tab Tab`) y `Return`. El orden de foco es el visual, de arriba hacia abajo. Para sembrar datos: `localStorage.setItem('flutter.registros_v1', JSON.stringify(JSON.stringify([...])))` (el plugin guarda JSON dentro de JSON) y recargar.
- Con `resize_window` en preset `mobile` (375×812), la captura sale en un marco de 469×1015 y **recortada a la derecha**: parece un bug de la app pero no lo es. En ancho de escritorio se ve completa. Para revisar anchos de celular, confiar en los widget tests a 360 dp.
- El panel de escritorio es chico (800×450): muestra el riel lateral y el contenido cortado. Es normal.
- La primera captura después de `navigate` puede dar timeout de 5 s: reintentar.
- Sin código de sincronización la app funciona local. Con código, la web pide `/api/registros` al mismo origen; con este servidor estático da error, y es esperable.
- `resize_window` se limpia solo al terminar el turno. Volver a `desktop` al terminar.

## Troubleshooting
- `flutter pub get` falla con "failed to list directory ... ios/Flutter/ephemeral": la carpeta `ios` no está en el proyecto a propósito (no se compila desde Windows). No volver a crearla en Windows.
- `flutter test` con `impellerc failure: Failed to set access`: ocurre si el proyecto está en una carpeta virtualizada de la app de Windows Store. En `C:\Users\dimar\entreno-en-casa` no pasa.
- Los widget tests con toques usan `NoSplash` a propósito; sin eso falla el shader `ink_sparkle` en `flutter_tester`.
