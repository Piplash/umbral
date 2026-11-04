# UMBRAL — Reglas permanentes del proyecto

## Identidad

UMBRAL es un RPG táctico por turnos con narrativa de ciencia ficción distópica. Utiliza Godot 4.x, GDScript y Windows como plataforma principal. Su estética es pixel art oscuro, decadente y atmosférico, con perspectiva cenital clásica. Mantener compatibilidad con la versión utilizada por el proyecto, actualmente Godot 4.2.2; no adoptar API posteriores sin una migración solicitada y verificada.

## Principios arquitectónicos obligatorios

1. Todas las mecánicas de combate deben ser reutilizables entre mapas y misiones.
2. No introducir reglas de un escenario en sistemas generales.
3. Separar datos, lógica de negocio y presentación visual.
4. Mantener independientes movimiento, turnos, habilidades, combate, IA y objetivos.
5. Evitar dependencias circulares y clases monolíticas.
6. Usar escenas y recursos reutilizables de Godot.
7. Usar GDScript tipado cuando corresponda.
8. Priorizar señales y eventos para comunicar sistemas desacoplados.
9. No duplicar lógica existente.
10. Mantener compatibilidad con la versión de Godot del proyecto.

## Mapas

- Admitir dimensiones diferentes. Cada mapa define transitabilidad y obstáculos.
- Ubicar las unidades mediante datos de configuración.
- Calcular movimiento y rangos dinámicamente con la información del mapa activo y el sistema de rutas existente.
- No copiar implementaciones de combate dentro de mapas.
- La decoración no altera las reglas tácticas salvo configuración explícita.
- Definir el tamaño de casilla en un lugar centralizado por mapa y consumirlo desde allí; no mantener constantes inconsistentes en vistas, animaciones o colisiones.

## Personajes

- Definir estadísticas mediante datos reutilizables.
- Las habilidades no deben depender de nombres concretos de personajes.
- Aliados y enemigos comparten los sistemas generales de combate.
- Incorporar personajes nuevos mediante configuración y recursos.
- Separar animaciones, sprites y retratos de la lógica de combate.

## Misiones

- Las condiciones de victoria y derrota deben ser configurables; no asumir que todas las misiones exigen eliminar enemigos.
- Mantener puntos de extensión para defensa, rescate, sabotaje, supervivencia y escape, sin implementar modalidades no solicitadas.
- Evaluar objetivos mediante sistemas independientes del mapa visual.
- Los eventos narrativos deben poder reaccionar a resultados y eventos del combate sin modificar su lógica interna.

## Preservación

Antes de modificar una mecánica: inspeccionar su implementación, identificar dependencias, revisar las pruebas, implementar los cambios mínimos necesarios, comprobar las funcionalidades anteriores y documentar las decisiones arquitectónicas relevantes.

No modificar estadísticas, habilidades, reglas ni contenido narrativo salvo petición expresa de la tarea. No sustituir arte existente sin autorización. Proteger los cambios existentes antes de editar; no sobrescribir trabajo ajeno ni restaurar indiscriminadamente archivos.

## Calidad

- No dejar código de depuración visible en la interfaz final.
- No usar rutas absolutas del equipo del desarrollador en código, recursos ni instrucciones de ejecución del proyecto.
- No introducir dependencias externas innecesarias.
- No silenciar errores: resolver su causa o documentar con precisión una limitación comprobada.
- No afirmar pruebas que no se ejecutaron. Diferenciar carga headless, simulación, renderizado y prueba manual.
- No eliminar archivos ni funcionalidades sin comprobar dependencias.
- No realizar refactorizaciones masivas sin justificación en la tarea.

## Flujo obligatorio para futuras tareas

1. Leer este AGENTS.md.
2. Consultar docs/ARCHITECTURE.md si el cambio afecta sistemas técnicos.
3. Inspeccionar el código relevante y sus pruebas.
4. Implementar cambios incrementales.
5. Ejecutar las pruebas disponibles pertinentes y corregir regresiones.
6. Actualizar la documentación si cambia la arquitectura; para mapas consultar docs/CREATING_MAPS.md.
7. Informar los archivos modificados, las pruebas realmente ejecutadas y las limitaciones pendientes.

Estas son normas generales y permanentes, no instrucciones limitadas a una iteración concreta.

## Exploración y narrativa: reglas permanentes

- Diseñar toda mecánica como reutilizable y configurable desde su primera implementación: exploración, movimiento, interacciones, diálogo, decisiones, combate, IA, cinemáticas, objetivos, misiones, inventario, progresión y persistencia. No implementar sistemas futuros hasta necesitarlos.
- Antes de incorporar funcionalidades: inspeccionar, identificar reutilización, retirar acoplamientos que impidan el cambio, implementar componentes generales, verificar regresiones y documentar. Evitar duplicación y sobreingeniería.
- Separar lógica, configuración, contenido narrativo, arte, interfaz y persistencia. Ningún controlador general debe codificar consecuencias exclusivas de un NPC o misión.
- La historia principal es dirigida, con ramificaciones y convergencias. Conservar decisiones al converger. Distinguir consecuencias tácticas, persistentes y estructurales; implementar solo las necesarias para la misión actual. No crear todavía reclutamiento, reputación, relaciones ni rutas completas.
- Definir elecciones, condiciones y efectos mediante datos. Un evaluador central comprueba condiciones y un resolver aplica efectos; la UI no decide consecuencias. No ejecutar expresiones arbitrarias de los datos.
- Priorizar profundidad narrativa. El único escenario táctico visible actualmente es el asentamiento original 8×8. Conservar dimensiones dinámicas y el 10×10 como fixture automatizado, sin selector jugable ni decoración adicional. No crear mapas de demostración sin necesidad de misión.
- Preservar Godot 4.x/GDScript, recursos, HUD, estadísticas y habilidades; no modificar mecánicas ajenas, añadir dependencias innecesarias ni inventar resultados de pruebas. Documentar contratos entre sistemas.

## Asentamiento, animación y rutinas

- Toda funcionalidad nueva será reutilizable/configurable. No duplicar controladores por NPC, personaje o escenario; compartir animación, navegación, rutinas, diálogo e interacción.
- Priorizar mapas compactos, legibles y organizados intencionalmente. No ampliar superficies para evitar diseñar su distribución; la decoración debe comunicar función, actividad, cultura o historia.
- Separar movimiento y representación. Orientar según velocidad real o interacción; idle conserva orientación. Admitir idle/walk/run/interact configurables. No simular arriba con inversión vertical ni resolver todas las direcciones solo con flip horizontal. Los pasos no se reinician cada frame.
- Las rutinas ambientales serán configurables y compatibles con navegación, colisiones, diálogos y eventos. Usar un coordinador compartido, no temporizadores dispersos por NPC. Suspender y reanudar durante diálogos/cinemáticas; no implementar horarios complejos sin necesidad.
- Conservar el combate 8×8 como único escenario actual, manteniendo dimensiones dinámicas para pruebas. No añadir mapas tácticos de demostración.
- Las introducciones y secuencias utilizarán acciones narrativas configurables reutilizables. No incrustar una cinemática rígida por escena.
- Añadir pruebas razonables y documentación de reutilización; no declarar finalizado lo que no se haya verificado. Registrar etapas y pendientes en docs/ITERATION_4_PROGRESS.md si una iteración queda parcial.
