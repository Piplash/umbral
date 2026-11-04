# Iteración 6 — progreso y evidencia

Fecha: 2026-11-04. Godot 4.2.2, Windows / Compatibility. Inicio limpio en 684b479. Se leyeron AGENTS.md, arquitectura, narrativa, misiones y código de resultados/diálogos/cinemática/estado antes de editar. Se localizó y abrió la referencia aprobada con extensión .png, no la ruta inexistente sin extensión. No se usó como mapa ni se recortaron sus componentes.

## Implementado

- Victoria registrada → botón Continuar historia → alivio, fuerza militar superior, destrucción, rescate fallido, captura visual de Lira, inconsciencia/despertar, título y ruinas explorables.
- Derrota/reintento intactos, reclamación idempotente y protección contra resultados abiertos/duplicados. Nueva partida conserva el inicio anterior; reanudar un snapshot de capítulo selecciona ruinas sin repetir prólogo/captura.
- Supervivencia del aldeano leída de resultado real; aviso y terminal conservan fuentes previas. Testigo solo si sobrevivió; líneas distintas según aviso. Terminal permite escape parcial; sigue habiendo pérdidas.
- Dos pistas distintas de tres en cualquier orden si falta testigo. Información de puente solo por testimonio, fuente de conocimiento conservada y suministros como bandera, sin inventario nuevo.
- Mismo mapa/controlador, props dañados, escombros sólidos, iluminación fría, humo, ausencia de Lira/actividad cotidiana y límite narrativo hacia el norte. Sin segundo combate ni nuevo mapa.
- Reutilización de condiciones, efectos, diálogos, WorldState, ExplorationController, actores, HUD y acciones. Nuevo NarrativeContent únicamente para composición de datos heredados.
- AGENTS.md añade normas permanentes de consecuencias/convergencia, identidad/cinemática, idempotencia y pruebas incrementales.

La etapa funcional verificada se conservó en commit 4c4b191; documentación, capturas y pulido del texto del límite se guardan en un commit posterior.

## Archivos

Nuevos: data/narrative/fall.json; scripts/narrative/narrative_content.gd; tests/test_iteration6.gd y test_iteration6_visual.gd; assets/art/fall_props.png e importación; assets/art/cinematics/separation.png e importación; cuatro WAV/importaciones wind/embers/alarm/blast; CHAPTER_1.md, CINEMATICS.md, ART_ITERATION_6_PROMPTS.json, este registro y nueve capturas iteration6_*.png.

Modificados: AGENTS.md, README.md, settlement.json, main.gd, MissionFlowController, ConditionEvaluator, StorySession, ExplorationController/Actor/AmbientActor/Atmosphere, tools/generate_audio.py, assets/audio/README.md, ARCHITECTURE.md, NARRATIVE_SYSTEM.md, CREATING_MISSIONS.md y EXPLORATION.md. Las importaciones de capturas anteriores generadas por Godot se conservan como metadatos, no como recursos de runtime.

Sin cambios en recursos/estadísticas tácticas, BattleManager, EnemyAI, habilidades, GridManager, BFS, objetivos ni HUD táctico. No se sobrescribieron cambios ajenos.

## Pruebas ejecutadas

Inicial: test_story.gd, 38/38. No se ejecutó toda la suite al empezar.

Validación final seleccionada:

| Suite | Checks | Fallos |
|---|---:|---:|
| test_iteration6 | 215 | 0 |
| test_story | 38 | 0 |
| test_exploration_physics | 13 | 0 |
| test_iteration4 | 187 | 0 |
| test_iteration5 | 53 | 0 |
| **Total** | **506** | **0** |

Motivo de la ampliación: cambios en intérprete/condiciones, flujo de resultados y cuerpo exploratorio compartido. No se ejecutaron suites tras cada edición: se empezaron con narrativa, luego casos nuevos, física y finalmente intro/rutinas/UI directamente afectadas.

La suite nueva cubre resultado abierto rechazado, señal real de victoria/resultados, derrota/reintento, cuatro combinaciones narrativas, civil ausente aunque advertido, superviviente no advertido, captura mediante acciones de movimiento y tarjeta, terminal, dos pistas distintas, seis órdenes, pista repetida, colisiones, acceso, estado restaurado, no reaparición de Lira, callbacks duplicados y límite sin nuevo combate. Los resultados se preparan con fixtures de PV; no son partidas tácticas completas ni playtesting de equilibrio.

Omitidas deliberadamente: test_battle, test_maps, test_matches, test_presentation y test_iteration2, además de las capturas históricas. No cambiaron reglas/estadísticas/IA/BFS/turnos/condiciones/HUD táctico y no se detectaron regresiones que justificaran repetir simulaciones. No se eliminaron ni deshabilitaron pruebas existentes.

Render real: test_iteration6_visual terminó con salida 0, OpenGL en NVIDIA RTX 4060, cinco beats y cuatro capturas jugables. Se inspeccionaron refuerzos, fuego, captura, despertar, capítulo, ruinas, pista y final. Una retención de audio al cerrar detectada en la primera captura se corrigió; la ejecución final no tiene avisos ObjectDB/recursos. La última revisión visual ajustó la formación militar, sustituyó llamas geométricas por el atlas original y dejó el final en lenguaje narrativo.

La importación headless del editor conserva el error ambiental previo de safe-save de preferencias; los recursos se importaron y todas las pruebas de runtime/captura anteriores terminaron correctamente. No se presenta ese import con código 1 como una prueba exitosa. No se exportó ejecutable.

## Evidencia visual

- screenshots/iteration6_reinforcements.png: fuerza superior y transportes.
- iteration6_burning.png: edificios/maquinaria bajo ataque.
- iteration6_capture.png: separación representada, no texto sustitutivo.
- iteration6_awakening.png: aldeano atendiendo a Gael.
- iteration6_chapter.png: título posterior al despertar.
- iteration6_ruins_witness.png / iteration6_ruins_alone.png: variantes explorables.
- iteration6_clue.png / iteration6_north_boundary.png: investigación y límite.

Arte nuevo generado con herramienta integrada image_gen (skill imagegen), prompts/rutas en ART_ITERATION_6_PROMPTS.json. Atlas RGBA de 1254×1254 con cuatro props; fuego reutilizado de environment.png, no de la referencia. Audio nuevo sintetizado original, sin dependencias externas de ejecución.

## Límites y próximos pasos

- Revisar manualmente ritmo de 3–5 minutos, mezcla de audio y navegación prolongada. Las pruebas aceleradas/capturas no sustituyen una sesión humana.
- La caída utiliza rotación de sprite y el rig por piezas heredado; faltan frames dedicados de caída/levantarse y movimiento militar. No se presentan como animaciones dibujadas finales.
- No hay guardado/carga en disco: persistencia actual compartida y snapshot/restore en memoria, sin prometer reanudar después de cerrar el juego.
- La ilustración y props están integrados; no hay vídeo, música nueva, inventario completo ni explicación del destino/origen energético.
- El viejo puente industrial y el puesto de control quedan para una siguiente misión. No se construyeron mapas vacíos para representarlos.

El flujo funcional pedido está implementado y verificado; quedan pulido de animación y playtesting manual. Retomar desde esos límites sin repetir la implementación.

## Ejecutar

F5 → Iniciar historia → ganar combate → Continuar historia en resultados. Confirmar diálogos con sus botones; la tarjeta de captura/título permite Continuar. Tras el despertar, WASD/flechas/Shift y clic; sin testigo investigar dos pistas y usar Partir hacia el norte.

Prueba nueva: `godot --headless --path . --script res://tests/test_iteration6.gd`. Capturas: `godot --path . --script res://tests/test_iteration6_visual.gd`. Ejecutar únicamente las suites adicionales justificadas por el cambio. Consultar CHAPTER_1.md y CINEMATICS.md para contenido/estado/contratos.
