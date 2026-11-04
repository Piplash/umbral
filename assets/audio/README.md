# Efectos originales

Quince WAV PCM mono, 16 bits, 22050 Hz. Se generaron por síntesis determinista con la biblioteca estándar de Python en `tools/generate_audio.py`: osciladores, barridos de frecuencia, ruido con semilla fija y envolventes suaves. No contienen muestras, música ni grabaciones comerciales. El juego carga los WAV importados por Godot; Python no es una dependencia de ejecución.

- Combate: attack, impact, damage, heal, jam, unit_defeat, victory, defeat.
- Interfaz: navigate, select, confirm, cancel, invalid, turn, pause.

La cola de SFX reproduce sucesivamente ataque, impacto, daño y derrota cuando corresponden. UI usa su propio bus/reproductor. Los ajustes de volumen/mute se encuentran en pausa → Ajustes de audio.

## Ambiente narrativo (iteración 6)

Se añadieron wind, embers, alarm y blast, también síntesis original con biblioteca estándar. Regenerar solo estos con `python tools/generate_audio.py --only wind embers alarm blast`; sin --only se conservan las quince fórmulas anteriores y se generan los diecinueve cues. Wind usa ruido filtrado, embers impulsos aleatorios deterministas, alarm alterna tonos y blast un barrido/ruido con envolvente. Son efectos procedurales, no grabaciones ni música final.

StorySession utiliza un reproductor ambiental local en SFX, con volumen/fundidos configurados por acciones; respeta los ajustes/mute existentes y libera stream al salir. La cola de sonidos tácticos no se modificó.
