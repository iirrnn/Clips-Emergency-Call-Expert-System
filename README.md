# Clips - Emergency Call Expert System

Se trata de un ejemplo sencillo de sistema experto implementado en *CLIPS*. Simula el protocolo a seguir cuando el operador de emergencias recibe una llamada.

El programa comienza preguntando: ¿Cuál es su emergencia? pudiendo ser accidente de coche, fuego o una falsa alarma. 
Si se tratase de un accidente de coche, 
- Ubicación (Norte/Sur)
- ¿Hay heridos? S/N -> ¿Cuántos heridos?
- ¿Hay gente atrapada? S/N
- ¿Hay algún vehículo con mercancías peligrosas? S/N

Si se tratase de un incendio,
- Ubicación (Norte/Sur)
- ¿Qué se encuentra en llamas? Vivienda/Múltiples Edificios
- ¿Hay algún edificio con productos peligrosos? S/N

Una vez obtenida esta información, se procedería a notificar a los servicios correspondientes; y se realizaría un resumen de la emergencia producida con todos los datos recopilados además de indicar si ha sido resuelta o no.
