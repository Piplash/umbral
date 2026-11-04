# Refactorización de mapas y misiones — Validación

Fecha: 4 de noviembre de 2026. Motor ejecutado: **Godot 4.2.2 stable**, Windows, Compatibility / OpenGL 3.3, NVIDIA RTX 4060.

## Protección y alcance

Se inspeccionaron escena, scripts, recursos, dependencias y suites antes de editar. No hay repositorio Git configurado. Se guardó el estado anterior en `backups/architecture-before-20261104-120025/`, excluido del importador por `backups/.gdignore` y de Git por la regla ya existente.

Los hashes confirman que los dos atlas y los **15 WAV** no cambiaron. También permanecen idénticos CombatSystem, AbilitySystem, MovementSystem, TurnManager, UmbralAudio y `scenes/main.tscn`. Las estadísticas extraídas a recursos se contrastan con los cinco valores originales en ambos escenarios. El asentamiento conserva seis obstáculos y las mismas posiciones iniciales.

## Resultados ejecutados

| Suite | Resultado final |
|---|---|
| `tests/test_battle.gd` | 221 comprobaciones, 0 fallos |
| `tests/test_presentation.gd` | 27 comprobaciones, 0 fallos |
| `tests/test_iteration2.gd` | 148 comprobaciones, 0 fallos |
| `tests/test_maps.gd` | 834 comprobaciones, 0 fallos |
| `tests/test_matches.gd` | Cuatro partidas completas, 0 fallos |
| `tests/test_visual.gd` | Doce capturas renderizadas, salida 0 |
| `tests/test_maps_visual.gd` | Ocho capturas renderizadas, salida 0 |

**Total: 1.230 aserciones sin fallos**, más cuatro partidas de reglas y veinte capturas. Las últimas ejecuciones de las suites finalizan con código 0, sin errores de scripts ni avisos de recursos pendientes.

| Misión | Victoria automática | Daño aliado | Habilidades | Captura al ganar | Derrota automática |
|---|---:|---:|---:|---:|---|
| Defensa del asentamiento 8×8 | Turno 7 | 34 | 3 | 0/3 | Captura 3/3 en turno 4 |
| Escenario de prueba 10×10 | Turno 7 | 35 | 4 | 0/3 | Captura 3/3 en turno 4 |

Las partidas usan el mismo bot de prueba y las mismas órdenes públicas de movimiento/acciones y activaciones de IA. No se modifica el daño ni los PV para obtener esas victorias. El mapa 10×10 tiene obstáculos y posiciones distintos; no es una segunda implementación.

## Qué cubre la suite nueva

- Validación y consumo de los recursos, apariciones correctas y estadísticas preservadas.
- Dimensiones dinámicas, BFS, alcance, obstáculos, ocupación y casillas transitables mediante whitelist.
- Rangos actuales y potenciales sobre el mapa activo, también en una topología no cuadrada.
- Golpe contundente, interferencia, curación, enfriamiento aplicado y bloqueo de captura en ambos escenarios.
- Victoria por todos los enemigos y derrota por captura/todos los aliados, con reinicio limpio.
- IDs renombrados, participantes reordenados y un tercer enemigo: el resultado no depende de nombres, índices ni del número dos.
- Una UnitDefinition nueva creada solo en la prueba reutiliza habilidades y arte con un ID de instancia diferente.
- Una condición Resource de ubicación definida exclusivamente en la prueba completa la misión mediante un movimiento real, sin cambiar BattleManager ni la vista. `battle_completed` emite motivo/estadísticas una sola vez.
- Estado runtime independiente entre batallas que comparten configuración.
- Selector, movimiento animado, deshacer, fase enemiga y reinicio sobre ambos mapas mediante la misma escena y controlador.
- Ajuste visual para un mapa mayor sin cambiar sus dimensiones lógicas.

Durante el desarrollo se detectó que `Resource.duplicate(true)` en Godot 4.2 no aislaba las apariciones dentro de arrays tipados de los fixtures. Se corrigió la prueba para duplicar cada UnitSpawnData expresamente. El juego no muta recursos de configuración compartidos; esa separación también queda cubierta por aserciones.

## Revisión visual realizada

Se ejecutaron ventanas reales de Godot y se guardaron imágenes del viewport en `docs/screenshots/`. Se inspeccionaron menú, selector conservando la segunda misión, combate 8×8, combate 10×10, amenazas, pronóstico y ajustes; se comprobaron composición y legibilidad del HUD. Las ocho capturas nuevas se llaman `maps_menu`, `maps_menu_test_selected` y `maps_{settlement,test_field}{,_threat,_results}`.

Las capturas de resultados preparan expresamente el estado final para revisar esa pantalla; no se presentan como una partida ganada manualmente. Las cuatro partidas completas son simulaciones de reglas headless. Las pruebas de escena ejercitan movimiento y fases con animaciones, pero no equivalen a una partida manual completa de principio a fin en cada mapa.

La importación headless del editor se ejecutó con `--editor --import`; registró las clases y recursos nuevos. Ese proceso mantiene el error ambiental de **guardado seguro de preferencias del editor** ya observado antes de esta tarea y devuelve salida 1. Se redirigió APPDATA únicamente en los procesos de validación al directorio local `.godot/runtime` para no escribir fuera del proyecto. No se modificaron opciones de seguridad ni se ocultó ese error. Las ejecuciones de juego, escenas, pruebas y renderizado funcionan con salida 0.

## Archivos creados o modificados

**Nuevos:** `AGENTS.md`; clases de recursos bajo `scripts/data/`; `objective_system.gd`, `mission_catalog.gd`, `board_layout.gd`, `map_visual.gd`; recursos bajo `data/maps/`, `data/missions/`, `data/units/`, `data/objectives/`; `scenes/maps/settlement_visual.tscn`; `test_maps.gd`, `test_maps_visual.gd`; auditoría, guía de mapas e informe de validación.

**Modificados:** `battle_manager.gd`, `grid_manager.gd`, `unit.gd`, `enemy_ai.gd`, `capture_system.gd`, `threat_system.gd`, `board_view.gd`, `settlement_view.gd`, `art_library.gd`, `main.gd`; tests de partidas y referencias de geometría en presentación/iteración 2; `README.md`, `docs/ARCHITECTURE.md`, `docs/TESTING.md` y capturas regeneradas. No se copiaron scripts de combate por escenario.

## Límites y trabajo futuro

- Solo se entregan las modalidades actuales, con puntos de extensión probados. Rescate, sabotaje, supervivencia y escape no se anuncian como contenido implementado.
- Una misión tiene un único objetivo de captura/progreso. Proteger varios civiles a la vez necesitará ampliar ese sistema.
- El coste de movimiento es uniforme; no se implementó terreno con costes diferentes.
- La cámara es fija. BoardLayout adapta el tablero al HUD, pero un mapa enorme perdería legibilidad y requeriría cámara desplazable.
- SettlementView conserva coordenadas artísticas específicas. Esto no afecta reglas ni rutas; otro escenario artístico necesita su propia presentación o la genérica.
- El HUD continúa compuesto por código en main.gd. Ambos escenarios lo reutilizan, pero no se hizo una extracción completa a escenas de UI.
- No se exportó un `.exe`, no se probaron todas las escalas de Windows ni se completó una partida manual solo con teclado en cada mapa. Las imágenes cubren 1280×720 y 960×540 mediante las suites existentes.
