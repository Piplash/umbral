# Validación — 4 de noviembre de 2026

**Informe vigente:** `ARCHITECTURE_TESTING.md`. La configuración reutilizable de mapas y misiones suma 1.230 aserciones sin fallos, cuatro partidas completas de reglas y veinte capturas renderizadas. Se preservan abajo los informes de etapas anteriores como histórico.

**Informe vigente de iteración 2:** `ITERATION2.md`. Se añaden movimiento por ruta real, amenazas, deshacer, pronóstico y audio. Resultado: 396 aserciones sin fallos (221 + 27 + 148), dos partidas completas de reglas, una derrota animada en escena y doce capturas renderizadas. Los párrafos siguientes se conservan como registro de etapas anteriores.

**Actualización del rediseño:** los apartados originales de este archivo describen la validación del primer prototipo. La nueva presentación ya suma 27 comprobaciones adicionales (248 en total, sin fallos), dos partidas completas sin fallos y ocho capturas renderizadas y revisadas a 960×540 y 1280×720. El informe vigente de archivos, recursos, resultados y limitaciones está en `REDESIGN.md`. Las suites finales de ejecución normal no emiten errores ni advertencias; se mantiene la incidencia de configuración del editor descrita abajo. La revisión física de una partida completa solo con teclado y la exportación Windows siguen pendientes.

Motor real: **Godot 4.2.2 stable**, Windows, renderizador Compatibility / OpenGL 3.3. No se utilizaron dependencias externas para el juego.

## Ejecutado

- Importación headless del editor: registró y compiló las clases. La primera pasada encontró dos colisiones de nombres con métodos nativos; se corrigieron. El entorno restringido impidió inicialmente escribir la configuración en AppData; se redirigió `APPDATA` a `.godot/runtime` solo en los procesos de prueba. El editor aún emitió un error de guardado seguro de configuración; no es un error de scripts. Las suites y la ejecución normal funcionan sin ese error.
- `tests/test_battle.gd`: **221 comprobaciones, 0 fallos**. Incluye carga de escena, menú, batalla, pausa, resultados, reinicio y regreso al menú; tablero, posiciones válidas, BFS, alcance, obstáculos y ocupación; daño, redondeo de defensa, curación máxima, enfriamientos exactos, bloqueo de acciones repetidas y movimiento después de atacar; IA, interferencia, captura y condiciones finales.
- `tests/test_matches.gd`: **2 partidas completas, 0 fallos**. Victoria en **7 turnos**, 34 puntos de daño recibido, 3 habilidades utilizadas y captura 0/3. El agente de prueba usa comandos públicos de selección, movimiento y acciones y las activaciones normales de IA; no modifica PV ni posiciones para obtener esa victoria. Derrota por captura 3/3 en el **turno 4** al dejar actuar a los enemigos.
- Ejecución real con ventana: carga del juego y observación del tablero, unidades, coordenadas, resaltados, estadísticas, acciones y registro. Se observó la partida avanzar hasta turno 4 y captura 2/3 mientras el usuario interactuaba. No se atribuyen esas entradas a la automatización: el control del equipo detectó actividad del usuario y se dejaron de enviar entradas.

## Alcance y pendientes

La carga y las transiciones de menús se comprobaron por código de escena en headless; la inspección visual cubrió el tablero, no todos los menús ni todos los estados. Los retoques finales de interpolación y tooltips se verificaron mediante carga y pruebas, sin interrumpir la partida abierta del usuario. No se ha completado manualmente una partida íntegra solo con teclado ni se han cronometrado partidas de personas. No se verificó un ejecutable exportado, sonido, otras versiones de Godot ni diferentes factores de escala de pantalla.

Las comprobaciones del BFS recorren varios destinos y pasos, por eso el total de asercciones es mayor que el número de casos conceptuales. Las pruebas de victoria y derrota también se ejercitan aisladas en la primera suite; la segunda verifica recorridos completos desde el estado inicial.
