# Iteración 5 — registro de implementación

Fecha: 2026-11-04. Proyecto existente, Godot 4.2.2 / Windows / Compatibility. Dirección: El último refugio.

## Auditoría y recuperación

Se leyeron AGENTS.md, arquitectura, exploración y narrativa; se inspeccionaron escenas/scripts/atlas y Git. Inicio en 9e1c125, sin cambios salvo la referencia PNG aportada. La ruta sin extensión no existía; se localizó y abrió assets/references/486a0401-c42c-47e2-8b21-55ad25ebc5e0.png y se comparó realmente con la exploración anterior. Análisis en ART_DIRECTION.md.

Línea base ejecutada antes de modificar código: 1.452 checks sin fallos y 12 partidas simuladas sin fallos. El commit e98fc1b conserva referencia, auditoría y normas artísticas antes de los cambios grandes. Se mantuvieron los screenshots de iteración 4 como evidencia histórica; las capturas nuevas tienen prefijo iteration5_.

## Etapas completadas

1. Auditoría y reglas permanentes: referencia real, diferencias de composición/densidad/arquitectura/tecnología/personajes/luz/atmósfera y AGENTS.md ampliado sin retirar normas anteriores.
2. Escenario: mismo mundo 1080×780, plaza empedrada de contorno poligonal, casas/puesto/pozo agrupados y caminos conectados. Sin nuevo mapa ni uso del concepto como fondo.
3. Tecnología: transformador, consola con acumuladores, rover energético reutilizado, taller con tanque/ventilación, generador existente y cables conectados. Props originales individuales, con profundidad y colisiones explícitas.
4. Población: ocho NPC activos (Lira, aldeano, vecino, Elena, reparador, niño, perro, gallina) y Gael. Mara, transportista, vecino mayor y otra gallina permanecen configurados en reserva, con diálogos intactos. Rutinas compartidas; frecuencia de pasos proporcional a velocidad y sombra de apoyo.
5. Luz/interfaz: CanvasModulate frío y PointLight2D cálidos/cian, vapor discreto, HUD pequeño negro/dorado y ayuda ?. Sin cambios en el HUD táctico.
6. Introducción: tres ilustraciones originales (ciudad, asentamientos, hermanos), pan/zoom/fundidos, texto progresivo, título sobre oscuro, sonido existente y salto. Mismo intérprete intro_card/play_actions. No se reveló ni eliminó contenido narrativo.
7. Integración: navegación física, acceso a actores, rutinas/diálogos, terminal/preparación, ataque/transición, combate/IA/captura/victoria/derrota/reintento preservados en las pruebas.
8. Documentación: arquitectura, exploración, narrativa, rutinas, dirección artística, prompts, revisión visual y este registro.

## Archivos y recursos

Nuevos de runtime:

- scripts/exploration/exploration_prop.gd: presentación individual con y-sort y caché de texturas.
- scripts/exploration/exploration_atmosphere.gd: ambiente/luces/vapor configurables.
- assets/art/refuge_props.png + import: seis props de infraestructura/vida comunitaria.
- assets/art/refuge_domestic.png + import: ropa, huerto y banco detallados.
- assets/art/cinematics/{city,refuge,twins}.png + import: ilustraciones exclusivas del prólogo.

Modificados de runtime: data/narrative/settlement.json, ExplorationController, ExplorationScenery, DirectionalVisual y StorySession. Sin cambios en estadísticas, recursos tácticos, BattleManager, IA ni habilidades.

Documentación: AGENTS.md, README.md, ARCHITECTURE.md, EXPLORATION.md, NARRATIVE_SYSTEM.md, NPC_ROUTINES.md; nuevos ART_DIRECTION.md, ART_ITERATION_5_PROMPTS.json, VISUAL_REVIEW_ITERATION_5.md y este registro. Referencia del usuario archivada con importación de Godot.

Pruebas: test_iteration5.gd, test_iteration5_visual.gd y ajuste del mínimo de población de test_iteration4.gd a ocho actores configurados. La cobertura de obstáculos/acceso no se eliminó: el número de checks depende de la cantidad de actores y cuerpos, y aumenta con las nuevas colisiones. Capturas nuevas en docs/screenshots/iteration5_*.png.

## Pruebas finales ejecutadas

| Script en tests/ | Checks | Fallos |
|---|---:|---:|
| test_battle.gd | 221 | 0 |
| test_presentation.gd | 27 | 0 |
| test_iteration2.gd | 148 | 0 |
| test_maps.gd | 834 | 0 |
| test_story.gd | 38 | 0 |
| test_exploration_physics.gd | 13 | 0 |
| test_iteration4.gd | 187 | 0 |
| test_iteration5.gd | 53 | 0 |
| **Total** | **1.521** | **0** |

Además, test_matches.gd: 12 partidas completas, cero fallos. Dos fixtures base y cuatro combinaciones advertencia/terminal, cada una con victoria y derrota. Se mantienen exactamente los resultados tácticos previos: victorias de historia en 11/13/11/11 turnos, captura final 2/1/0/0; derrotas pasivas en turnos 4/4/6/6. No se modificaron PV/posiciones para forzar resultados de esas simulaciones.

test_iteration5.gd verifica: población en reserva y diálogos, regiones de atlas, separación ilustración/mapa/referencia, props Godot individuales/y-sort, luces cálidas y frías, cámara configurada, frecuencia de pasos según velocidad, bloqueo/cierre de ayuda, aproximación real a terminal y efecto de preparación, zoom real del prólogo y salto seguro. La suite anterior también ejecuta rutinas y ambas variantes de la secuencia de ataque.

Render real: test_iteration5_visual.gd terminó con código 0 en OpenGL / NVIDIA RTX 4060. Capturas de los cuatro planos, exploración con rutinas, ayuda y terminal, inspeccionadas visualmente; comparación con el concepto en VISUAL_REVIEW_ITERATION_5.md. No confundir esta prueba gráfica automatizada con una sesión manual completa.

La importación headless del editor registra recursos/clases, pero termina con el error de safe-save de preferencias ya presente en este entorno restringido. Las ocho suites de runtime y las capturas sí terminan con código 0. No se cambió la configuración de seguridad para ocultar ese error y no se exportó ejecutable Windows.

## Límites y pendientes

- El rig direccional heredado por piezas continúa provisional. Se conserva la orientación verdadera, se sincroniza frecuencia y se añaden sombras; faltan frames dibujados para un acabado final de caminar/correr.
- Revisar manualmente durante una sesión prolongada la sensación de movimiento, congestión, luz en distintos monitores y navegación con teclado/ratón. Los checks/capturas no sustituyen playtesting humano.
- El empedrado conserva repetición y tono más frío que el concepto; se reutilizaron los tiles existentes. La escena tiene menor densidad que la referencia, de acuerdo con la reducción solicitada de población.
- No hay sombras dinámicas de oclusión, normal maps, música nueva ni animación interna de las ilustraciones. La presentación usa capas, texto y cámara, sin vídeo.
- No quedan los huertos/bancos/ropa geométricos como arte activo: se sustituyeron. Los sprites de personas y su rig son los recursos provisionales heredados que requerirían reemplazo para mayor acabado.

El rediseño está implementado y verificado en runtime/capturas; el pulido de animación y la revisión humana permanecen abiertos. Retomar desde estos pendientes sin rehacer sistemas ni generar otro mapa.

## Ejecución

Abrir project.godot con Godot 4.2.2, F5 → Iniciar historia. Continuar/Saltar controla el prólogo. WASD/flechas, Shift y clic para explorar; ? abre ayuda; Continuar historia confirma el ataque. El único tablero jugable sigue siendo 8×8.

Pruebas: `godot --headless --path . --script res://tests/test_iteration5.gd` y las suites de la tabla; `godot --headless --path . --script res://tests/test_matches.gd`. Capturas: `godot --path . --script res://tests/test_iteration5_visual.gd`, sin --headless. Ajustar solo el nombre del ejecutable a la instalación local.
