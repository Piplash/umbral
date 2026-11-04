# Narrativa, decisiones y preparación

WorldState mantiene diccionarios serializables por IDs: flags, choices, conversations, examined, prepared, characters, events y results. snapshot/restore hacen copias independientes. No hay menú de guardado/carga ni persistencia de campaña en disco.

ConditionEvaluator compara condiciones `{bucket,key,value}` mediante igualdad y AND, sin ejecutar expresiones. EffectResolver aplica escrituras idempotentes en buckets permitidos. Las opciones de diálogo solo entregan esos datos; no contienen código especial para el aldeano.

StorySession presenta conversaciones configuradas con speaker, art opcional, lines, choices, conditions y effects. Completar una conversación registra su ID; examined_id registra objetos examinados. El aldeano ofrece los textos solicitados y registra `villager_warned`; omitir la conversación equivale a false.

BattlePreparationResolver copia misión, mapa, cada aparición y cada definición explícitamente (sin confiar en copias profundas de arrays Resource de Godot 4.2). Aplica modificadores combinables de unit_behavior y barrier. El civil preparado tiene movimiento 2: wander por defecto, seek_shelter si fue advertido. La barrera está en (5,3); la base no cambia. Los mensajes de preparación se obtienen de modificadores realmente aplicados.

NeutralAI comparte BFS y ThreatSystem: Wander elige destinos deterministas sin estrategia protectora; SeekShelter compara rutas legales y peligro, prefiriendo posiciones sin amenaza. Los neutrales actúan después de los enemigos y antes de renovar aliados. Siguen siendo objetivos de captura y permanecen dentro del tablero. Refugio configurado: (0,3).

MissionFlowController consolida decisiones, crea una misión preparada y guarda el estado previo. StorySession reproduce acciones de secuencia: camera, sound, show/hide, move, dialogue, wait, wait_event, fade, scene y battle. Los movimientos y fundidos esperan señales de Tween; los diálogos esperan dialogue_finished. La primera secuencia enfoca la entrada, reproduce maquinaria, muestra/mueve tropas, presenta reacciones y carga el mismo combate 8×8 tras el fundido.

Al terminar, se restaura el snapshot precombate y se registra un resultado estructurado por misión: outcome, unidades/PV, supervivencia del aldeano, preparaciones y eventos. Reintentar restaura las decisiones previas, elimina el resultado del intento anterior y reinicia el mismo combate preparado. No hay recompensas duplicadas ni siguiente misión automática.

El controlador táctico no conoce NPC de exploración. El 10×10 permanece disponible exclusivamente para tests/API de desarrollo; el selector está oculto en la interfaz normal. Las modalidades futuras de reclutamiento, relaciones, rutas y reputación no están implementadas.
