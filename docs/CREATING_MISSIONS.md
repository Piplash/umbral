# Crear contenido narrativo

Consultar AGENTS.md, ARCHITECTURE.md y CREATING_MAPS.md. La arquitectura táctica sigue basada en recursos y dimensiones dinámicas. El contenido explorable inicial está en `data/narrative/settlement.json`; no copiar controladores para añadir conversaciones.

## NPC y objetos

Agregar un actor con id estable, name, position `[x,y]`, dialogue y art (clave de personaje) o prop (índice de atlas). Opcionalmente conditions limita disponibilidad. El controlador crea colisión y navegación de aproximación comunes. Para un objeto examinado, usar examined_id en el diálogo. No escribir lógica en un script exclusivo del NPC.

## Diálogos y decisiones

En dialogues agregar una clave de conversación con speaker, art opcional, lines y choices. Cada opción contiene text, conditions opcionales y effects. Ejemplo de advertencia:

```json
{"text":"Refúgiate si llegan las tropas.","effects":[{"bucket":"flags","key":"villager_warned","value":true}]}
```

Registrar una decisión adicional puede usar bucket choices. Un evento usa events. La terminal usa `{"bucket":"prepared","key":"terminal","value":true}`. El evaluador y resolver son compartidos y no ejecutan código del JSON.

## Modificadores

Agregar a modifiers un unit_behavior con unit (ID de instancia táctico), behavior y movement, o un barrier con cell `[x,y]`. conditions selecciona cuándo aplicarlo. Ejemplo:

```json
{"type":"barrier","cell":[5,3],"conditions":[{"bucket":"prepared","key":"terminal","value":true}],"message":"Defensas activas"}
```

No bloquear apariciones ni cerrar todos los caminos; validar mission.validation_errors y probar rutas reales. shelters configura destinos neutrales. La copia de batalla debe seguir siendo independiente del recurso base.

## Secuencias y flujo

sequence contiene acciones ordenadas con type. camera/move usan position; move/show/hide usan id; show puede incluir actor; dialogue usa speaker/text; sound usa cue; wait usa seconds; wait_event usa event; scene usa path; battle entrega la misión preparada al controlador existente. Las acciones de diálogo requieren confirmación del jugador.

Para una entrada distinta, llamar `start_exploration(ruta_del_contenido)` o usar directamente `start_battle(mision)` cuando no haga falta exploración. El campo battle_mission referencia el recurso táctico asociado; title, player_art, walk_speed y ground_paths configuran presentación y movimiento iniciales. No añadir escenarios tácticos al menú normal sin necesidad narrativa. Las transiciones y el registro se coordinan por MissionFlowController; un botón solo solicita confirmar.

## Validación

Elegir pruebas incrementales según los componentes afectados. Para diálogo/preparación usar `godot --headless --path . --script res://tests/test_story.gd`; para continuación/ruinas, test_iteration6.gd. No ejecutar la suite completa por costumbre. Para capturas: `godot --path . --script res://tests/test_story_visual.gd`. Probar además clics físicos, cancelación manual, cámara, colisiones y mezcla de audio en una partida humana; la integración automatizada no sustituye esa revisión.

## Continuación después de una victoria

En el contenido de exploración añadir after_victory con id único, path al contenido siguiente y entry al nombre de su secuencia. MissionFlowController verifica el resultado registrado y reclama ese ID una sola vez; el botón de resultados entrega el mismo WorldState al nuevo StorySession. No poner esa transición en EnemyAI, objetivos, daño ni scripts del mapa.

El contenido siguiente puede declarar base_content para reutilizar el mapa y los diálogos. Los diccionarios se fusionan y los arrays se reemplazan. environments contiene parches de presentación y base_environment opcional; environment cambia su configuración con el controlador común. Una condición path consulta el resultado, por ejemplo results → settlement → villager_survived, sin duplicar esa variable. Diseñar state_catalog y state_rules en los datos, con efectos idempotentes.

Para terminar una secuencia y devolver control utilizar control; para delimitar una continuación todavía no implementada usar chapter_end con título/texto. No añadir mapas vacíos ni combates perdidos obligatorios. El ejemplo completo es fall.json; ver CHAPTER_1.md y CINEMATICS.md. Probar victoria, derrota, callback duplicado, ramas, navegación y restauración, sin volver a simular el combate si sus reglas no cambiaron.
