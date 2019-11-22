# FPUG-AMXX
## Descripccion:
El famoso Pick Up Game/Competitive, con algunas características distintas, fue tomado como base el competitivo de "Counter-Strike: Global Offensive"

## Caracteristicas:
Al igual que el YAP, posee características muy similares o mas bien iguales, tiene los mismos comandos a diferencia de 1 o 2
- Modo practica/calentamiento con ronda infinita
- La puntuacion esta en el "ServerName" ~~y el GameName~~
- La puntuacion de los jugadores no se reinicia al cambiar de equipos
- ~~(Por cvar) La 1era Ronda es de cuchillo (determina que equipo va a TT)~~
- Opciones Para desarrolladores
- ~~Opcion para privatizar el PUG y evitar el uso de password~~
- Al hacer el "intermission", al cambio de equipos se evita otra vez el .ready y no se reinicia las puntuaciones en el scoreboard
- Sonidos tomados del CS:GO
- Al igual que el CS:GO, tiene un breve intermission mas dimanico
- Se puede hacer votaciones personalizadas usando addons externos
- Rondas Extras si queda empatada la partida
- Chat Global (puede desactivarse)

## CVARS
|Nombre|Def|Min|Max|Descripcion|
|:-----|:-:|:-:|:-:|:----------|
|pug_maptype|1|0|2|Archivo de lectura de mapas<br/>`0` Directorio<br>`1` maps.ini<br>`2` mapcycle.txt|
|pug_legacychat|0|0|1|Activa el comportamiento de chat como viene en el juego (solo se comunican vivos con vivos, muertos con muertos)<br>`0` Activa Chat Global<br>`1`Desactiva Chat Global|
|pug_players|10|6|32|Minimo de jugadores que se necesita para empezar la partida|
|pug_vote_countdown|15|0|~|Conteo regresivo para la siguiente votacion|
|pug_vote_map|1|0|1|Activa la votacion de mapas|
|pug_maxrounds|30|2|~|Maximo de rondas para culminar la partida|
|pug_overtime|0|0|1|Activa las rondas extras (para desempate)
|pug_overtime_rounds|6|1|~|Maximo de rondas para desempate|
|pug_intermission_countdown|15|0|~|Tiempo que dura el descanso de media partida (cambio de equipos)|
|pug_overtime_intermission_cd|10|0|~|Tiempo que dura el descanso en las Rondas Extra|
|pug_overtime_money|10000|800|16000|Dinero inicial al iniciar las rondas extra|
|pug_minplayers|3|0|(pug_players / 2)|Define el minimo de jugadores por equipo para mantener la partida activa|
|pug_force_end_time|3|0|~|Tiempo que tarda en chequear el numero de jugadores antes de Forzar el final|
|pug_bombfrags|1|0|1|Agrega los clasicos 3 puntos a los jugadores que desactiven o explote la C4|

## Comandos (Say):
- .ready: Cambias de estado a "listo"
- .unready: Cambias de estado a "nolisto"
- .dmg: Muestra el daño recibido
- ~~.hp: Muestra el Health Point de los jugadores contrarios~~
- ~~.score: Muestra la puntuacion actual (Esto es innecesario ya que la puntuacion esta en el scoreboard)~~
- .start: Forzar el inicio del pug con los jugadores actuales"
- .cancel: Cancelar el pug
- .forceready: Forzar a todos los jugadores al estado "listo"
## Requisitos:
- AmxModx 1.8.3+
- ReGameDLL_CS [![Download](http://rehlds.org/version/regamedll.svg)](http://teamcity.rehlds.org/guestAuth/downloadArtifacts.html?buildTypeId=ReGameDLL_Publish&buildId=lastSuccessful)
- Reapi [![Download](https://camo.githubusercontent.com/a3ac64aab91dcea4e0f3dfd611808ad61cc05798/687474703a2f2f7265686c64732e6f72672f76657273696f6e2f72656170692e737667)](http://teamcity.rehlds.org/guestAuth/downloadArtifacts.html?buildTypeId=Reapi_Publish&buildId=lastSuccessful)
