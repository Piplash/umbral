# Auditoría previa a la configuración de mapas y misiones

Se inspeccionaron `scenes/main.tscn`, `project.godot`, scripts, atlas, audio y las suites existentes antes de refactorizar. No existe repositorio Git configurado; se guardó una copia completa del código, arte, escenas, pruebas y documentación en `backups/architecture-before-*`. Esta carpeta está excluida de Godot y Git.

## Arquitectura encontrada

La única escena principal es `scenes/main.tscn`, con `main.gd`: crea menú, HUD y BoardView por código. No hay una segunda escena de combate ni escenas por misión. BattleManager coordina objetos RefCounted: GridManager, TurnManager, CaptureSystem y BattleResults. MovementSystem calcula BFS; CombatSystem aplica daño; AbilitySystem controla curación/enfriamientos; EnemyAI consulta rutas y elige objetivos; ThreatSystem deriva alcances y peligro. BoardView anima rutas y efectos. SettlementView dibuja piezas ambientales por capas. ArtLibrary proporciona regiones de atlas; UmbralAudio administra buses, WAV y preferencias. Las señales route_requested, animation_requested, impact, changed y finished separan resolución lógica de animación e interfaz.

## Acoplamientos específicos encontrados y plan mínimo

| Componente | Dependencia existente | Cambio necesario |
|---|---|---|
| GridManager | Tamaño 8×8 y seis obstáculos iniciales | Recibir datos del mapa activo |
| BattleManager | Cinco spawns, civil en units[4], victoria con dos enemigos y captura 3 | Recibir misión y delegar evaluación de objetivos |
| TacticalUnit | id de instancia igual al arquetipo y tabla fija de estadísticas | Definiciones reutilizables y separar identidad, arte y comportamiento |
| EnemyAI / ThreatSystem | Identificadores soldier/captor/civil | Roles de comportamiento y objetivo asignado por misión |
| BoardView | range(8), TILE/ORIGIN fijos, escalas de sprites de 46 px | Geometría centralizada a partir del mapa y dimensiones activas |
| SettlementView | Composición artística y coordenadas del asentamiento | Conservar como presentación específica referenciada por el mapa; extraer base visual genérica |
| main.gd | BattleManager.new sin configuración, cinco unidades por índice y textos 2/3 fijos | Selector de misión, selección por equipo/objetivo y textos derivados de configuración |

Los cálculos de daño, enfriamientos, BFS y alternancia de fases ya son reutilizables. No necesitan una segunda implementación. El controlador sigue compartido; la composición artística original se conserva. La documentación final en ARCHITECTURE.md debe describir solo lo implementado y distinguir extensiones pendientes.
