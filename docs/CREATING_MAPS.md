# Crear mapas y misiones sin copiar combate

Leer `AGENTS.md` y `ARCHITECTURE.md`. Los pasos usan las clases Resource disponibles en el inspector de Godot 4.2.2. Todos los archivos y referencias del proyecto usan `res://`; no requieren rutas del equipo del autor.

## 1. Crear el recurso de mapa

En `data/maps/`, crear un recurso **BattleMapData** y guardarlo con un nombre nuevo, por ejemplo `cantera.tres`. Alternativamente, copiar un `.tres` de mapa y editar sus propiedades: se copia configuración, no scripts.

El asentamiento usa `data/maps/settlement.tres`; el segundo escenario usa `data/maps/test_field.tres`. No modificar esos archivos para crear otra misión si se quiere conservarlos.

## 2. Dimensiones y geometría

Configurar `map_id` único, `dimensions` y `cell_size`. Las coordenadas empiezan en (0,0); X va a la derecha y Y hacia abajo.

| Ejemplo existente | Dimensiones | Casilla | Origen visual |
|---|---:|---:|---|
| settlement | 8×8 | 46 px | (226,128) |
| test_field | 10×10 | 36 px | (265,132) |

`board_origin = (0,0)` pide centrado automático en el área del tablero. BoardLayout reduce el tamaño visual si no cabe, sin cambiar dimensiones ni alcances lógicos. No añadir constantes TILE a scripts de mapas o unidades. La cámara actual muestra el tablero completo; para mapas enormes hará falta trabajo adicional de cámara/legibilidad.

## 3. Transitabilidad y terreno

- `walkable_cells` vacío: todas las casillas dentro de las dimensiones existen y son transitables salvo obstáculos.
- `walkable_cells` no vacío: solo existen como transitables las casillas enumeradas, menos los bloqueos. Sirve para islas o huecos.
- `default_terrain`: índice visual del suelo común.
- `terrain`: overrides por casilla, con claves Vector2i. Valores actuales: 0 pasto, 1 tierra, 2 mezcla, 3 grava.

Los cuatro terrenos cuestan un movimiento. No asignar costes implícitos por textura; BFS sigue siendo la única búsqueda. Si se implementan costes en otra tarea, hay que adaptar el algoritmo y sus pruebas.

## 4. Obstáculos

Rellenar `blocked_cells` con Vector2i válidos. No ubicar unidades sobre ellos. La vista genérica dibuja cajas/rocas y el sistema de rutas consulta el mismo array del mapa activo. Una pieza puramente decorativa no bloquea por sí sola.

Ejemplo mínimo de mapa 10×10:

```ini
[gd_resource type="Resource" script_class="BattleMapData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/battle_map_data.gd" id="map_script"]

[resource]
script = ExtResource("map_script")
map_id = "cantera"
dimensions = Vector2i(10, 10)
cell_size = 36
board_origin = Vector2(0, 0)
blocked_cells = Array[Vector2i]([Vector2i(2, 2), Vector2i(2, 3), Vector2i(7, 6)])
default_terrain = 0
terrain = {Vector2i(4, 4): 1, Vector2i(4, 5): 2}
spawn_points = {"entrada": Vector2i(1, 5)}
```

El ejemplo es configuración; no necesita una escena propia ni otro BattleManager.

## 5. Misión y posiciones iniciales

Crear un **BattleMissionData** en `data/missions/`, por ejemplo `cantera.tres`. Asignar `mission_id`, `display_name` y el recurso `map`. En `participants`, crear **un UnitSpawnData nuevo por aparición**:

- `instance_id`: único dentro de la misión; no es el ID de arquetipo.
- `definition`: recurso de `data/units/`.
- `position`: casilla inicial.
- `spawn_point`: opcional, clave de `map.spawn_points`; si está definido prevalece sobre position.

Los ejemplos existentes usan posiciones directas:

| Instancia | Asentamiento 8×8 | Prueba 10×10 |
|---|---|---|
| hero | (1,4) | (1,5) |
| support | (2,5) | (2,6) |
| soldier | (6,2) | (8,3) |
| captor | (6,6) | (8,8) |
| civil | (3,3) | (4,5) |

Se puede copiar el archivo `.tres` de misión como punto de partida: cambiar la referencia `res://data/maps/...`, ID, nombre y posiciones de sus SubResource de aparición. Los SubResource deben pertenecer al archivo nuevo. En el inspector, crear apariciones nuevas o hacerlas únicas antes de editar; no compartir UnitSpawnData mutable entre misiones por accidente. Godot 4.2 no garantiza aislar esos recursos dentro de arrays tipados mediante `duplicate(true)`.

## 6. Elegir unidades

Los recursos actuales son `hero.tres`, `support.tres`, `soldier.tres`, `captor.tres` y `civil.tres`. Compartir UnitDefinition es correcto: el runtime copia los datos y no modifica el recurso.

Para otro personaje crear UnitDefinition con ID de definición, nombre, equipo, PV/ataque/defensa/movimiento, códigos de habilidades y comportamiento. Los códigos actuales son `heavy`, `jam` y `heal`; asignarlos a otra unidad no requiere cambiar nombres de personajes en la lógica. Un poder nuevo requiere implementar su regla y probarla.

Comportamientos actuales: `player` para control aliado, `aggressive` para persecución/ataque enemigo, `capture` para aproximación/captura y `passive` para una unidad inmóvil sin control. No cambiar estadísticas existentes sin autorización.

Para varios soldados reutilizar su definición y crear apariciones con IDs diferentes, por ejemplo `guard_a` y `guard_b`. La victoria cuenta todos los enemigos configurados; no presupone dos.

## 7. Objetivos

Para conservar el encuentro de protección:

1. `protected_unit_id`: ID de instancia del civil de esa misión.
2. `capture_limit = 3`.
3. `objective_text`: texto breve del HUD.
4. `victory_conditions`: referencia a `data/objectives/eliminate_enemies.tres`.
5. `defeat_conditions`: referencias a `all_allies_defeated.tres` y `civil_captured.tres`.
6. `victory_title` y `defeat_title`: títulos del resultado, si se quieren personalizar.

Todas las condiciones de victoria deben cumplirse; basta una condición de derrota. Los recursos TeamDefeatedCondition permiten elegir el equipo; CaptureCompleteCondition consulta el progreso y límite de la misión. El ID protegido se resuelve por identidad, no por su posición en el array de participantes.

Para supervivencia, escape, sabotaje u otra modalidad futura, crear una subclase de BattleCondition que implemente `evaluate(units, capture, turns)` y añadir su recurso a la misión. No modificar MapVisual ni añadir condiciones por ID de mapa dentro de BattleManager. Esas modalidades no están implementadas como contenido actualmente; la suite demuestra el contrato con una condición de ubicación exclusiva de prueba.

Un futuro módulo narrativo puede escuchar `BattleManager.battle_completed(mission_id, outcome)` sin intervenir en el cálculo del resultado.

## 8. Asociar arte

Sin `visual_scene`, MapVisual dibuja suelo, overrides de terreno y obstáculos mediante el atlas existente. Es la opción usada por el 10×10.

Para arte específico, crear una PackedScene cuya raíz herede **MapVisual** y asignarla a `map.visual_scene`. Cada instancia recibe `map_data`, `board_layout`, `battle` y `layer` antes de entrar en el árbol. Respetar `layer` (`ground`, `lower`, `obstacles`, `upper`) para no dibujar las mismas decoraciones en todas las capas. Usar `board_layout.pixel(cell)` y `tile_size` para todo elemento ligado a una casilla. Mantener la lógica de obstáculos en los datos, no en el dibujo.

Ejemplo real: `scenes/maps/settlement_visual.tscn` usa SettlementView para casa, generador, árboles, cercas y luces; delega obstáculos a la base. Un script de presentación nuevo puede especializar `_draw` y llamar `super._draw()` para suelo/obstáculos, sin copiar ninguna mecánica de combate.

En UnitDefinition, `art_key` puede reutilizar sprites/retratos del atlas actual. Para arte nuevo, asignar texturas a `sprite` y `portrait`; ArtLibrary las prioriza. Conservar el filtrado nearest y no sustituir recursos existentes sin autorización.

## 9. Incorporar al selector

Guardar el recurso BattleMissionData dentro de **`data/missions/`**, con extensión `.tres`. MissionCatalog lo descubre automáticamente al abrir el menú; no editar main.gd ni agregar otro controlador. El nombre visible y las dimensiones salen del recurso. Reiniciar usa la misión seleccionada.

Guardar solo misiones en ese directorio; mapas, unidades y condiciones tienen sus carpetas separadas. La ruta de misión predeterminada está en MissionCatalog y apunta al asentamiento. Solo cambiarla si una tarea pide cambiar el inicio del juego.

## 10. Validar y jugar

En una copia recién importada, dejar terminar el escaneo del editor. Desde la raíz, con el ejecutable de Godot en PATH:

```powershell
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --script res://tests/test_presentation.gd
godot --headless --path . --script res://tests/test_iteration2.gd
godot --headless --path . --script res://tests/test_maps.gd
godot --headless --path . --script res://tests/test_matches.gd
godot --path . --script res://tests/test_maps_visual.gd
```

`mission.validation_errors()` comprueba mapa, posiciones, IDs, puntos de aparición y condiciones. Corregir la configuración antes de jugar. La suite de mapas recorre todas las misiones descubiertas para reglas básicas; sus fixtures adicionales de reidentificación y selector verifican los dos escenarios entregados. Las suites de partidas/capturas usan los personajes de este prototipo: adaptarlas al añadir misiones con otra composición, sin alterar los sistemas generales.

En Godot, F5 → elegir escenario → Iniciar combate. Comprobar selección, previsualización, rutas reales, obstáculos, deshacer, habilidades, amenazas, IA, captura, victoria/derrota y reinicio. Revisar la legibilidad del tablero y el HUD en ventana. Una carga headless no sustituye la revisión visual ni una partida manual completa.

Para diagnosticar diferencias, consultar `ARCHITECTURE_TESTING.md`. Nunca copiar `battle_manager.gd`, `movement_system.gd`, `enemy_ai.gd` ni `main.gd` a una carpeta de mapa.
