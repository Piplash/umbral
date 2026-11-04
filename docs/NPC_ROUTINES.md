# Habitantes, animales y animación reutilizables

## Componentes

- ExplorationActor: cuerpo, círculo de colisión, velocidad, ruta y señal arrived.
- ExplorationPlayer: InputMap y cancelación manual.
- AmbientActor: suspensión y recuperación tras bloqueo de 1,5 segundos.
- AmbientRoutines: coordinador único de pausas, selección de destino, reservas y navegación.
- DirectionalVisual: orientación y estados visuales; no mueve el cuerpo.
- ExplorationScenery: suelo, props y decoración estática independientes de los actores.

No hay scripts por NPC, timers por habitante ni búsqueda global de nodos. Los actores se registran en ExplorationController.actor_nodes. Las rutas se solicitan al elegir destino, con un máximo de cuatro intentos por decisión. La pausa configurable limita reintentos imposibles. Los destinos de otros actores se reservan con separación de 28 píxeles; las colisiones resuelven cruces dinámicos. No garantiza ausencia total de congestión.

## Añadir un habitante sin copiar scripts

En actors de data/narrative/settlement.json añadir, por ejemplo:

```json
{
  "id": "habitante_nuevo",
  "name": "Habitante",
  "position": [730, 380],
  "visual_row": 3,
  "speed": 40,
  "initial_pause": 2,
  "dialogue": "saludo_nuevo",
  "routine": {
    "type": "patrol",
    "pause": 3,
    "points": [[730, 380], [750, 450]]
  }
}
```

El ejemplo ilustra el formato; comprobar ocupación y accesibilidad antes de usar esas posiciones. Añadir dialogues.saludo_nuevo con speaker/lines/choices. No requiere crear escenas o controladores. La exploración no incorpora automáticamente una unidad táctica: eso se configura por separado en misión/modificadores.

Tipos de rutina:

| Tipo | Configuración | Actividad |
|---|---|---|
| idle | pause opcional | Quieto, conserva orientación |
| wander | area: [x,y,ancho,alto], pause | Elige destinos alcanzables dentro del área |
| patrol | points: [[x,y],...], pause | Recorre puntos con pausas; omite el punto actual |
| work | pause | Actividad visual sencilla junto al lugar de trabajo |
| socialize | partner: ID, pause | Se orienta al interlocutor y muestra actividad |

Lira utiliza patrol a velocidad 43 con tres puntos y pausas de 3,5 segundos; no sigue a Gael. El niño y animales usan wander en áreas pequeñas. El trabajador de maquinaria usa work. Los conversadores usan socialize.

Para un animal usar visual_row 6 (perro) o 7 (gallina), speed, routine y omitir dialogue. Comparte navegación, cuerpo y orientación; el clic no abre una conversación humana. No tiene combate ni simulación adicional.

## Orientación y animación

El atlas assets/art/directional_villagers.png tiene cuatro columnas: abajo, derecha, arriba, izquierda. Filas: Gael, Lira, aldeano mayor, mujer, trabajador, niño, perro y gallina. BANDS describe las franjas reales inspeccionadas del atlas (no filas uniformes). Para otro atlas hay que adaptar la descripción de regiones; no asumir una grilla perfecta de la salida generada.

DirectionalVisual.face elige eje dominante con histéresis 1,15 y mantiene el eje anterior en diagonales casi iguales. advance recibe velocidad real, carrera, interacción y delta: idle conserva orientación, walk/run acumulan fase proporcional a velocidad real (0,07/0,075 por píxel de velocidad), interact muestra actividad. La vista trasera es arte independiente; no hay inversión vertical. El controlador compartido soporta run, aunque solo Gael lo activa desde InputMap.

El paso utiliza un rig provisional de torso y dos mitades inferiores con oscilación alternada. No son fotogramas de caminar dibujados a mano. Las vistas generadas están reducidas con nearest a unos 60 píxeles; animales mantienen menor altura. Revisar costuras del rig, identidad de Gael/Lira y lectura de animales en una sesión manual antes de considerar el arte definitivo. Los atlas tácticos y retratos originales no se sustituyeron.

## Diálogo y cinemática

interact suspende al objetivo inmediatamente, incluso mientras Gael se aproxima, y lo orienta al jugador. player.locked congela las rutinas durante paneles y secuencias. choose libera interaction_target y devuelve el control cuando flow.phase es exploration. La ruta se conserva para reanudarla después de conversar. El movimiento manual cancela aproximación y reserva de interacción.

StorySession.play_actions es el intérprete común de intro y ataque. move puede actualizar un actor ambiental mientras está suspendido y suministrar cinematic_velocity a su representación. Las condiciones de acciones usan ConditionEvaluator. intro_card admite text, seconds y prop opcional. Los botones Continuar y Saltar introducción usan una generación de tarjeta para ignorar callbacks antiguos. El final revela el mundo con fundido antes de liberar controles.

## Datos tácticos

BattlePreparationResolver aplica unit_behavior, barrier, unit_position y add_unit a una copia independiente de la misión. settlement.json cambia la posición/IA del civil y añade scout desde data/units/scout.tres, sin copiar combates. Scout tiene 22 PV, ataque 6, defensa 1 y movimiento 5; flanker pondera rutas y vulnerabilidad del aliado. Conserva arte de soldado con nombre/color diferentes. Ver NARRATIVE_SYSTEM.md para decisiones y pruebas de equilibrio.

## Validación y límites

Ejecutar tests/test_iteration4.gd junto a test_story.gd, test_exploration_physics.gd y test_matches.gd. La prueba nueva utiliza física real para Lira, niño y perro, comprueba pausa/reanudación, destinos imposibles, límites, accesibilidad de todos los actores y salto/avance/final automático del prólogo. Las capturas de test_story_visual.gd requieren renderizador gráfico; headless no prueba composición ni calidad visual.

El sistema actual no implementa horarios, multitudes, navegación de edificios arbitrarios ni animaciones multiframe finales. Las tarjetas cinematográficas reutilizan props como fondos provisionales. Esas limitaciones están registradas en ITERATION_4_PROGRESS.md.

## Distribución de iteración 5

La escena activa mantiene ocho NPC (seis humanos y dos animales), además de Gael. Las configuraciones de Mara/transportista/vecino mayor/segunda gallina están en reserve_actors y no se instancian; sus diálogos se conservan. Para activar una, mover su configuración a actors y revisar ocupación, rutas e identidad visual. No copiar controladores.

El vecino y reparador utilizan tint configurado sobre el arquetipo compartido y actividades/ubicaciones distintas. La gallina recorre ahora [160,500,105,50], junto al huerto físico; el niño conserva su área segura anterior. Los pasos dependen de velocidad, con fase persistente y sombra de apoyo; el rig no se convirtió en spritesheet multiframe final.
