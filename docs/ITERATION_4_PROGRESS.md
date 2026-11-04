# Iteración 4 — progreso y validación

Fecha: 2026-11-04. Godot 4.2.2, Windows, Compatibility.

## Punto de restauración

La iteración 3 se conservó mediante commit local `9ef2d54` (chore: checkpoint iteración 3 antes del asentamiento vivo). No se restauraron ni descartaron cambios previos. Antes de editar se leyeron AGENTS.md, arquitectura, exploración y narrativa, se inspeccionaron controladores/recursos y se ejecutó la línea base.

## Etapas implementadas

1. AGENTS.md: reglas permanentes de reutilización, densidad, orientación, estados, rutinas, combate 8×8, acciones cinematográficas y evidencia de pruebas.
2. Movimiento y visual separados: ExplorationActor, ExplorationPlayer, AmbientActor y DirectionalVisual; cuatro orientaciones verdaderas, idle/walk/run/interact y rig de pasos provisional.
3. Coordinador compartido: idle/wander/patrol/work/socialize; pausas, reservas, navegación existente, colisión, suspensión/reanudación y rechazo de destinos imposibles.
4. Lira activa con recorrido propio; población variada y animales sin diálogo obligatorio.
5. Mismo asentamiento reducido a 1080×780, con vivienda, huerto/lavadero, comunidad, maquinaria y entrada; no se añadió otro mapa jugable.
6. Civil advertido en (1,3), seek_shelter y reacción de refugio; no advertido en (4,3), wander y confusión. Ambos conservan movimiento 2 y captura. Terminal sigue configurando barrera (5,3).
7. Explorador de la Autoridad mediante recurso/modificador: 22/6/1/5, flanker, mismos sistemas y arte de soldado reutilizado. No se tocaron estadísticas de Gael/Lira.
8. Prólogo configurable de cuatro tarjetas (34 segundos), texto progresivo, pan, fundidos, avance/salto y devolución del control. Nueva partida lo reproduce; reintentar combate no.
9. Documentación y pruebas automatizadas añadidas.

## Pruebas ejecutadas

Línea base antes de la iteración: 1.281 comprobaciones, cero fallos, más 12 partidas completas simuladas. Se conservaron los fixtures 8×8/10×10; solo el 8×8 se ofrece en la historia.

Resultado final de suites headless:

| Script en tests/ | Comprobaciones | Fallos |
|---|---:|---:|
| test_battle.gd | 221 | 0 |
| test_presentation.gd | 27 | 0 |
| test_iteration2.gd | 148 | 0 |
| test_maps.gd | 834 | 0 |
| test_story.gd | 38 | 0 |
| test_exploration_physics.gd | 13 | 0 |
| test_iteration4.gd | 171 | 0 |
| **Total** | **1.452** | **0** |

Nueva cobertura: orientación/continuidad de fase, carrera/interacción, prólogo antes de control, avance doble obsoleto, salto/fundido, final automático con duraciones reducidas solo en test, nueva partida, rutinas físicas de Lira/niño/perro, pausa/reanudación, límites/obstáculos, acceso a todos los interactuables, reintento acotado imposible, cuatro configuraciones tácticas, secuencia no advertida y reinicio.

`test_matches.gd`: 12 partidas completas, cero fallos: victoria/derrota de los dos fixtures base y victoria/derrota de las cuatro combinaciones narrativas. El bot usa movimiento, ataques y habilidades normales; la prueba de derrota no modifica PV/posiciones para forzar el resultado.

| Advertencia | Terminal | Victoria (turnos) | Daño recibido | Captura al ganar | Derrota pasiva (turno) |
|---|---|---:|---:|---:|---:|
| No | No | 11 | 57 | 2/3 | 4 |
| No | Sí | 13 | 72 | 1/3 | 4 |
| Sí | No | 11 | 67 | 0/3 | 6 |
| Sí | Sí | 11 | 67 | 0/3 | 6 |

Esto demuestra rutas de victoria y derrota, no equilibrio exhaustivo ni facilidad para una persona. La terminal cambia acceso/captura; el bot no obtiene necesariamente menos turnos/daño con ella. El aviso no garantiza supervivencia: ambas variantes pierden si se juega pasivamente.

Renderizado real con `test_story_visual.gd` (OpenGL, NVIDIA RTX 4060, salida 0): capturas de prólogo, exploración, rutinas, elección y combate preparado en docs/screenshots/story_*.png. Se inspeccionaron capturas mediante lectura de imagen. No se realizó una sesión manual completa; no se presenta headless como prueba visual/jugable.

La importación headless del editor registró clases/arte, pero termina con error de guardado de preferencias en este entorno restringido. Los ejecutables de pruebas de runtime sí terminaron correctamente. No se ha exportado un ejecutable Windows.

## Recursos y archivos

Nuevo atlas: assets/art/directional_villagers.png (RGBA con transparencia), generado con la herramienta integrada image_gen usando el skill imagegen. Prompt y procedencia en ART_ITERATION_4.md. El arte táctico, retratos y sonidos previos permanecen intactos. Huerto, ropa, banco y cable son decoración por código, sin colisiones implícitas.

Nuevos: cinco scripts exploration (exploration_actor, ambient_actor, ambient_routines, directional_visual, exploration_scenery), data/units/scout.tres, atlas/import, tests/test_iteration4.gd, NPC_ROUTINES.md, este registro y ART_ITERATION_4.md.

Modificados: AGENTS.md, README.md, ARCHITECTURE.md, EXPLORATION.md, NARRATIVE_SYSTEM.md, settlement.json, ExplorationController/Player, StorySession, main.gd, BattlePreparationResolver, EnemyAI, UnitDefinition/BattleMissionData; pruebas story/physics/matches/visual y capturas. No existen scripts de combate duplicados.

## Pendiente antes de considerar acabado el pulido visual

- Revisión manual continua con teclado/ratón: orientación en ocho desplazamientos, costuras/deslizamiento del rig, lectura de animales y congestión prolongada.
- Sustituir, si se desea calidad final, pasos por piezas por fotogramas dibujados y revisar identidad/escala del atlas direccional. Las vistas actuales son provisionales.
- Ilustraciones cinematográficas definitivas: las tarjetas actuales reutilizan props, no fondos finales generados.
- Playtesting humano de las cuatro combinaciones y accesibilidad visual/audio; las simulaciones no sustituyen esa revisión.
- No hay música nueva, voz, horarios diarios ni planificación global de multitudes; no se añadieron por esta iteración.

El alcance funcional automatizable está implementado y pasa sus pruebas; el acabado artístico/manual permanece pendiente. Retomar desde esta lista, sin reconstruir los sistemas.

## Ejecutar

Abrir project.godot con Godot 4.2.2 y F5 → Iniciar historia. Usar Continuar/Saltar introducción; WASD/flechas, Shift y clic en habitantes/objetos. Continuar historia confirma el ataque y carga el combate original 8×8 con las decisiones aplicadas.

Validación: `godot --headless --path . --script res://tests/test_iteration4.gd` y análogamente las suites de la tabla/test_matches.gd. Para capturas usar `godot --path . --script res://tests/test_story_visual.gd`, con un renderizador gráfico disponible. El nombre del ejecutable depende de la instalación local; el proyecto no contiene rutas absolutas de desarrollo.
