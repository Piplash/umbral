# Efectos originales

Quince WAV PCM mono, 16 bits, 22050 Hz. Se generaron por síntesis determinista con la biblioteca estándar de Python en `tools/generate_audio.py`: osciladores, barridos de frecuencia, ruido con semilla fija y envolventes suaves. No contienen muestras, música ni grabaciones comerciales. El juego carga los WAV importados por Godot; Python no es una dependencia de ejecución.

- Combate: attack, impact, damage, heal, jam, unit_defeat, victory, defeat.
- Interfaz: navigate, select, confirm, cancel, invalid, turn, pause.

La cola de SFX reproduce sucesivamente ataque, impacto, daño y derrota cuando corresponden. UI usa su propio bus/reproductor. Los ajustes de volumen/mute se encuentran en pausa → Ajustes de audio.
