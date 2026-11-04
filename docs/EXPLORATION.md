# Exploración — El último refugio

F5 → Iniciar historia → prólogo ilustrado (Continuar / Saltar) → asentamiento. WASD/flechas caminan, Shift corre; clic se aproxima a un habitante u objeto. El botón ? abre ayuda y pausa desplazamientos/rutinas; cerrar devuelve el control. Continuar historia confirma el avance y conduce al ataque y al combate original 8×8.

## Mapa y presentación

Se conserva scenes/exploration.tscn y el contenido data/narrative/settlement.json, con límites 1080×780. Viviendas agrupadas, puesto/pozo y plaza empedrada conectan residencia, huerto, zona tecnológica y entrada. La cámara usa camera_zoom 0.9 y camera_offset [0,-60]; sigue a Gael sin cambiar coordenadas de navegación.

ExplorationScenery dibuja el suelo una vez por invalidación. ground_paths conserva rectángulos anteriores; ground_polygons permite contornos de caminos definidos por puntos, recortados contra tiles con Geometry2D y UV del atlas existente. No son obstáculos ni modifican costes de movimiento.

ExplorationProp representa cada edificio/objeto como Node2D individual ordenado por y. props conserva el formato anterior [índice,x,y,ancho,alto]; visual_props añade sheet, region en píxeles, rect y sort_y opcional. texture_for comparte las texturas fuente. El mapa no carga la imagen de referencia ni las ilustraciones cinematográficas como terreno. Los props nuevos son originales, no recortes de la referencia.

ExplorationAtmosphere recibe ambient, lights y steam. Usa CanvasModulate y PointLight2D con un gradiente radial compartido, más vapor discreto. No añade desenfoque ni altera colisiones. La UI está en otro CanvasLayer y permanece legible; la atmósfera desaparece junto a la exploración al entrar en combate.

## Actores y navegación

ExplorationActor comparte cuerpo/ruta/velocidad; ExplorationPlayer aporta InputMap y cancelación manual; AmbientActor y AmbientRoutines mantienen las rutinas existentes. DirectionalVisual usa cuatro orientaciones y fase continua según velocidad real; conserva dirección al parar. Los pasos siguen siendo un rig por piezas provisional, ahora con sombra de apoyo.

Activos: Lira, aldeano preocupado, vecino, Elena, reparador, niño, perro y una gallina, además de Gael. Cuatro configuraciones anteriores se mantienen en reserve_actors (Mara, transportista, vecino mayor y segunda gallina), con sus diálogos intactos; no se instancian ni añaden colisiones. El reparador y el vecino comparten arquetipo con tintes/ubicaciones/ocupaciones diferentes. No se generaron nuevas animaciones de personas en esta iteración.

InteractionNavigation conserva AStar2D por esquinas, obstáculos expandidos y cuatro puntos de aproximación a 42 píxeles. blockers define los cuerpos estáticos; los actores móviles aportan cuerpos y reservas de destino. Un objeto interactuable puede configurar collision_size, independiente de visual_size: la consola usa 56×28 físicos y 88×104 visuales. El huerto y postes tienen bloqueos explícitos; la gallina se desplazó a un área vecina libre. La decoración nunca crea reglas implícitas.

Un clic suspende al objetivo y lo orienta hacia Gael. Diálogos, ayuda, confirmación y secuencias bloquean rutinas mediante player.locked. Cerrar reanuda. Un destino imposible o bloqueo prolongado cancela/reintenta con pausa; no hay planificación global de multitudes.

## Crear contenido sin copiar scripts

Para otro contenido, suministrar bounds/start/blockers/actors y los datos visuales anteriores a start_exploration. Definir posiciones/puntos alcanzables y comprobar colisiones por separado de la silueta. Incorporar un residente desde un arquetipo/rutina compartidos, como se explica en NPC_ROUTINES.md. El único mapa táctico jugable sigue siendo 8×8; el 10×10 es fixture.

Validación: test_exploration_physics.gd, test_story.gd, test_iteration4.gd y test_iteration5.gd; capturas gráficas con test_iteration5_visual.gd. Ver ITERATION_5_PROGRESS.md y VISUAL_REVIEW_ITERATION_5.md para evidencia y límites. Headless no valida calidad artística.

## Ruinas del asentamiento (iteración 6)

La victoria narrativa permite continuar a una secuencia que cambia el mismo mundo a su estado destruido. fall.json hereda límites/caminos y configura props dañados, ambiente frío y nuevos escombros sólidos. No hay un segundo controlador/mapa exploratorio. Los NPC rutinarios y Lira se retiran; solo el testigo condicional permanece en idle. Las tres pistas tienen marcador/área de interacción generosa y usan los mismos diálogos/aproximación.

Con testigo se puede partir directamente o volver a hablar/examinar. Sin él, examinar dos pistas distintas basta en cualquier orden. Partir hacia el norte comprueba las condiciones y presenta el límite del capítulo, sin cargar el siguiente mapa. Ver CHAPTER_1.md para estados, persistencia en memoria y pruebas.
