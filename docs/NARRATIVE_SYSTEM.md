# Narrativa, decisiones y preparación

WorldState mantiene diccionarios serializables por IDs: flags, choices, conversations, examined, prepared, characters, events y results. snapshot/restore hacen copias independientes. No hay menú de guardado/carga ni persistencia de campaña en disco.

ConditionEvaluator compara condiciones `{bucket,key,value}` mediante igualdad y AND, sin ejecutar expresiones. EffectResolver aplica escrituras idempotentes en buckets permitidos. Las opciones de diálogo solo entregan esos datos; no contienen código especial para el aldeano.

StorySession presenta conversaciones configuradas con speaker, art opcional, lines, choices, conditions y effects. Completar una conversación registra su ID; examined_id registra objetos examinados. El aldeano ofrece los textos solicitados y registra `villager_warned`; omitir la conversación equivale a false.

BattlePreparationResolver copia misión, mapa, cada aparición y cada definición explícitamente (sin confiar en copias profundas de arrays Resource de Godot 4.2). Aplica modificadores combinables de unit_behavior, barrier, unit_position y add_unit. El civil preparado tiene movimiento 2: wander por defecto, seek_shelter si fue advertido. La barrera está en (5,3); la base no cambia. Los mensajes de preparación se obtienen de modificadores realmente aplicados.

NeutralAI comparte BFS y ThreatSystem: Wander elige destinos deterministas sin estrategia protectora; SeekShelter compara rutas legales y peligro, prefiriendo posiciones sin amenaza. Los neutrales actúan después de los enemigos y antes de renovar aliados. Siguen siendo objetivos de captura y permanecen dentro del tablero. Refugio configurado: (0,3).

MissionFlowController consolida decisiones, crea una misión preparada y guarda el estado previo. StorySession reproduce acciones de secuencia: camera, sound, show/hide, move, dialogue, wait, wait_event, fade, scene y battle. Los movimientos y fundidos esperan señales de Tween; los diálogos esperan dialogue_finished. La primera secuencia enfoca la entrada, reproduce maquinaria, muestra/mueve tropas, presenta reacciones y carga el mismo combate 8×8 tras el fundido.

Al terminar, se restaura el snapshot precombate y se registra un resultado estructurado por misión: outcome, unidades/PV, supervivencia del aldeano, preparaciones y eventos. Reintentar restaura las decisiones previas, elimina el resultado del intento anterior y reinicia el mismo combate preparado. No hay recompensas duplicadas. Una victoria narrativa ahora ofrece Continuar historia hacia la caída y el Capítulo I; la derrota mantiene el reintento.

El controlador táctico no conoce NPC de exploración. El 10×10 permanece disponible exclusivamente para tests/API de desarrollo; el selector está oculto en la interfaz normal. Las modalidades futuras de reclutamiento, relaciones, rutas y reputación no están implementadas.

## Consecuencias y prólogo (iteración 4)

El civil advertido comienza en (1,3), conserva movimiento 2 y seek_shelter hacia el refugio (0,3). Sin advertencia aparece expuesto en (4,3), movimiento 2 y wander. La cinemática usa condiciones sobre villager_warned: reconoce la advertencia y camina hacia protección, o reacciona con confusión. El texto de sorpresa también es válido cuando se omitió la conversación. Los mensajes tácticos proceden únicamente de los modificadores aplicados. La terminal mantiene su barrera (5,3), sin duplicar mapa ni misión.

`add_unit` incorpora scout en (7,0), desde data/units/scout.tres: 22 PV, ATQ 6, DEF 1, MOV 5, comportamiento flanker. Reutiliza sprite/animaciones de soldado, rutas, rangos, ataques y turnos; se distingue por nombre y color táctico. El recurso base conserva sus cinco participantes para fixtures; la misión preparada de historia tiene seis, tres enemigos.

`intro` contiene cuatro acciones intro_card (9/9/8/8 segundos), previas a la exploración: presentación energética, asentamientos, Gael/Lira y PRÓLOGO / ANTES DEL SILENCIO. Cada tarjeta admite text, seconds y prop opcional; muestra texto progresivo y capas reutilizadas con pan/fundido. No son ilustraciones cinematográficas finales. Continuar cambia tarjeta; Saltar introducción sale de toda la introducción. La generación de tarjeta invalida clics antiguos. El control y las rutinas permanecen bloqueados hasta el fundido final. Reiniciar la batalla no crea otra StorySession; una nueva partida sí reproduce el prólogo.

Las condiciones de acción se evalúan en play_actions, compartido con la secuencia de ataque. move puede orientar/animar actores ambientales registrados sin dejar que su rutina compita con el tween. Los actores de tropas de la secuencia conservan el arte táctico anterior. No se añadió vídeo, sistema narrativo paralelo ni persistencia en disco.

## Presentación ilustrada (iteración 5)

Se preservan los tres textos y el título, 34 segundos de duración configurada, así como la lógica de decisiones/ataque/preparación. Las primeras tres intro_card referencian assets/art/cinematics/city.png, refuge.png y twins.png; son ilustraciones originales de ciudad, comunidad periférica y hermanos, sin revelar el origen energético. La cuarta usa title=true y el texto existente.

Campos de intro_card: image (Texture2D), seconds, text, zoom_from/zoom_to, pan [x,y], transition (entrada), audio opcional (cue existente) y title. Pan y zoom se ejecutan juntos durante la tarjeta; salida gradual y entrada fundida permiten cortes suaves. La narración progresiva se integra en el tercio inferior, con velo para legibilidad y botones Continuar/Saltar. Los finales se encadenan en play_actions; las acciones scene/battle/effects siguen disponibles en el intérprete general, sin crear lógica específica por ilustración. La música no se añadió porque no había un recurso apropiado.

La ayuda de exploración no aplica efectos ni marca conversaciones. Los habitantes retirados de escena conservan configuración y diálogos en datos; no se borra contenido narrativo. La terminal conserva sus choices/effects y la misma preparación de batalla pese a cambiar su representación.

## Caída y Capítulo I (iteración 6)

El resultado real del primer combate determina la presencia del aldeano. La advertencia sigue en flags.villager_warned y la terminal en prepared.terminal; nunca se usan para inferir supervivencia. after_victory se configura en settlement.json; el contenido fall.json contiene el catálogo central de estados nuevos, las ramas y los entornos. No hay cadenas de estado de este capítulo dispersas en sistemas generales.

Tras reconocer la victoria en Continuar historia: breve alivio, fuerza superior, ataque visual, consecuencias de la terminal, intento de rescate, captura de Lira, inconsciencia, despertar y título del Capítulo I. Ganar no implica que el civil esté vivo. Si no lo está, no tiene actor, cuerpo ni diálogo durante la continuación. Si fue advertido y sobrevivió reconoce el aviso; un superviviente no advertido tiene texto diferente.

Con testigo, convoy_route_known e industrial_bridge_known se establecen por diálogo y convoy_route_source=witness; basic_supplies es una ventaja narrativa booleana, sin inventario. Sin testigo, dos elementos examinados distintos activan convoy_route_known por state_rules, source=investigation e industrial_bridge_known sigue false. Reexaminar no aumenta un contador: count deriva de claves examined únicas. Ambas rutas habilitan salida al norte conservando distinto detalle.

Las ruinas solo contienen pistas y, condicionalmente, al testigo. Lira y los civiles cotidianos no reaparecen. El título no repite la intro y un estado restaurado selecciona las ruinas. No hay todavía guardado/carga en disco, segundo combate, puente jugable ni puesto de control.

Los héroes a 0 PV en el combate representan incapacitación táctica; la continuación muestra recuperación/agotamiento antes de la captura canónica, sin alterar sus PV ni el snapshot del resultado. La muerte/captura del civil sí controla su ausencia. No se convierte a Lira en enemiga ni se revela su destino.
