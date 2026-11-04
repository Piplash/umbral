# Capítulo I — Los que quedaron

## Acceso y flujo

F5 → Iniciar historia → exploración/decisiones → primer combate 8×8. Tras una victoria, el panel de resultados ofrece **Continuar historia**. Ese botón entrega el resultado registrado al mismo flujo narrativo. Una derrota solo conserva reintento/menú y no activa destrucción.

La continuación contiene: alivio breve → ruido mecánico/refuerzos → incendio y ocupación → consecuencias de la terminal → Lira ayuda a Elena → tropas bloquean la salida → Gael corre e intenta rescatarla → impacto/caída → escolta al transporte e ilustración de separación → partida del vehículo → negro/silencio → ruinas/despertar → diálogo condicional → título del Capítulo I → exploración.

Los tiempos fijos configurados suman aproximadamente 168–176 segundos, según rama, más el avance manual de diálogos: objetivo de 3–5 minutos a lectura normal. El ritmo humano no se midió en una sesión manual completa. Las pruebas aceleran playback_speed para comprobar integración, sin cambiar los tiempos de producto.

No se añade segundo combate, puente jugable, puesto militar ni asentamiento nuevo. Partir hacia el norte finaliza en un **CONTINUARÁ** narrativo; se puede volver a explorar las ruinas o ir al menú.

## Consecuencias que se conservan

| Hecho | Fuente única | Consecuencia observable |
|---|---|---|
| Victoria | results.settlement.outcome.status | Habilita continuación, sin inferirla de un booleano del botón |
| Civil vivo y no capturado | results.settlement.villager_survived | Aparece en alivio/despertar; muerto/capturado no tiene actor ni cuerpo |
| Advertencia | flags.villager_warned | Reconocimiento solo si además sobrevivió; otro texto si sobrevivió sin aviso |
| Terminal preparada | prepared.terminal | Barrera y escape de vecino/niño durante el ataque; escape_group_saved queda registrado |
| Violencia de la invasión | Secuencia configurada | El reparador cae fuera de un detalle gráfico explícito y repairer_killed se registra; sigue habiendo pérdidas aunque funcionara la barrera |
| Lira capturada | flags.lira_captured | Sale del escenario; no muere, cambia de bando ni revela destino |
| Testimonio | flags.convoy_route_source=witness | Ruta conocida, viejo puente industrial/puesto mencionados y vendas básicas |
| Investigación | flags.convoy_route_source=investigation | Dirección probable al norte, sin conocimiento detallado del puente |

Los héroes a 0 PV al ganar están incapacitados tácticamente; se muestra agotamiento/recuperación, no se cambia el resultado táctico ni se afirma que murieron. Lira dispone de una línea de recuperación si quedó incapacitada. El civil a 0 PV sí está ausente. Los resultados originales de unidades/PV quedan conservados.

## Despertar y exploración

Con testigo: el aldeano atiende a Gael, explica el convoy del norte y el viejo puente industrial, reconoce el aviso solo cuando corresponde y ofrece vendas (prepared.basic_supplies). Es una ventaja narrativa booleana/idempotente; no se creó inventario. Puede volver a hablar con él, examinar restos o partir sin investigar.

Sin testigo: Gael despierta solo. Hay tres elementos claramente señalados:

1. Huellas del convoy, junto al acceso oriental.
2. Equipamiento de la Autoridad, junto a escombros de la plaza.
3. Registro de transporte dañado, junto a la consola.

Dos pistas distintas bastan, en cualquiera de los seis órdenes. Reexaminar no cuenta dos veces. El registro conserva solo un fragmento de ruta, no el destino. La regla deriva el contador de examined; no mantiene otra variable equivalente. Mientras no hay suficiente información, Partir hacia el norte explica que falta investigar y permite volver. La rama conserva industrial_bridge_known=false.

Las ruinas reutilizan límites/caminos, edificios reconocibles y controlador, con props dañados, restos, humo, cables y luz fría. Los escombros nuevos tienen colisiones explícitas; se comprobaron rutas de acceso y bloqueo físico. No hay rutinas cotidianas ni Lira; el testigo permanece en idle si corresponde. WASD/flechas, Shift y clic mantienen sus funciones.

## Datos y estados

settlement.json configura after_victory (id/path/entry). fall.json hereda su contenido con base_content; contiene state_catalog, secuencia aftermath, diálogos, state_rules y parches ambientales. aftermath_start, burning y ruins no son implementaciones paralelas del mapa. Los arrays se reemplazan al heredar; diccionarios se fusionan.

Estados nuevos principales: settlement_destroyed, lira_captured, chapter_1_started, convoy_route_known, industrial_bridge_known, convoy_route_source, escape_group_saved, repairer_killed y north_departure_ready. Los identificadores/condiciones/efectos están en los datos, no en ramas especiales de scripts generales. La victoria, advertencia, terminal y supervivencia conservan sus fuentes anteriores, sin duplicarlas.

MissionFlowController reclama settlement_aftermath_started una sola vez después de un resultado válido. Repetir el callback, intentar continuar una derrota o registrar de nuevo el resultado no reinicia la secuencia, no restaura datos sobre el capítulo y no duplica suministros. resume_environments selecciona ruinas al reconstruir una presentación de un estado con chapter_1_started. fall.json no hereda la intro del prólogo.

Persistencia aquí significa estado compartido y snapshot/restore en memoria. No se implementaron menú de guardado/carga ni archivos de campaña en disco. Reanudar una partida tras cerrar el programa sigue siendo trabajo futuro; no se promete esa capacidad.

## Arte y cinemática

Nuevo atlas assets/art/fall_props.png: dos edificios dañados, generador/terminal destruidos y transporte blindado. Cuatro regiones de 627×627 sobre una imagen 1254×1254 RGBA; se verificó alfa cero en márgenes y se inspeccionó el render.

Nueva ilustración assets/art/cinematics/separation.png: Gael intentando levantarse, Lira viva escoltada al transporte y otras mujeres, con ocupación e incendio no gráficos. Herramienta integrada image_gen, skill imagegen; prompts/procedencia en ART_ITERATION_6_PROMPTS.json. La referencia aprobada PNG se abrió e inspeccionó de nuevo; no se usó como fondo ni se extrajeron sus edificios/personas.

Se reutilizan sprites, atlas, HUD negro/dorado, movimiento, rutinas, diálogos y acciones. Fuego animado desde la región de llama del atlas original, vapor y luces dinámicas; el ambiente utiliza cuatro nuevos efectos sintetizados originales en SFX. Sin vídeo ni música nueva.

Las poses de caída por rotación y el rig de pasos heredado son provisionales, no fotogramas dibujados finales. Los soldados cinematográficos se desplazan con su sprite táctico existente, sin animación direccional nueva. Son pendientes de pulido, no sustitutos textuales de la separación.

## Validación incremental

Inicial: test_story.gd, 38 checks, cero fallos. Final: test_iteration6 (215), test_story (38), test_exploration_physics (13), test_iteration4 (187), test_iteration5 (53): **506 checks, cero fallos**. Se ampliaron las pruebas de exploración/intro porque cambiaron el cuerpo compartido, el intérprete y las condiciones; no se ejecutó toda la suite.

Los casos de resultado usan fixtures de PV y llaman al evaluador real de objetivos/check_end y su señal de resultado. No son partidas tácticas completas jugadas ni simulaciones de equilibrio. Cubren victoria/derrota/reintento, cuatro combinaciones narrativas (supervivencia/aviso/terminal), todos los órdenes de pistas, repeticiones, restauración, acceso y colisión. No se ejecutaron test_battle, test_maps, test_matches, test_presentation ni test_iteration2: reglas/estadísticas/IA/BFS/turnos/HUD táctico no cambiaron.

test_iteration6_visual terminó con código 0, sin avisos de recursos retenidos, en OpenGL / NVIDIA RTX 4060. Capturó cinco beats cinematográficos y cuatro pantallas jugables; se inspeccionaron imágenes, no solo carga headless. La prueba avanza diálogos y acelera la línea temporal; no sustituye playtesting humano del ritmo/audio.

Ver ITERATION_6_PROGRESS.md para archivos, pruebas omitidas y próximos pasos; CINEMATICS.md para reutilizar acciones.
