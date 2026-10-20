// zoodoku.js
// Lógica del juego en el navegador. Pide los datos a la API en PHP (carpeta api/)
// y se encarga de pintar el tablero, controlar los intentos y guardar el progreso.

// ---------- Constantes ----------
const URL_API = 'api/';
const INTENTOS_MAXIMOS = 9;
const TOTAL_CASILLAS = 9;
const ESPERA_BUSQUEDA = 250; // milisegundos desde la última tecla

// ---------- Estado del juego ----------
let tablero = null;               // datos del tablero de hoy (los manda tablero.php)
let casillaActiva = null;         // número de la casilla que se está rellenando
let intentosRestantes = INTENTOS_MAXIMOS;
let aciertos = {};                // casilla -> { animal_id, nombre, rareza }
let juegoTerminado = false;
let temporizadorBusqueda = null;
const jugadorId = obtenerJugadorId();

// ---------- Elementos de la página ----------
const elementoIntentos = document.getElementById('intentos');
const elementoAciertos = document.getElementById('aciertos');
const elementoMensaje = document.getElementById('mensaje');
const casillas = document.querySelectorAll('.casilla');

const ventanaBuscador = document.getElementById('buscador');
const elementoCondicion = document.getElementById('condicion');
const campoBusqueda = document.getElementById('campo-busqueda');
const listaResultados = document.getElementById('resultados');

const ventanaFin = document.getElementById('fin');
const tituloFin = document.getElementById('fin-titulo');
const textoFin = document.getElementById('fin-texto');


// ============================================================
//  Inicio
// ============================================================

iniciarJuego();

async function iniciarJuego() {
    try {
        tablero = await pedirJson(URL_API + 'tablero.php');
    } catch (error) {
        mostrarMensaje('No se ha podido cargar el tablero. ¿Está arrancado el servidor?', 'fallo');
        return;
    }

    pintarCabeceras();
    restaurarProgreso();
    actualizarMarcador();
    activarEventos();

    if (juegoTerminado) {
        mostrarMensaje('Ya has terminado el tablero de hoy. ¡Vuelve mañana!', '');
        bloquearCasillas();
    }
}

// Escribe las 6 condiciones en las cabeceras
function pintarCabeceras() {
    for (let i = 0; i < 3; i++) {
        escribirCabecera('fila-' + i, tablero.filas[i]);
        escribirCabecera('columna-' + i, tablero.columnas[i]);
    }
}

function escribirCabecera(idElemento, criterio) {
    const cabecera = document.getElementById(idElemento);
    cabecera.innerHTML = '';

    const icono = document.createElement('span');
    icono.className = 'icono';
    icono.textContent = criterio.icono;

    const texto = document.createElement('span');
    texto.textContent = criterio.texto;

    cabecera.append(icono, texto);
}

function activarEventos() {
    casillas.forEach(function (casilla) {
        casilla.addEventListener('click', function () {
            abrirBuscador(Number(casilla.dataset.celda));
        });
    });

    campoBusqueda.addEventListener('input', alEscribirBusqueda);
    document.getElementById('cerrar-buscador').addEventListener('click', function () {
        ventanaBuscador.close();
    });

    document.getElementById('boton-compartir').addEventListener('click', compartirResultado);
    document.getElementById('cerrar-fin').addEventListener('click', function () {
        ventanaFin.close();
    });
}


// ============================================================
//  Buscador de animales
// ============================================================

function abrirBuscador(numeroCasilla) {
    if (juegoTerminado) return;

    const casilla = casillas[numeroCasilla];
    if (casilla.dataset.estado === 'ok') return; // ya está acertada

    casillaActiva = numeroCasilla;

    // La condición de la casilla es la de su fila y la de su columna
    const fila = tablero.filas[Math.floor(numeroCasilla / 3)];
    const columna = tablero.columnas[numeroCasilla % 3];
    elementoCondicion.textContent = fila.texto + ' + ' + columna.texto;

    campoBusqueda.value = '';
    listaResultados.innerHTML = '';
    ventanaBuscador.showModal();
    campoBusqueda.focus();
}

// Espera un poco desde la última tecla para no preguntar al servidor
// por cada letra
function alEscribirBusqueda() {
    clearTimeout(temporizadorBusqueda);
    temporizadorBusqueda = setTimeout(buscarAnimales, ESPERA_BUSQUEDA);
}

async function buscarAnimales() {
    const texto = campoBusqueda.value.trim();

    if (texto.length < 2) {
        listaResultados.innerHTML = '';
        return;
    }

    try {
        const animales = await pedirJson(URL_API + 'buscar.php?q=' + encodeURIComponent(texto));
        pintarResultados(animales);
    } catch (error) {
        listaResultados.innerHTML = '<li class="sin-resultados">Error al buscar.</li>';
    }
}

function pintarResultados(animales) {
    listaResultados.innerHTML = '';

    if (animales.length === 0) {
        listaResultados.innerHTML = '<li class="sin-resultados">No hay ningún animal con ese nombre.</li>';
        return;
    }

    animales.forEach(function (animal) {
        const elemento = document.createElement('li');
        const boton = document.createElement('button');
        boton.type = 'button';
        boton.textContent = animal.nombre;

        const clase = document.createElement('small');
        clase.textContent = nombreDeClase(animal.clase);
        boton.append(clase);

        boton.addEventListener('click', function () {
            elegirAnimal(animal);
        });

        elemento.append(boton);
        listaResultados.append(elemento);
    });
}


// ============================================================
//  Jugada
// ============================================================

// El jugador ha elegido un animal para la casilla activa
async function elegirAnimal(animal) {
    const numeroCasilla = casillaActiva;
    ventanaBuscador.close();

    let resultado;
    try {
        resultado = await pedirJson(URL_API + 'comprobar.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                tablero_id: tablero.tablero_id,
                celda: numeroCasilla,
                animal_id: animal.id,
                jugador: jugadorId
            })
        });
    } catch (error) {
        mostrarMensaje('No se ha podido comprobar la respuesta. Inténtalo otra vez.', 'fallo');
        return;
    }

    if (resultado.valido) {
        registrarAcierto(numeroCasilla, animal.id, resultado);
    } else {
        registrarFallo(numeroCasilla, animal, resultado.motivo);
    }

    actualizarMarcador();
    guardarProgreso();
    comprobarFinDelJuego();
}

function registrarAcierto(numeroCasilla, animalId, resultado) {
    aciertos[numeroCasilla] = {
        animal_id: animalId,
        nombre: resultado.nombre,
        rareza: resultado.rareza
    };
    pintarCasillaAcertada(numeroCasilla);
    mostrarMensaje('¡Correcto! ' + resultado.nombre + ' (' + resultado.rareza + ' % de los jugadores).', 'ok');
}

function registrarFallo(numeroCasilla, animal, motivo) {
    // Si el animal está repetido no se gasta intento, es un despiste
    if (motivo === 'repetido') {
        mostrarMensaje(animal.nombre + ' ya lo has usado en este tablero.', 'fallo');
        return;
    }
    if (motivo === 'ocupada') {
        mostrarMensaje('Esa casilla ya está resuelta.', 'fallo');
        return;
    }

    intentosRestantes--;
    mostrarMensaje(animal.nombre + ' no cumple las dos condiciones.', 'fallo');

    // Pequeña animación de sacudida en la casilla
    const casilla = casillas[numeroCasilla];
    casilla.classList.add('fallo');
    setTimeout(function () {
        casilla.classList.remove('fallo');
    }, 400);
}

function pintarCasillaAcertada(numeroCasilla) {
    const datos = aciertos[numeroCasilla];
    const casilla = casillas[numeroCasilla];

    casilla.dataset.estado = 'ok';
    casilla.innerHTML = '';

    const nombre = document.createElement('span');
    nombre.className = 'nombre';
    nombre.textContent = datos.nombre;

    const rareza = document.createElement('span');
    rareza.className = 'rareza';
    rareza.textContent = datos.rareza + ' %';

    casilla.append(nombre, rareza);
    casilla.setAttribute('aria-label', 'Casilla ' + (numeroCasilla + 1) + ': ' + datos.nombre);
}


// ============================================================
//  Marcador y final
// ============================================================

function actualizarMarcador() {
    elementoIntentos.textContent = intentosRestantes;
    elementoAciertos.textContent = Object.keys(aciertos).length;
}

function mostrarMensaje(texto, tipo) {
    elementoMensaje.textContent = texto;
    elementoMensaje.className = 'mensaje ' + tipo;
}

function comprobarFinDelJuego() {
    const totalAciertos = Object.keys(aciertos).length;

    if (totalAciertos === TOTAL_CASILLAS) {
        terminarJuego('¡Tablero completado!', 'Has acertado las 9 casillas con ' + intentosRestantes + ' intentos de sobra.');
    } else if (intentosRestantes === 0) {
        terminarJuego('Se acabaron los intentos', 'Has acertado ' + totalAciertos + ' de 9 casillas.');
    }
}

function terminarJuego(titulo, texto) {
    juegoTerminado = true;
    bloquearCasillas();
    guardarProgreso();

    tituloFin.textContent = titulo;
    textoFin.textContent = texto;
    ventanaFin.showModal();
}

function bloquearCasillas() {
    casillas.forEach(function (casilla) {
        casilla.disabled = true;
    });
}

// Copia al portapapeles un resumen en emojis para compartir
async function compartirResultado() {
    let cuadricula = '';
    for (let i = 0; i < TOTAL_CASILLAS; i++) {
        cuadricula += aciertos[i] ? '🟩' : '⬛';
        if (i % 3 === 2) cuadricula += '\n';
    }
    const texto = 'Zoodoku ' + tablero.fecha + '\n' + cuadricula;

    try {
        await navigator.clipboard.writeText(texto);
        document.getElementById('boton-compartir').textContent = '¡Copiado!';
    } catch (error) {
        // Si el navegador no deja copiar, lo mostramos para copiarlo a mano
        window.prompt('Copia tu resultado:', texto);
    }
}


// ============================================================
//  Progreso guardado en el navegador (para no perderlo al recargar)
// ============================================================

function claveProgreso() {
    return 'zoodoku_progreso_' + tablero.fecha;
}

function guardarProgreso() {
    const progreso = {
        tablero_id: tablero.tablero_id,
        intentosRestantes: intentosRestantes,
        aciertos: aciertos,
        juegoTerminado: juegoTerminado
    };
    try {
        localStorage.setItem(claveProgreso(), JSON.stringify(progreso));
    } catch (error) {
        // Si no se puede guardar (modo privado, etc.) el juego sigue funcionando
    }
}

function restaurarProgreso() {
    let progreso = null;
    try {
        progreso = JSON.parse(localStorage.getItem(claveProgreso()));
    } catch (error) {
        return;
    }

    // Solo sirve si es del mismo tablero (por si se ha reiniciado la base de datos)
    if (!progreso || progreso.tablero_id !== tablero.tablero_id) return;

    intentosRestantes = progreso.intentosRestantes;
    aciertos = progreso.aciertos;
    juegoTerminado = progreso.juegoTerminado;

    Object.keys(aciertos).forEach(function (numeroCasilla) {
        pintarCasillaAcertada(Number(numeroCasilla));
    });
}


// ============================================================
//  Utilidades
// ============================================================

// Hace una petición a la API y devuelve el JSON. Lanza error si algo falla.
async function pedirJson(url, opciones) {
    const respuesta = await fetch(url, opciones);
    if (!respuesta.ok) {
        throw new Error('Error ' + respuesta.status);
    }
    return respuesta.json();
}

// Identificador anónimo del jugador, para que el servidor sepa qué
// animales ha usado ya. Se crea la primera vez y se guarda.
function obtenerJugadorId() {
    try {
        let id = localStorage.getItem('zoodoku_jugador');
        if (!id) {
            id = crearIdentificador();
            localStorage.setItem('zoodoku_jugador', id);
        }
        return id;
    } catch (error) {
        return crearIdentificador();
    }
}

function crearIdentificador() {
    if (window.crypto && crypto.randomUUID) {
        return crypto.randomUUID();
    }
    return Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 12);
}

function nombreDeClase(clase) {
    const nombres = {
        mamifero: 'Mamífero',
        ave: 'Ave',
        reptil: 'Reptil',
        anfibio: 'Anfibio',
        pez: 'Pez',
        invertebrado: 'Invertebrado'
    };
    return nombres[clase] || clase;
}
