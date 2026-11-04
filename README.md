# UMBRAL — Defensa del asentamiento

**Iteración narrativa:** F5 → Iniciar historia. WASD/flechas, Shift para correr y clic en NPC/objetos. Continuar historia confirma el avance, reproduce la cinemática y abre el combate 8×8 con consecuencias de decisiones. El selector táctico de escenarios ya no es visible. Consultar docs/ITERATION3.md y docs/CREATING_MISSIONS.md; los apartados históricos sobre selección de escenarios se mantienen como referencia de pruebas.

Prototipo jugable de combate táctico de ciencia ficción, en español. Dos gemelos defienden a un civil frente a un soldado y un capturador. Presentación rural decadente con atlas de pixel art originales generados para el proyecto, personajes independientes, retratos y HUD ornamental. Sin plugins ni dependencias externas de ejecución.

## Abrir y jugar

1. Usa Godot **4.2.2 o posterior de la rama 4.x**, edición estándar; no hace falta .NET.
2. Importa `project.godot` en el gestor de proyectos.
3. Abre el proyecto y pulsa **F5**.
4. Pulsa **Iniciar historia** para explorar. El combate 8×8 comienza al confirmar **Continuar historia** y avanzar la cinemática. El 10×10 es únicamente un fixture de pruebas.

Resolución lógica: **960 × 540**. Ventana inicial: 1280 × 720; mínimo 960 × 540. El lienzo escala conservando la proporción. Renderizador Compatibility y filtro nearest para el arte. Cámara fija: se ve todo el tablero. No se requiere descargar arte ni instalar complementos. Para distribuir un ejecutable Windows, instala las plantillas de exportación correspondientes a tu versión de Godot y utiliza Proyecto → Exportar → Windows Desktop. Esta entrega contiene el proyecto fuente, no un ejecutable exportado.

## Controles

| Entrada | Acción |
|---|---|
| Clic izquierdo en Gael o Lira | Seleccionar personaje |
| Clic en casilla azul | Recorrer la ruta previsualizada, una vez por fase |
| Ataque/Golpe contundente y clic en objetivo | Ver pronóstico; segundo clic o Enter confirma |
| Habilidad y clic en objetivo resaltado | Curar o aplicar interferencia |
| Clic en enemigo | Inspeccionar estadísticas y rangos sin controlarlo |
| WASD / flechas | Desplazar cursor del tablero |
| Enter / Espacio | Confirmar casilla o activar botón enfocado |
| Tab | Activar/desactivar peligro combinado enemigo |
| Q / Mayús+Q | Recorrer botones; Enter los activa (Tab también navega en pausa/menús) |
| M | Modo mover / seleccionar |
| X | Preparar ataque básico |
| 1 | Primera habilidad: Golpe contundente / Interferencia |
| 2 | Primeros auxilios de Lira |
| G | Defender |
| E | Esperar: ceder acción y movimiento restantes |
| F | Finalizar toda la fase aliada |
| H / botón Ayuda | Abrir instrucciones completas y pausar el combate |
| Z / Deshacer movimiento | Regresar al origen si aún no se ha realizado una acción |
| Clic derecho / Escape | Cancelar acción; después selección; sin selección, pausa |
| Ratón sobre una unidad | Consultar nombre, estadísticas y estados |

Se puede jugar solo con ratón o solo con teclado. Para elegir acciones con teclado, Q enfoca los botones y Enter los activa; después utiliza las flechas y Enter para indicar el objetivo. En un ataque, el primer Enter prepara el objetivo y el segundo confirma el daño mostrado. Las entradas de teclado repetidas y las confirmaciones durante una animación se ignoran.

La ruta dorada sigue el mismo BFS que el movimiento real. Azul indica destinos de movimiento y rojo fuerte el ataque desde la posición actual; ambos pueden coincidir mediante relleno y contorno. Al inspeccionar enemigos, ámbar indica movimiento y rojo tenue amenaza tras desplazarse; el contorno dorado distingue posiciones de captura. Tab superpone la amenaza de todos los enemigos vivos y puede mantenerse desactivado. Los enemigos bajo interferencia solo amenazan desde su posición actual.

**Audio:** pausa → Ajustes de audio. Volumen Master, Music, SFX y UI, con silenciamiento independiente de efectos/interfaz. Las preferencias se guardan en `user://audio.cfg`. No hay música; los quince efectos son síntesis original incluida en `assets/audio`, regenerable con `python tools/generate_audio.py` (solo para desarrollo).

## Reglas y ayuda

- Gael: 60 PV, ataque 12, defensa 4, movimiento 4. Lira: 40 PV, ataque 6, defensa 2, movimiento 4.
- Soldado: 40 PV, ataque 10, defensa 3, movimiento 3. Capturador: 30 PV, ataque 7, defensa 2, movimiento 3. Civil neutral inmóvil: 25 PV.
- Cada gemelo mueve una vez y realiza una acción una vez, en cualquier orden. Después de atacar o defender puede seguir moviéndose si conserva el movimiento. La fase termina automáticamente cuando todos los gemelos vivos han gastado ambos recursos; también puedes finalizarla con F.
- Ataque básico: alcance ortogonal 1, `max(1, ataque − defensa)`.
- Golpe contundente: `max(1, floor(ataque × 1.5) − defensa)`. Bloquea las **dos fases aliadas completas siguientes**. Usado en T01, vuelve en T04.
- Interferencia: alcance Manhattan 3; bloquea movimiento y captura durante la próxima activación enemiga, pero permite atacar a un gemelo adyacente. Primeros auxilios: alcance 2, cura 12 PV a cualquiera de los gemelos vivos, incluida Lira, sin superar su máximo. Ambas bloquean **una fase aliada completa siguiente**: usadas en T01, vuelven en T03.
- El texto «lista T04» indica el turno de recuperación. Las habilidades en enfriamiento tienen el botón desactivado.
- Defender reduce el daño recibido a `ceil(daño × 0.5)` hasta el inicio de la siguiente fase aliada.
- Las unidades bloquean el paso a todos los equipos. Los obstáculos también bloquean. Las habilidades usan distancia Manhattan y no necesitan línea de visión.
- El capturador busca una casilla ortogonal adyacente al civil. Cada activación puede sumar **una** captura; con 3/3 pierdes. El progreso se conserva aunque se aleje. Interferencia retrasa su captura.
- Victoria: ambos enemigos derrotados. Derrota: ambos gemelos caídos o captura 3/3. Un gemelo puede continuar si el otro cae.

Consejo inicial: acerca a Gael a la zona central e interfiere al capturador con Lira. Prioriza detener la captura antes de combatir al soldado. El civil no recibe ataques de esta IA.

## Estructura

- `scenes/main.tscn`: escena de entrada.
- `scripts/main.gd`: menús, composición de UI, controles y secuencia asíncrona de fase enemiga.
- `scripts/board_view.gd`: tablero, siluetas pixeladas, cursor, resaltados, desplazamiento visual y textos flotantes.
- `scripts/settlement_view.gd`: suelo y piezas ambientales en capas; usa regiones del atlas, no la imagen de referencia como fondo.
- `scripts/art_library.gd`: regiones de atlas para terreno, objetos, sprites y retratos.
- `scripts/threat_system.gd`: rangos actuales, amenazas por rutas y peligro global.
- `scripts/audio_manager.gd`, `default_bus_layout.tres`: reproducción por buses y preferencias.
- `scripts/ornament_panel.gd`, `tactical_action_button.gd`: marcos e iconos originales dibujados por código.
- `assets/art/`: dos atlas PNG integrados; procedencia y prompts en `docs/ART.md`.
- `docs/REDESIGN.md`: cambios del rediseño, validación y límites visuales.
- `docs/screenshots/`: capturas de validación de Godot.
- `scripts/battle_manager.gd`: comandos de combate, selección, validación y condiciones de fin.
- `scripts/unit.gd`: estado individual; estadísticas reutilizables en `data/units/*.tres`.
- `data/maps/`, `data/missions/`, `data/objectives/`: recursos de mapas, apariciones y condiciones.
- `scripts/data/`, `objective_system.gd`, `mission_catalog.gd`, `board_layout.gd`, `map_visual.gd`: configuración, objetivos y presentación compartida.
- `AGENTS.md`: instrucciones permanentes para futuras tareas.
- `docs/CREATING_MAPS.md`: creación de escenarios sin copiar combate.
- `docs/ARCHITECTURE_TESTING.md`: informe vigente de refactorización y pruebas.
- `scripts/grid_manager.gd`, `movement_system.gd`: geometría y BFS.
- `scripts/combat_system.gd`, `ability_system.gd`: daño, defensa, curación, interferencia y enfriamientos.
- `scripts/turn_manager.gd`, `enemy_ai.gd`, `capture_system.gd`, `battle_results.gd`: fases, decisiones y resultados.
- `tests/`: comprobaciones de reglas, escenas y partidas completas.
- `docs/ARCHITECTURE.md`: decisiones de diseño y puntos de ampliación.
- `docs/TESTING.md`: resultados reales y límites de validación.

## Pruebas

Desde la carpeta del proyecto, con el ejecutable de Godot en PATH:

```powershell
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --script res://tests/test_matches.gd
godot --headless --path . --script res://tests/test_presentation.gd
godot --headless --path . --script res://tests/test_iteration2.gd
godot --headless --path . --script res://tests/test_maps.gd
godot --path . --script res://tests/test_visual.gd
godot --path . --script res://tests/test_maps_visual.gd
```

La primera orden registra las clases en una copia recién descargada; el editor también lo hace al importar el proyecto. Las suites finalizan con código 0 si todo pasa. Las dos últimas órdenes abren ventanas de prueba, guardan doce y ocho capturas, respectivamente, y se cierran automáticamente. Consulta `docs/ARCHITECTURE_TESTING.md` para el informe vigente.

## Límites del prototipo

Dos escenarios configurados con el mismo encuentro y sistemas; sin exploración, inventario, experiencia, guardado de partidas ni historia completa. Audio sintetizado sencillo, sin música. Arte generado con posibles irregularidades de detalle; animaciones sobre sprites estáticos, sin spritesheets direccionales completas. La duración de 3–5 minutos sigue pendiente de medición con jugadores. No se ha validado una exportación Windows independiente ni cada configuración de pantalla completa.
