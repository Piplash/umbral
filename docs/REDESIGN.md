# Rediseño visual de UMBRAL

## Resultado

Referencia inspeccionada antes de editar y conservada en `references/umbral_visual_reference.png`. No se utiliza como fondo, textura ni recurso del combate. No había repositorio Git configurado; no se creó un commit. Las estadísticas, habilidades, mapa lógico, IA y condiciones finales se conservaron. El único añadido al gestor de combate es una señal de animación para la vista.

El nuevo escenario combina cuatro tiles de suelo y doce piezas de decoración independientes: casa de madera con ventanas cálidas, generador abandonado, ruina, árbol, cajas, rocas, cercas, arbusto, brasero, barril, pozo y estandarte. Los obstáculos visuales usan exactamente las seis coordenadas anteriores. El arte está dividido en capas, con selección, ruta y áreas translúcidas; los personajes se dibujan sobre esas áreas.

Gael y Lira tienen cabello oscuro y ropa de supervivencia; Lira lleva coleta y dispositivo. Los soldados llevan armadura oscura y visor rojo; el capturador se diferencia por piezas de cobre y su dispositivo de captura. El civil tiene cabello blanco y ropa de trabajo. Cada sprite es independiente y tiene retrato propio. El panel izquierdo muestra la composición del encuentro en un orden fijo, no una iniciativa nueva que cambie el juego.

HUD: barra superior de turno/fase/captura, lista compacta izquierda, ficha de personaje derecha con retrato y PV, menú de cinco acciones, submenú de habilidades, descripción, objetivo y barra breve de controles. El registro visible se sustituyó por un solo mensaje contextual; H abre la ayuda completa. Los iconos de acción son trazos monocromos propios, sin emojis.

Efectos: movimiento interpolado, balanceo de espera, pulso de selección, ruta al cursor, impulso de ataque, destello de daño, números flotantes, anillo de impacto/curación/interferencia, arco de interferencia, barras de PV suaves, transición de fase y desaparición de derrotados. Victoria y derrota disponen de paneles con oscurecimiento del escenario y opciones de reinicio/menú.

## Archivos

Modificados: `project.godot`, `scripts/main.gd`, `scripts/board_view.gd`, `scripts/battle_manager.gd` (señal visual), README y documentación de arquitectura/pruebas.

Creados: `scripts/art_library.gd`, `scripts/settlement_view.gd`, `scripts/ornament_panel.gd`, `scripts/tactical_action_button.gd`, `assets/art/environment.png`, `assets/art/characters.png`, `tests/test_presentation.gd`, `tests/test_visual.gd`, documentación y ocho capturas en `docs/screenshots/`.

## Verificación real

- Godot 4.2.2 en Windows, OpenGL 3.3, GPU NVIDIA RTX 4060.
- Reglas y escenas: 221 comprobaciones sin fallos.
- Partidas completas: victoria en 7 turnos (34 de daño recibido, 3 habilidades, captura 0/3) y derrota por captura en turno 4. Resultados iguales a los del prototipo anterior.
- Presentación: 27 comprobaciones sin fallos. Capas, recursos y transparencia, conversión de coordenadas, submenú de habilidades, descripción dentro del panel, bloqueo de órdenes durante movimiento, pausa de la IA, reanudación y cancelación de corrutinas al reiniciar.
- Ocho capturas con renderizador real: menu, battle, lira_abilities, help, victory, defeat, battle_960, menu_960. Revisadas para comprobar composición y texto. Los estados de victoria/derrota de esta suite se preparan expresamente para revisar sus pantallas; las partidas completas se validan por separado en `test_matches.gd`.
- Las suites de juego, presentación y captura finalizan con código 0, sin errores ni advertencias en sus últimas ejecuciones. La importación del editor mantiene el error ambiental de guardado seguro ya documentado en `TESTING.md`; no se cambió la seguridad de Windows.

## Limitaciones visuales

La dirección y composición se aproximan a la referencia, pero no son una reproducción píxel por píxel. Los atlas son arte generado, con irregularidades de contorno, detalle y densidad de píxel. La corrección de transparencia se hizo con la herramienta de imágenes; la presencia de alfa real se comprueba en pruebas. Las texturas del suelo se repiten y las luces son simulaciones suaves dibujadas, sin sombras dinámicas.

Los personajes tienen una sola vista; los estados de animación están preparados pero no hay fotogramas dibujados por dirección ni animaciones completas de espada o caída. Esos recursos deben sustituirse por spritesheets revisadas por un artista para un acabado comercial definitivo. Los marcos son ornamentales pero más sencillos que los de la referencia. No se añadió nivel/experiencia aunque la referencia muestre «Nv. 1», porque no existe esa mecánica.

Se verificaron capturas a 960×540 y 1280×720, no todas las relaciones de aspecto, escalas de Windows ni pantalla completa. El escalado conserva proporción y usa nearest para texturas; factores no enteros pueden producir píxeles de anchura desigual. Las pruebas de teclado usan eventos del juego y comandos de escena, no una partida manual completa exclusivamente con teclado. No se exportó un ejecutable.
