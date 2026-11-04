# Exploración

F5 → **Iniciar historia**. WASD/flechas mueven a Gael en ocho direcciones; Shift corre. Clic sobre NPC u objeto: Gael se aproxima y conversa/examina. Lira permanece como NPC; su aparición no determina su disponibilidad táctica. No se inicia combate al tocar enemigos.

`scenes/exploration.tscn` y ExplorationController consumen `data/narrative/settlement.json`. El mapa mide 1400×900, tiene decoración independiente del atlas, colisiones StaticBody2D, cinco interactuables y cámara limitada al rectángulo configurado. No usa una captura como fondo ni el BFS táctico.

ExplorationPlayer es CharacterBody2D con círculo de colisión, dirección normalizada, orientación con espejo horizontal y balanceo visual idle/movimiento. Utiliza acciones InputMap explore_left/right/up/down/run; añade bindings físicos WASD/flechas/Shift si aún no existen. Los sprites mantienen una sola vista de autoría; no se crearon spritesheets direccionales. player_art y walk_speed proceden del contenido, igual que ground_tile_size, ground_terrain y ground_paths: no hay caminos exclusivos del asentamiento codificados en el controlador general.

InteractionNavigation construye un grafo de visibilidad AStar2D sobre esquinas de obstáculos expandidos para el radio del personaje. Prueba posiciones de aproximación alrededor del objetivo y rechaza rutas inexistentes. Nunca intenta ocupar el cuerpo del NPC. El movimiento manual cancela la ruta y la interacción pendiente. Los paneles bloquean clics; diálogos y secuencias bloquean movimiento.

Para crear otro mapa, proporcionar bounds, start, blockers (rectángulos), props (índice de atlas y rectángulo) y actors en otro JSON; pasar su ruta a `start_exploration`. No copiar scripts de navegación o movimiento. La implementación actual usa obstáculos estáticos rectangulares; una geometría más compleja necesitaría ampliar el proveedor de navegación.
