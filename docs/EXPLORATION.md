# Exploración

F5 → **Iniciar historia** → prólogo (Continuar o Saltar introducción) → asentamiento. WASD/flechas desplazan a Gael; Shift corre. Clic sobre NPC/objeto: aproximación y conversación/examen. Continuar historia confirma la salida de exploración y reproduce el ataque antes del combate 8×8.

`scenes/exploration.tscn` y ExplorationController consumen `data/narrative/settlement.json`. El mismo mapa se compactó de 1400×900 a 1080×780 (33 % menos superficie). Viviendas/huerto/lavadero, pozo y suministros comunitarios, terminal/maquinaria y entrada oriental comparten caminos conectados. No se utiliza una captura como fondo. ExplorationScenery dibuja una capa estática con el atlas existente y detalles por código; los bloqueos físicos proceden exclusivamente de `blockers` y cuerpos interactuables.

ExplorationActor comparte CharacterBody2D, círculo de radio 9, recorridos y llegada. ExplorationPlayer normaliza movimiento diagonal, permite correr y cancelar rutas manualmente. AmbientActor reutiliza el cuerpo para habitantes y animales. DirectionalVisual representa idle/walk/run/interact mediante cuatro orientaciones distintas y un ciclo de pasos por piezas; no invierte verticalmente ni mantiene una única vista lateral. El arte y el rig son provisionales. Ver NPC_ROUTINES.md.

InteractionNavigation construye un grafo de visibilidad AStar2D sobre esquinas expandidas. La aproximación prueba cuatro puntos separados 42 píxeles del objetivo. Incluye edificios y posiciones actuales de NPC; reservas evitan destinos coincidentes entre rutinas. Los cuerpos resuelven encuentros dinámicos; tras un bloqueo prolongado se cancela/reintenta con pausa. No hay resolución global de tráfico.

Lira recorre puntos propios y se detiene para conversar. También hay aldeano importante, vecino, dos mujeres, dos trabajadores, una persona mayor, un niño, un perro y dos gallinas. El NPC pulsado se suspende durante la aproximación; los diálogos y secuencias congelan las rutinas. Al terminar se reanudan, conservando el recorrido. Los animales no abren paneles de diálogo. Lira sigue disponible en combate con independencia de su posición explorable.

Para reutilizar: proporcionar bounds/start/blockers, props y actors en un JSON; pasar su ruta a `start_exploration`. `ground_paths` y `decorations` son datos visuales. No copiar navegación ni movimiento. La geometría admite obstáculos rectangulares; formas complejas requerirían ampliar el proveedor. La población actual no exige culling ni horarios diarios.

Validación: test_exploration_physics.gd comprueba movimiento, carrera, pared, clic y bloqueo de diálogo; test_iteration4.gd comprueba rutinas reales, pausa/reanudación, límites, accesibilidad y rechazo de destinos imposibles. test_story_visual.gd captura el render de Godot. Estas pruebas no sustituyen una sesión manual de legibilidad y sensación del movimiento.
