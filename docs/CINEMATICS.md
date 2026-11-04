# Acciones cinematográficas reutilizables

StorySession.play_actions interpreta arrays de datos; el prólogo, ataque inicial y caída comparten ese intérprete. No hay una clase por escena. Las acciones emiten action_started y exponen current_action para pruebas, sin depuración visible al jugador.

## Acciones

| type | Campos | Responsabilidad |
|---|---|---|
| camera | position, seconds opcional | Tween de cámara |
| show / hide | id, actor opcional | Crear/configurar o cambiar visibilidad; se respetan condiciones de aparición |
| move | id, position, seconds, run opcional | Mover player, NPC o prop cinematográfico y alimentar animación |
| pose | id, rotation, face opcionales | Pose visual del cuerpo compartido |
| dialogue | speaker, text, effects opcionales | Diálogo breve, espera confirmación, aplica efectos al cerrar |
| intro_card | image/text/seconds, zoom_from/to, pan, transition, title/caption, audio | Ilustración/texto progresivo o título, avance protegido contra callback antiguo |
| sound | cue | Efecto en la cola SFX existente |
| ambience | cue opcional, volume en dB, seconds | Ambiente local con fundido; cue vacío detiene; sin cue ajusta volumen actual |
| flash | color, seconds | Impacto visual temporal, sin detalle gráfico explícito |
| fade / reveal | seconds | Negro mantenido / devolución de la imagen |
| environment | id | Reinstanciar el controlador común con un parche ambiental |
| effects | effects | Escrituras idempotentes de estado |
| wait / wait_event | seconds / event | Pausa temporal o espera de evento |
| control | — | Habilitar exploración/HUD al terminar la puesta en escena |
| chapter_end | title/text | Límite narrativo con retorno a exploración/menú, sin otro mapa |
| scene / battle | path / misión preparada del flujo | Transiciones existentes |

Todas admiten conditions. bucket/key/value mantiene el contrato anterior. path permite consultar resultados anidados, por ejemplo:

```json
{"path":["results","settlement","villager_survived"],"value":true}
```

Para contar hechos distintos sin duplicar contadores:

```json
{"count":[["examined","convoy_tracks"],["examined","authority_equipment"],["examined","transport_record"]],"at_least":2}
```

Los efectos solo escriben buckets permitidos; no se evalúan expresiones arbitrarias. state_rules se evalúa tras registrar un examen/elección y usa esos mismos contratos.

## Entornos y actores

NarrativeContent.read resuelve base_content con un límite de profundidad; merge fusiona diccionarios y sustituye arrays. environments declara parches y base_environment permite heredar otro parche. Las variantes se componen sobre el mapa original; no copiar navegación, rutinas o UI.

Asignar WorldState antes de setup garantiza que un actor excluido por condiciones no cree sprite, cuerpo o interacción. show reutiliza add_actor. Un actor cinematic=true es de puesta en escena; static_sprite=true reutiliza el sprite táctico/visual como ExplorationProp ordenado por profundidad. Vehículos y tropas cinematográficas no crean TacticalUnit, IA ni un segundo combate.

El ID reservado player identifica el cuerpo controlable, sin nombres de protagonistas en sistemas generales. cinematic_velocity y cinematic_running separan tween y estado visual. Al terminar el tramo se limpian; la física habitual continúa usando move_and_slide. Las rutas de la cinemática están compuestas en espacios libres; no son el pathfinding táctico.

El HUD permanece oculto y las rutinas suspendidas en la secuencia. control devuelve la fase exploration y la cámara/controles. En tarjetas fuera de la introducción no se muestra Saltar introducción, que no debe omitir efectos del capítulo; Continuar permite avanzar la tarjeta. Los diálogos conservan confirmación manual. playback_speed acelera pruebas sin alterar datos de duración del producto.

## Recurso y ciclo de vida

El ambiente local utiliza SFX, respeta ajustes existentes y libera stream/tween al salir. La secuencia de prueba gráfica detectó una retención al cerrar el ambiente; se corrigió deteniendo y liberando el stream en _exit_tree, y la ejecución final no mostró ese aviso. No se silenció el error.

La introducción usa ilustraciones completas únicamente dentro de la tarjeta; los mapas interactivos se construyen con props/tiles/cuerpos individuales. La caída combina movimiento real de puesta en escena, ilustración, fuego del atlas, cámara y audio, sin vídeo obligatorio.

Validar acciones nuevas con pruebas específicas, resultado/estado real, restauración y capturas. Para la caída ejecutar test_iteration6.gd y test_iteration6_visual.gd; para preservar intro/movimiento, seleccionar test_story, test_iteration4/5 y test_exploration_physics según el cambio. No ejecutar la suite completa por costumbre.
