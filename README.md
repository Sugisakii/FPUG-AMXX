# FPUG-AMXX
### Descripccion:
El famoso Pick Up Game/Competitive, con algunas características distintas, fue tomado como base el competitivo de "Face It"

### Caracteristicas:
Al igual que el YAP, posee características muy similares o mas bien iguales, tiene los mismos comandos a diferencia de 1 o 2
- Modo practica/calentamiento con ronda infinita
- La puntuacion esta en el "ServerName y el GameName"
- La puntuacion de los jugadores no se reinicia al cambiar de equipos
- (Por cvar) La 1era Ronda es de cuchillo (determina que equipo va a TT)
- Opciones Para desarrolladores
- Opcion para privatizar el PUG y evitar el uso de password
- Al hacer el "intermission", al cambio de equipos se evita otra vez el .ready y no se reinicia las puntuaciones en el scoreboard
- Sonidos tomados del CS:GO
- Al igual que el CS:GO, tiene un breve intermission mas dimanico
- Se puede hacer votaciones personalizadas usando addons externos
### Comandos (Say):
- .ready: Cambias de estado a "listo"
- .unready: Cambias de estado a "nolisto"
- .dmg: Muestra el daño recibido
- .hp: Muestra el Health Point de los jugadores contrarios
- .score: Muestra la puntuacion actual (Esto es innecesario ya que la puntuacion esta en el scoreboard)
- .start: Forzar el inicio del pug con los jugadores actuales"
- .cancel: Cancelar el pug
- .forceready: Forzar a todos los jugadores al estado "listo"
### Requisitos:
- AmxModx 1.8.3
- ReGameDLL_CS [![Download](http://rehlds.org/version/regamedll.svg)](http://teamcity.rehlds.org/guestAuth/downloadArtifacts.html?buildTypeId=ReGameDLL_Publish&buildId=lastSuccessful)
- Reapi [![Download](https://camo.githubusercontent.com/a3ac64aab91dcea4e0f3dfd611808ad61cc05798/687474703a2f2f7265686c64732e6f72672f76657273696f6e2f72656170692e737667)](http://teamcity.rehlds.org/guestAuth/downloadArtifacts.html?buildTypeId=Reapi_Publish&buildId=lastSuccessful)
