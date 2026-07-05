# Dofus Tabs (macOS) — Investigación de mercado y arquitectura técnica

> Última actualización: 2026-07-03
> Objetivo: documentar el estado del ecosistema de organizadores de ventanas multicuenta para Dofus, y dejar registrada la decisión de stack técnico para una versión nativa de macOS.

---

## 1. Contexto

El concepto "Dofus Tabs" es genérico en la comunidad: un programa que gestiona varias ventanas de Dofus (Unity o Retro) abiertas simultáneamente para multicuentas, con atajos de teclado globales para saltar entre personajes, orden por iniciativa, y (en el mejor de los casos) auto-foco cuando le toca jugar a un personaje.

**Conclusión de la investigación: no existe ninguna solución para macOS que esté a la altura de las de Windows.** El ecosistema serio está construido casi en su totalidad sobre APIs de Win32/WinUI. Lo único nativo de Mac es un proyecto experimental y abandonado.

---

## 2. Panorama competitivo

| Proyecto | Plataforma | Stack | Estado / actividad | Notas |
|---|---|---|---|---|
| [Dofus Tabs](https://www.dofustabs.com/) | Windows | No confirmado (scraping bloqueado, 403) | Activo, es el más conocido | Overlay minimalista, hotkeys globales, temas, auto-update |
| [Organizer-Dofus](https://www.organizer-dofus.com/) ([repo](https://github.com/valyriaa/DofusOrganizer)) | **Windows-only** | No especificado | Muy reciente (dic. 2025), 2 commits, 6 stars | Aún en fase temprana |
| [Dofus Organizer](https://dofus-organizer.vercel.app/) | **Windows 10/11 only** | No especificado | — | Versión instalable + portable |
| [Dorganize](https://github.com/kihw/dorganize) | Se anuncia "cross-platform" pero es de facto Windows | — | Repo devuelto 404 en julio 2026 (privado/eliminado/renombrado) | Contradicción entre el título del repo y las reseñas, que lo describen como Windows-only |
| [dofus-multi-organizer](https://github.com/Madgique/dofus-multi-organizer) (Madgique) | **Windows-only** | C# / **WinUI 3** / Windows App SDK, MSIX | Activo, release v1.1.1 | El más sofisticado técnicamente: auto-foco por turno vía `UserNotificationListener`, hotkeys directos por personaje, MVVM |
| [Organizer-dofus](https://github.com/rolljee/Organizer-dofus) (rolljee) | **macOS ARM64** | **Electron + AppleScript** (`applescript` npm + `menubar`) | Abandonado desde enero 2024, 7 commits, 1 star | Único proyecto nativo-ish de Mac. El propio autor lo describe como *"very raw but it works"* |
| [JPDevOpti/DofusTabs](https://github.com/JPDevOpti/DofusTabs) | **Windows 10/11 only** | .NET 8 | Parece ser el repo real detrás de dofustabs.com | El más completo en features de UI: overlay flotante siempre visible, iconos de clase, activar/desactivar ventana de la rotación |
| [Glutoblop/DofusSwap](https://github.com/Glutoblop/DofusSwap) | **Windows-only** | No especificado (Win32 API) | — | Más simple: solo swap por hotkey + reorder, sin overlay ni iconos |

### 2.1 Comparativa de funcionalidades

| Funcionalidad | Dofus Tabs (JPDevOpti) | Organizer-Dofus | DofusSwap | dofus-multi-organizer (Madgique) | OpenMultiBoxing (otros juegos) | **Nuestro macOS (hoy)** |
|---|---|---|---|---|---|---|
| Detección automática de ventanas | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ciclar con hotkey global | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Hotkeys directos por personaje | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| Atajos personalizables (key capture: clic y pulsa la tecla) | ✅ | ✅ | — | — | — | ✅ (`HotkeyRecorderView`, ciclo/organizar/cada posición directa) |
| Reordenar personajes a mano | ✅ (drag&drop) | ✅ (drag&drop) | ✅ (drag&drop) | — | — | ✅ (botones ▲▼, no drag&drop — ver v3) |
| Activar/desactivar una ventana de la rotación | ✅ | — | — | — | — | ✅ |
| Icono de clase de Dofus junto al nombre | ✅ | — | — | — | — | ❌ a propósito (sin acceso legítimo a assets de Ankama); icono genérico de repuesto |
| Miniatura/preview real de la ventana | — | — | — | — | — | ✅ (nadie más lo tiene) |
| Overlay flotante siempre visible | ✅ | — | — | — | — | ❌ (pendiente, v3) |
| Arranque automático al iniciar sesión | — (no confirmado) | ✅ | — | — | — | ✅ (`SMAppService`, solo desde el `.app` empaquetado) |
| Tileado/organización automática en pantalla | — | — | — | — | ✅ (snap a grid, nudge 1px, stay-on-top por ventana) | ✅ (cuadrícula automática; sin snap manual ni multi-monitor todavía) |
| Auto-foco al turno | — | ✅ (Retro) | — | ✅ (Retro, vía notificaciones) | — | **N/A — lo resuelve el propio Dofus**, no hace falta construirlo (ver §5.5) |
| Input broadcasting (repetir tecla en varias ventanas) | — | — | — | — | Algunas herramientas lo ofrecen | ❌ descartado a propósito (zona gris de ToS) |

**Lectura rápida:** las tres funcionalidades que más se repiten entre competidores y que no tenemos son reordenar a mano, activar/desactivar ventanas de la rotación, y arranque automático — son la brecha básica a cerrar. El tileado de ventanas al estilo OpenMultiBoxing no lo tiene ninguna herramienta de Dofus (ni Windows ni Mac) tan desarrollado, así que sería el diferenciador más fuerte si se construye bien. Las miniaturas reales de ventana (en vez de icono de clase estático) tampoco las tiene nadie — ya la tenemos nosotros.

---

## 3. Cómo funcionan las soluciones existentes por dentro

### 3.1 Windows — Madgique/dofus-multi-organizer (la más madura)

Encontré un `CLAUDE.md` público en su repo con notas de arquitectura muy detalladas. Resumen de lo relevante:

- **Detección de ventanas**: `EnumWindows` (Win32) + filtro por clase de ventana:
  - Dofus Unity → clase `UnityWndClass`
  - Dofus Retro → clase `Chrome_WidgetWin_1` (cliente x64, Chromium embebido) + filtro de proceso `dofus*` para no capturar Chrome/Edge/Discord
- **Parseo del título de ventana** para extraer nombre de personaje y clase:
  - Unity: `"NombrePersonaje - Clase - Version - Release"` (split por `" - "`, usar el *primer* separador, no el último)
  - Retro: `"NombrePersonaje - Dofus Retro v1.47.20"`
- **Foco de ventana**: `AttachThreadInput` + `SetForegroundWindow` (hack clásico de Win32 para robar el foco desde un proceso en segundo plano)
- **Hotkeys globales**: `RegisterHotKey` vía P/Invoke manual (CsWin32 no genera bien `SetWindowLongPtrW`), con IDs reservados: `1`=siguiente, `2`=anterior, `100+index`=hotkey directo por ventana
- **⭐ Auto-foco en el turno** (la feature diferenciadora): usa `Windows.UI.Notifications.Management.UserNotificationListener` para interceptar las notificaciones toast que genera Dofus Retro con formato `"[Personaje] - Dofus Retro v..."`, y trae automáticamente esa ventana al frente. Esto **no tiene equivalente conocido en ninguna herramienta de Mac**.
- Arquitectura MVVM + DI, distribución vía MSIX firmado con certificado propio.

### 3.2 macOS — rolljee/Organizer-dofus (la única existente)

Código fuente revisado directamente:

- **Detección de instancias**: `ps aux | grep './Dofus.app/Contents/MacOS/Dofus'` vía `child_process.exec` — extremadamente frágil (depende del path exacto del binario, no filtra bien, no distingue Unity/Retro)
- **Cambio de foco**: AppleScript ejecutado vía `applescript` npm, literalmente:
  ```applescript
  tell application "System Events"
    set frontmost of every process whose unix id is <pid> to true
  end tell
  ```
- **Nombre de ventana**: otro AppleScript (`name of first window of process`) recortando el string en el primer `-`
- Solo un atajo (`Cmd+1`) que cicla secuencialmente; no hay atajos directos por personaje, no hay orden por iniciativa real, no hay auto-foco por turno, no hay persistencia de configuración robusta.
- Es una app Electron envuelta en `menubar` (barra de menú), no una app nativa de verdad — de ahí el consumo de recursos y la sensación de "no está pulido" que comentas.

---

## 4. Gap de mercado

1. **Nadie ha construido una app nativa de macOS** (Swift/AppKit) para esto. Todo lo que existe en Mac es un wrapper de Electron + AppleScript, sin mantenimiento desde 2024.
2. **La feature más valiosa de la competencia (auto-foco por turno)** depende de una API exclusiva de Windows (`UserNotificationListener` leyendo toasts). No es portable directamente — habría que investigar una vía equivalente en macOS (ver §5.4).
3. Detección de ventanas por AppleScript/`System Events` es lenta y limitada (no diferencia bien multi-ventana por proceso, no da acceso a title-change events en tiempo real). La Accessibility API nativa (`AXUIElement`) es muy superior y es exactamente lo que usan los gestores de ventanas serios de macOS (Rectangle, Swindler, etc.).

---

## 5. Stack técnico recomendado para macOS

### 5.1 Decisión: Swift nativo (AppKit/SwiftUI), no Electron

| Criterio | Electron + AppleScript (como rolljee) | Swift nativo + Accessibility API |
|---|---|---|
| Rendimiento / RAM | Alto consumo (Chromium embebido) | Mínimo, apto para menu bar app |
| Latencia de cambio de ventana | AppleScript es lento (cientos de ms, spawnea `osascript`) | `AXUIElementSetAttributeValue` es prácticamente instantáneo |
| Eventos en tiempo real (título cambia, ventana se cierra) | No hay forma limpia sin polling | `AXObserver` + notificaciones (`kAXTitleChangedNotification`, `kAXUIElementDestroyedNotification`) |
| Confianza del usuario al pedir permiso de Accesibilidad | Un `.app` de Electron sin firmar/notarizar genera desconfianza | App firmada y notarizada da más confianza para conceder el permiso crítico |
| Tamaño de descarga | ~150-200 MB (Electron) | Unos pocos MB |
| Distribución / autoupdate | electron-updater | [Sparkle](https://sparkle-project.org/) (estándar de facto en macOS) |

Con el nombre del proyecto y que el target es Mac-only, no tiene sentido cargar con Electron. Recomiendo **Swift + SwiftUI para la UI (ventana de settings) y AppKit para la pieza de menu bar (`NSStatusItem`)**, con toda la lógica de ventanas sobre accessibility APIs nativas.

### 5.2 Detección de instancias de Dofus

- `NSWorkspace.shared.runningApplications` filtrando por `bundleIdentifier` (Dofus Unity y Dofus Retro tendrán bundle IDs distintos — hay que inspeccionarlos con un `Dofus.app` real, o filtrar por `localizedName == "Dofus"` + `executableURL` conteniendo `Dofus.app`)
- Para multicuenta, cada ventana adicional en macOS normalmente es **una ventana más del mismo proceso**, no un proceso nuevo (a diferencia de Windows donde cada cliente es su propio proceso) — esto es una diferencia importante de arquitectura: en Mac probablemente haya que enumerar **ventanas** de un único `NSRunningApplication`, no procesos distintos. Hay que validar esto empíricamente abriendo 2-3 cuentas.
- Enumeración de ventanas: `AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, ...)` para obtener el array de `AXUIElement` por proceso.

### 5.3 Parseo de título y foco de ventana

- Igual que en Windows, leer `kAXTitleAttribute` de cada `AXUIElement` ventana y parsear `"Personaje - Clase - Version"` (mismo formato que ya documentó Madgique para Unity — probablemente idéntico en Mac, a confirmar).
- Foco: `AXUIElementSetAttributeValue(windowRef, kAXMainAttribute, true)` + `AXUIElementPerformAction(windowRef, kAXRaiseAction)` + `app.activate(options: [])` (vía `NSRunningApplication`). Esto sustituye por completo al AppleScript lento del proyecto de rolljee.

### 5.4 Hotkeys globales

- Opción recomendada: librería [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) de Sindre Sorhus (Swift, muy usada en apps de menu bar como Rectangle/CleanShot) — da UI de captura de atajo gratis y maneja el registro a bajo nivel.
- Alternativa más manual: `Carbon.HIToolbox` `RegisterEventHotKey` (API antigua pero sigue siendo la vía estándar para hotkeys verdaderamente globales en macOS).
- Diseño de atajos: igual que Madgique — ciclar siguiente/anterior + atajos directos por personaje (`Cmd+1`...`Cmd+9`), configurables.

### 5.5 Auto-foco por turno — descartado, ya lo hace el propio Dofus

**Corrección (2026-07-03):** esta sección asumía que había que replicar en macOS lo que Madgique resuelve en Windows leyendo notificaciones toast. Confirmado por el usuario: **Dofus ya trae esto de fábrica** — con varias cuentas abiertas, el propio cliente pone en primer plano la ventana del personaje al que le toca jugar. No hace falta construir nada para esto; deja de ser el diferenciador a perseguir. Se mantiene el apartado solo como registro de que se investigó y por qué se descartó.

### 5.6 Permisos y distribución

- Requiere permiso de **Accesibilidad** (`AXIsProcessTrusted`) — el usuario debe añadir la app en Ajustes del Sistema → Privacidad y Seguridad → Accesibilidad.
- Firma de código + notarización de Apple (Developer ID) recomendable para evitar el aviso de Gatekeeper y generar confianza al pedir el permiso de accesibilidad (crítico dado que es un permiso sensible).
- Auto-update: **Sparkle** (framework estándar, usado por casi todas las utilidades de menu bar de macOS).
- Empaquetado: `.app` nativo, sin necesidad de instalador complejo — arrastrar a `/Applications` es suficiente, como la mayoría de utilidades de este tipo (Rectangle, AlDente, etc.)

### 5.7 Resumen del stack propuesto

```
Lenguaje:       Swift 6
UI:             SwiftUI (ventana de settings) + AppKit (NSStatusItem para menu bar)
Ventanas:       Accessibility API (AXUIElement, AXObserver) — no AppleScript
Hotkeys:        KeyboardShortcuts (Sindre Sorhus) o Carbon RegisterEventHotKey
Persistencia:   UserDefaults o un JSON en ~/Library/Application Support/DofusTabs/
Auto-update:    Sparkle
Distribución:   .app notarizado, Developer ID, sin App Store (necesita permisos de Accesibilidad incompatibles con sandboxing estricto)
```

---

## 6. Roadmap de features sugerido

**MVP**
- Detección de ventanas Dofus Unity y Retro (validar si son procesos separados o ventanas del mismo proceso en Mac)
- Listado de personajes en menu bar
- Ciclar siguiente/anterior con hotkey global
- Hotkeys directos por personaje
- Persistencia de orden manual (drag & drop, como en la versión Windows)

**v2 — hecho (2026-07-03)**
- [x] Tileado/organización de ventanas en pantalla (`Cmd+0`, cuadrícula sobre la pantalla principal) — diferenciador real, ya que el auto-foco por turno lo resuelve el propio juego (ver §5.5)
- [x] Ventana de ajustes: reordenar personajes a mano (▲▼), excluir ventanas de la rotación, arrancar al iniciar sesión (`SMAppService`)
- [x] Icono propio de la app (antes era el texto "DT")
- [ ] Orden automático por iniciativa — pendiente
- [ ] Temas / personalización visual — pendiente

**v3**
- Overlay flotante siempre visible (modo "barra de tabs"), alternativa al menú desplegable — es lo único de la comparativa de §2.1 que sigue sin cubrirse
- Soporte multi-monitor (el tileado actual solo usa `NSScreen.screens.first`)
- Perfiles guardados (distintas composiciones de cuentas)
- Internacionalización (ES/EN/FR, siguiendo el patrón de recursos localizados que ya usa Madgique)
- Reordenar con drag & drop de verdad en vez de botones ▲▼ (se descartó drag&drop en la ventana de Ajustes por fiabilidad del gesto en SwiftUI/macOS sin poder probarlo interactivamente)

---

## 7. Fuentes

- [Dofus Tabs](https://www.dofustabs.com/)
- [Organizer-Dofus (organizer-dofus.com)](https://www.organizer-dofus.com/)
- [Dofus Organizer (Windows-only, Vercel)](https://dofus-organizer.vercel.app/)
- [valyriaa/DofusOrganizer](https://github.com/valyriaa/DofusOrganizer)
- [kihw/dorganize](https://github.com/kihw/dorganize) (repo no accesible en julio 2026)
- [Madgique/dofus-multi-organizer](https://github.com/Madgique/dofus-multi-organizer) — [CLAUDE.md con notas de arquitectura](https://raw.githubusercontent.com/Madgique/dofus-multi-organizer/main/CLAUDE.md)
- [rolljee/Organizer-dofus](https://github.com/rolljee/Organizer-dofus) — único proyecto nativo-ish de macOS
- [Swindler — macOS window management library for Swift](https://github.com/tmandry/Swindler)
- [KeyboardShortcuts — Sindre Sorhus](https://github.com/sindresorhus/KeyboardShortcuts)
- [Sparkle — auto-update framework para macOS](https://sparkle-project.org/)
- [Dofus forum — Multiaccounting Techniques](https://www.dofus.com/en/forum/2-general-discussion/330213-multiaccounting-techniques)
