# Zoodoku

Juego diario de animales al estilo Pokedoku. Un tablero de 3x3: cada fila y cada columna tiene una condición (por ejemplo "Mamífero" o "Vive en Asia") y en cada casilla hay que poner un animal que cumpla las dos. Hay 9 intentos y un tablero nuevo cada día.

## Estructura

```
zoodoku/
├── zoodoku.sql          Base de datos (tablas, datos y vistas)
├── index.html           Página del juego
├── css/estilos.css      Estilos
├── js/zoodoku.js        Lógica del navegador
└── api/
    ├── conexion.php     Conexión a MySQL y funciones comunes
    ├── tablero.php      Devuelve (o crea) el tablero de hoy
    ├── buscar.php       Busca animales por nombre
    └── comprobar.php    Comprueba si un animal vale para una casilla
```

## Ponerlo en marcha (XAMPP)

1. Arranca Apache y MySQL en XAMPP.
2. En phpMyAdmin, pestaña **Importar**, elige `zoodoku.sql`.
3. Copia la carpeta `zoodoku` dentro de `htdocs`.
4. Abre `http://localhost/zoodoku/`.

Si tu MySQL tiene contraseña o otro usuario, cámbialo al principio de `api/conexion.php`.

## Cómo funciona

- Cada animal tiene clase, dieta y tamaño, y además etiquetas (hábitat, continentes y rasgos).
- La tabla `criterios` son las condiciones que pueden salir en las cabeceras.
- La vista `v_animal_criterio` dice qué animal cumple qué condición. Un animal vale para una casilla si aparece con los dos criterios (el de su fila y el de su columna).
- La vista `v_parejas` cuenta cuántos animales cumplen cada pareja de condiciones, y `tablero.php` la usa para no crear casillas imposibles (mínimo 3 animales por casilla, se cambia en `MINIMO_RESPUESTAS`).
- El tablero de cada día se guarda en `tableros`. Cada acierto se guarda en `respuestas` con un identificador anónimo del jugador, y la vista `v_rareza` saca el porcentaje de jugadores que eligió cada animal.
- El navegador guarda en `localStorage` los intentos y los aciertos del día para que no se pierdan al recargar.

## Añadir animales

En `zoodoku.sql`, añade una fila en `animales` y sus etiquetas en `animal_etiqueta` (los ids de las etiquetas están en la tabla `etiquetas`). El tamaño es orientativo según el peso de un adulto: pequeño menos de 5 kg, mediano de 5 a 100 kg, grande más de 100 kg. Después vuelve a ejecutar el `UPDATE` del final del archivo para activar las condiciones que ya tengan suficientes animales.

Algunos datos son aproximados (tamaños, continentes, rasgos) y se pueden discutir. Corrígelos en la base de datos.

## Límites a tener en cuenta

- **GitHub Pages no ejecuta PHP.** Para jugar online necesitas un hosting con PHP y MySQL (por ejemplo InfinityFree). En el portfolio puedes enlazar el código de GitHub y la demo en ese hosting.
- Los intentos se controlan en el navegador, así que alguien con conocimientos podría saltárselos. Es normal en un juego así sin cuentas de usuario.
- La búsqueda por nombre ignora mayúsculas y tildes gracias a la colación `utf8mb4_unicode_ci` de MySQL.
