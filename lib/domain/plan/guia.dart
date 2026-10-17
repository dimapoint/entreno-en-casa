import 'plan_casa.dart';

String _conEtiqueta(String? etiqueta, String texto) =>
    etiqueta == null ? texto : '$etiqueta $texto';

/// Un trozo de contenido de una sección de la guía.
sealed class BloqueGuia {
  const BloqueGuia();

  /// Texto sin formato, para que el buscador lo recorra.
  String get textoPlano;
}

class SubtituloGuia extends BloqueGuia {
  const SubtituloGuia(this.texto);

  final String texto;

  @override
  String get textoPlano => texto;
}

class ParrafoGuia extends BloqueGuia {
  const ParrafoGuia(this.texto, {this.etiqueta});

  final String texto;

  /// Encabezado en negrita antes del texto, sin los dos puntos.
  final String? etiqueta;

  @override
  String get textoPlano => _conEtiqueta(etiqueta, texto);
}

/// Aviso que se muestra con el color de énfasis del tema.
class NotaGuia extends BloqueGuia {
  const NotaGuia(this.texto, {this.etiqueta});

  final String texto;
  final String? etiqueta;

  @override
  String get textoPlano => _conEtiqueta(etiqueta, texto);
}

class ItemGuia {
  const ItemGuia(this.texto, {this.etiqueta, this.subitems = const []});

  final String texto;
  final String? etiqueta;
  final List<String> subitems;

  String get textoPlano =>
      [_conEtiqueta(etiqueta, texto), ...subitems].join(' ');
}

class ListaGuia extends BloqueGuia {
  const ListaGuia(this.items, {this.numerada = false});

  final List<ItemGuia> items;
  final bool numerada;

  @override
  String get textoPlano => items.map((item) => item.textoPlano).join(' ');
}

class TablaGuia extends BloqueGuia {
  const TablaGuia({
    required this.encabezados,
    required this.filas,
    this.filasPorSemana = false,
  });

  /// La primera celda de cada fila es su título; los encabezados de las demás
  /// columnas rotulan el resto de la fila.
  final List<String> encabezados;
  final List<List<String>> filas;

  /// Hay una fila por semana del plan, en orden, para poder resaltar la actual.
  final bool filasPorSemana;

  @override
  String get textoPlano =>
      [...encabezados, for (final fila in filas) ...fila].join(' ');
}

class SeccionGuia {
  const SeccionGuia({
    required this.titulo,
    required this.icono,
    required this.bloques,
  });

  final String titulo;

  /// Clave del ícono; la vista la traduce a un IconData.
  final String icono;
  final List<BloqueGuia> bloques;

  String get textoPlano =>
      [titulo, for (final bloque in bloques) bloque.textoPlano].join(' ');
}

/// Contenido de la pantalla Guía, tomado del PDF "Plan de entrenamiento en casa".
/// Las fichas técnicas de cada ejercicio no están acá: viven en la pantalla de fuerza.
class Guia {
  const Guia._();

  static final secciones = <SeccionGuia>[
    _objetivo,
    _semanaTipo,
    _calentamiento,
    _progresion,
    _cardio,
    _semanas,
    _alimentacion,
    _medicion,
    _alertas,
  ];

  static const _objetivo = SeccionGuia(
    titulo: 'Objetivo y antes de arrancar',
    icono: 'objetivo',
    bloques: [
      ParrafoGuia(
        'En 13 semanas buscás recomposición: bajar grasa, ganar músculo y aguantar más, '
        'entrenando en casa 5 días por semana. Arrancás sedentario, con 1,80 m y unos 75 kg, '
        'así que las primeras 4 semanas son suaves a propósito.',
      ),
      ParrafoGuia(
        'El cardio y la alimentación del plan también apuntan a mejorar el colesterol y el '
        'hepatograma del análisis de octubre.',
      ),
      SubtituloGuia('Antes del primer entrenamiento'),
      ListaGuia([
        ItemGuia(
          'Apto físico con un clínico: llevá el análisis de octubre y preguntá si hay alguna '
          'restricción para intervalos intensos.',
        ),
        ItemGuia(
          'Hacé las mediciones del día 0 (sección "Cómo medir el progreso").',
        ),
        ItemGuia(
          'Prepará el espacio: unos 2 × 2 m libres, con piso liso para el curl femoral con toalla.',
        ),
        ItemGuia(
          'Probá que la mesa del remo invertido aguante tu peso (detalle en Fuerza B).',
        ),
      ]),
      SubtituloGuia('Material'),
      TablaGuia(
        encabezados: ['Qué', 'Para qué', '¿Lo tenés?'],
        filas: [
          [
            '2 mancuernas de 5 kg',
            'Búlgara, zancadas, remo, press militar',
            'Sí',
          ],
          ['Silla firme, sin ruedas', 'Búlgara, remo, fondos', ''],
          ['Mesa maciza y pesada', 'Remo invertido', ''],
          ['Sillón o cama firme', 'Puente de glúteo', ''],
          ['Toalla', 'Curl femoral', ''],
          ['Colchoneta o alfombra', 'Planchas y zona media', ''],
          ['Soga de saltar', 'Cardio adentro (opcional, barata)', ''],
          ['Mochila resistente', 'Sumar peso más adelante', ''],
          ['Celular con cronómetro', 'Descansos e intervalos', ''],
        ],
      ),
    ],
  );

  static const _semanaTipo = SeccionGuia(
    titulo: 'Semana tipo',
    icono: 'semana',
    bloques: [
      ParrafoGuia(
        'Entrenás fuerza 3 días y cardio 2, con al menos 48 h entre sesiones de fuerza. '
        'Los días son orientativos: movelos según la facu, respetando esa regla.',
      ),
      TablaGuia(
        encabezados: ['Día', 'Sesión', 'Duración'],
        filas: [
          ['Lunes', 'Fuerza (A o B)', '45–55 min'],
          ['Martes', 'Cardio suave', '25–45 min'],
          ['Miércoles', 'Fuerza (A o B)', '45–55 min'],
          [
            'Jueves',
            'Descanso activo: caminata de 30 min + 10 min de movilidad',
            '40 min',
          ],
          ['Viernes', 'Fuerza (A o B)', '45–55 min'],
          [
            'Sábado',
            'Cardio: suave en semanas 1–4, intervalos desde la 5',
            '20–45 min',
          ],
          ['Domingo', 'Descanso total', '—'],
        ],
      ),
      ParrafoGuia(
        'las semanas impares hacés A–B–A y las pares B–A–B. Así cada rutina se repite 3 veces '
        'cada 2 semanas.',
        etiqueta: 'Alternancia de fuerza',
      ),
      ParrafoGuia(
        'las 3 sesiones de fuerza, cada una con 15 min de cardio suave al final, más caminatas '
        'los otros días.',
        etiqueta: 'Semana cargada (3 días)',
      ),
      ParrafoGuia(
        '2 sesiones de fuerza de 30 min, con 2 series por ejercicio, y caminar todo lo que '
        'puedas. Sostener el hábito pesa más que hacer la sesión perfecta.',
        etiqueta: 'Semana de parciales (mínimo)',
      ),
    ],
  );

  static final _calentamiento = SeccionGuia(
    titulo: 'Calentamiento y vuelta a la calma',
    icono: 'calentamiento',
    bloques: [
      const ParrafoGuia(
        'Cada sesión arranca con 8–10 min de calentamiento y termina con 5 min de vuelta a la '
        'calma. Los jueves, la movilidad de 10 min es la parte de movilidad de esta lista '
        '(círculos de brazos, rotaciones de cadera, balanceos y gato-camello) hecha dos veces.',
      ),
      const SubtituloGuia('Calentamiento (8–10 min)'),
      ListaGuia([
        for (final paso in PlanCasa.calentamiento) ItemGuia(paso),
      ], numerada: true),
      const SubtituloGuia('Vuelta a la calma (5 min)'),
      const ParrafoGuia(PlanCasa.notaVueltaALaCalma),
      ListaGuia([
        for (final estiramiento in PlanCasa.vueltaALaCalma)
          ItemGuia(estiramiento),
      ]),
    ],
  );

  static final _progresion = SeccionGuia(
    titulo: 'Cómo progresar sin más peso',
    icono: 'progresion',
    bloques: [
      const ParrafoGuia(
        'Cuando completás el tope de repeticiones en todas las series con buena técnica, '
        'subís un escalón. Con 5 kg, la progresión sale de repeticiones, velocidad y variantes '
        'más difíciles.',
      ),
      const ParrafoGuia(
        'terminá cada serie sintiendo que te quedaban 2 repeticiones más. En las semanas 11–12 '
        'podés llegar a dejar solo 1.',
        etiqueta: 'Cuánto esfuerzo por serie',
      ),
      const SubtituloGuia('La escalera, en orden'),
      const ListaGuia([
        ItemGuia(
          'sumás 1–2 por sesión hasta llegar al tope del rango.',
          etiqueta: 'Repeticiones',
        ),
        ItemGuia(
          'bajada en 3–4 s y pausa de 1–2 s en la posición más difícil. Al cambiar, volvés al '
          'piso del rango de repeticiones.',
          etiqueta: 'Velocidad',
        ),
        ItemGuia(
          'pasás al nivel siguiente de la tabla y volvés al piso del rango.',
          etiqueta: 'Variante más difícil',
        ),
        ItemGuia(
          'mochila cargada o mancuernas más pesadas (ver la última sección).',
          etiqueta: 'Peso extra',
        ),
      ], numerada: true),
      const SubtituloGuia('Niveles por ejercicio'),
      TablaGuia(
        encabezados: const ['Ejercicio', 'Nivel 1', 'Nivel 2', 'Nivel 3'],
        filas: [
          for (final ejercicio in [
            ...PlanCasa.ejerciciosA,
            ...PlanCasa.ejerciciosB,
          ])
            [ejercicio.nombre, ...ejercicio.niveles],
        ],
      ),
      const NotaGuia(
        'emparejá un ejercicio de piernas con uno de torso. Hacés una serie de cada uno con '
        '60 s entre medio. En A: búlgara con flexiones y remo con curl femoral. En B: zancadas '
        'con press militar y remo invertido con puente. Te ahorra unos 10 min.',
        etiqueta: 'Para ahorrar tiempo',
      ),
      const NotaGuia(
        'si llegás muerto, hacé 2 series en vez de 3 y no intentes subir repeticiones ese día.',
        etiqueta: 'Día flojo',
      ),
    ],
  );

  static final _cardio = SeccionGuia(
    titulo: 'Cardio',
    icono: 'cardio',
    bloques: [
      const ParrafoGuia(
        'Dos sesiones por semana: el martes siempre suave, y el sábado suave hasta la semana 4 '
        'y con intervalos desde la 5. El suave construye la base; los intervalos suben el techo.',
      ),
      const SubtituloGuia('Cómo medir la intensidad'),
      const TablaGuia(
        encabezados: [
          'Intensidad',
          'Esfuerzo (1 a 10)',
          'Prueba de la charla',
          'Pulso aproximado',
        ],
        filas: [
          ['Suave', '4–5', 'Hablás en frases de 5–8 palabras', '115–135 lpm'],
          [
            'Fuerte (intervalos)',
            '8',
            'Solo palabras sueltas',
            '160 lpm o más',
          ],
        ],
      ),
      const NotaGuia(
        'El pulso es una estimación para tu edad; si no tenés reloj, guiate por la charla.',
      ),
      const SubtituloGuia('Opciones para el cardio suave'),
      const ListaGuia([
        ItemGuia(
          'la más fácil de sostener y la que más rinde por minuto.',
          etiqueta: 'Caminata rápida o trote por el barrio',
        ),
        ItemGuia(
          'bloques de 2–3 min con 1 min de pausa caminando. Saltá bajito, sobre la punta de '
          'los pies.',
          etiqueta: 'Soga',
        ),
        ItemGuia(
          'subir y bajar a ritmo constante, cambiando la pierna que sube primero cada minuto.',
          etiqueta: 'Escalera o escalón',
        ),
        ItemGuia(
          'Podés mezclar: por ejemplo, 10 min de soga en bloques + 20 min de caminata.',
        ),
      ]),
      const SubtituloGuia('Si arrancás a trotar desde cero'),
      ListaGuia([
        ItemGuia('Semanas 1–2: ${PlanCasa.troteDesdeCero(1).texto}.'),
        ItemGuia('Semanas 3–4: ${PlanCasa.troteDesdeCero(3).texto}.'),
        ItemGuia('Semanas 5–6: ${PlanCasa.troteDesdeCero(5).texto}.'),
        ItemGuia(
          'Semanas 7–8: ${PlanCasa.troteDesdeCero(7).texto}. '
          'Desde ahí sumás 5 min cada 2 semanas.',
        ),
      ], numerada: true),
      const SubtituloGuia('Sesión de intervalos (desde la semana 5)'),
      const ListaGuia([
        ItemGuia('5 min suaves: caminata o trote en el lugar.'),
        ItemGuia(
          'Vuelta de 4 ejercicios, 40 s fuerte y 20 s de pausa cada uno:',
          subitems: [
            'Soga rápida (o trote rápido en el lugar)',
            'Escaladores: en posición de flexión, llevás las rodillas al pecho alternando, '
                'rápido',
            'Sentadillas rápidas sin peso',
            'Rodillas arriba trotando en el lugar',
          ],
        ),
        ItemGuia(
          '1 min de pausa caminando entre vueltas. La cantidad de vueltas depende de la '
          'semana (ver "Las 13 semanas").',
        ),
        ItemGuia('5 min caminando para bajar.'),
      ], numerada: true),
    ],
  );

  static final _semanas = SeccionGuia(
    titulo: 'Las 13 semanas',
    icono: 'semanas',
    bloques: [
      const ParrafoGuia(
        'Cuatro fases: base (1–4), construcción (5–8), intensificación (9–12) y descarga (13). '
        'Después de la 13 repetís el ciclo desde la semana 5, arrancando con los niveles que '
        'alcanzaste.',
      ),
      TablaGuia(
        encabezados: const [
          'Semana',
          'Fase',
          'Fuerza',
          'Martes (suave)',
          'Sábado',
          'Hito',
        ],
        filasPorSemana: true,
        filas: [
          for (final semana in PlanCasa.semanas)
            [
              'Semana ${semana.numero}',
              semana.fase.etiqueta,
              semana.fuerzaTexto,
              '${semana.martesMinutos} min',
              semana.sabadoTexto,
              semana.hito ?? '',
            ],
        ],
      ),
      const NotaGuia(
        'La descarga se siente fácil a propósito: es la semana en que el cuerpo consolida lo '
        'que construiste.',
      ),
    ],
  );

  static const _alimentacion = SeccionGuia(
    titulo: 'Alimentación, sueño y recuperación',
    icono: 'alimentacion',
    bloques: [
      ParrafoGuia(
        'Apuntá a 120–150 g de proteína por día, repartidos en 4 comidas, y bajá las grasas '
        'saturadas: eso sostiene el músculo y ayuda con el colesterol. No hace falta contar '
        'calorías; con la proteína alta y menos comida chatarra, la recomposición se da sola.',
      ),
      SubtituloGuia('Fuentes de proteína (valores aproximados)'),
      TablaGuia(
        encabezados: ['Alimento', 'Porción', 'Proteína aprox.'],
        filas: [
          ['Pechuga de pollo cocida', '100 g', '30 g'],
          ['Carne magra cocida (nalga, peceto, lomo)', '100 g', '30 g'],
          ['Atún al natural', '1 lata escurrida', '25 g'],
          ['Merluza cocida', '100 g', '20 g'],
          ['Lentejas o garbanzos cocidos', '1 taza', '15 g'],
          ['Yogur tipo griego descremado', '1 pote', '10–15 g'],
          ['Huevos', '2 unidades', '12 g'],
          ['Ricota descremada', '100 g', '10 g'],
        ],
      ),
      ParrafoGuia(
        'Priorizá pollo, pescado, legumbres y lácteos descremados; la carne magra, 1–2 veces '
        'por semana.',
      ),
      SubtituloGuia('Ejemplo de día (unos 120–130 g de proteína)'),
      ListaGuia([
        ItemGuia(
          'avena con yogur griego y fruta + 2 huevos revueltos.',
          etiqueta: 'Desayuno',
        ),
        ItemGuia(
          '150 g de pollo + arroz o papa + ensalada con aceite de oliva.',
          etiqueta: 'Almuerzo',
        ),
        ItemGuia(
          'tostadas integrales con ricota + una fruta, o una lata de atún.',
          etiqueta: 'Merienda',
        ),
        ItemGuia(
          '150 g de merluza o un plato de lentejas + verduras.',
          etiqueta: 'Cena',
        ),
      ]),
      SubtituloGuia('Para el colesterol'),
      ListaGuia([
        ItemGuia(
          'avena, legumbres, frutas, verduras, aceite de oliva, palta, nueces.',
          etiqueta: 'Más',
        ),
        ItemGuia(
          'medialunas y facturas, manteca, fiambres y embutidos, quesos duros, carnes grasas, '
          'frituras.',
          etiqueta: 'Menos',
        ),
      ]),
      ParrafoGuia(
        '2–3 L por día, un poco más los días de cardio.',
        etiqueta: 'Agua',
      ),
      ParrafoGuia(
        'que alguna comida dentro de las 2 h siguientes tenga 30–40 g de proteína.',
        etiqueta: 'Después de entrenar',
      ),
      ParrafoGuia(
        '7–9 h, con horarios parecidos todos los días; ahí se repara el músculo. Evitá los '
        'intervalos muy tarde a la noche porque cuesta dormirse después.',
        etiqueta: 'Sueño',
      ),
      ParrafoGuia(
        'en las primeras 2 semanas es normal sentir los músculos doloridos 1–3 días. Caminar y '
        'moverte suave lo alivia; entrenar con ese dolor difuso no hace daño.',
        etiqueta: 'Dolor muscular',
      ),
    ],
  );

  static const _medicion = SeccionGuia(
    titulo: 'Cómo medir el progreso',
    icono: 'medicion',
    bloques: [
      ParrafoGuia(
        'Medís el día 0 y en las semanas 4, 8 y 13, siempre en las mismas condiciones: a la '
        'mañana, en ayunas, después de ir al baño. En recomposición la balanza sola engaña, por '
        'eso la cintura y las pruebas pesan más.',
      ),
      TablaGuia(
        encabezados: ['Medida', 'Cómo'],
        filas: [
          ['Peso (kg)', 'Pesate 3 veces esa semana y anotá el promedio'],
          [
            'Cintura (cm)',
            'Cinta métrica a la altura del ombligo, sin apretar, al final de exhalar',
          ],
          [
            'Fotos',
            'Frente, perfil y espalda; misma luz, misma ropa, misma distancia',
          ],
          ['Flexiones', 'Máximo seguido con buena técnica, anotando el nivel'],
          ['Plancha frontal (s)', 'Máximo con buena postura'],
          [
            'Prueba de 12 min',
            'Distancia caminando y trotando 12 min (con una app de mapas)',
          ],
        ],
      ),
      ParrafoGuia(
        'la cintura baja o se mantiene con el mismo peso, hacés más repeticiones o pasás de '
        'nivel, y el cardio suave se siente más fácil al mismo ritmo.',
        etiqueta: 'Señales de que va bien',
      ),
      SubtituloGuia('Registro de cada sesión'),
      ParrafoGuia(
        'Anotá cada ejercicio en el celular o en un cuaderno; sin registro no sabés cuándo '
        'subir. Ejemplo:',
      ),
      TablaGuia(
        encabezados: [
          'Fecha',
          'Rutina',
          'Ejercicio',
          'Nivel',
          'Series × repeticiones',
          'Cómo te sentiste (1–10)',
        ],
        filas: [
          ['20/10', 'A', 'Sentadilla búlgara', '2', '2 × 9, 8', '6'],
          ['20/10', 'A', 'Flexiones', '1', '2 × 12, 11', '7'],
        ],
      ),
    ],
  );

  static const _alertas = SeccionGuia(
    titulo: 'Señales de alerta y cuándo sumar peso',
    icono: 'alertas',
    bloques: [
      ParrafoGuia(
        'Cortá el entrenamiento y consultá si aparece algo de la primera lista. Para piernas, '
        'lo más probable es que necesites más peso entre las semanas 7 y 10.',
      ),
      SubtituloGuia('Pará y consultá a un médico si sentís:'),
      ListaGuia([
        ItemGuia('Dolor o presión en el pecho, mareo o palpitaciones raras.'),
        ItemGuia(
          'Falta de aire que no corresponde al esfuerzo o que no se va al frenar.',
        ),
        ItemGuia(
          'Dolor punzante en una articulación, o que dura más de 3 días.',
        ),
        ItemGuia('Dolor de espalda que baja por la pierna, u hormigueo.'),
      ]),
      ParrafoGuia(
        'ardor en el músculo durante la serie, dolor muscular difuso 1–3 días después y '
        'cansancio general las primeras 2 semanas.',
        etiqueta: 'Es normal',
      ),
      ParrafoGuia(
        'cuando estás en el nivel 3 de búlgara o zancadas y igual hacés más de 15 repeticiones '
        'limpias por pierna.',
        etiqueta: 'Cuándo sumar peso',
      ),
      SubtituloGuia('Opciones, de la más barata a la más completa'),
      ListaGuia([
        ItemGuia(
          'con botellas de agua o libros. Cada botella de 1 L pesa 1 kg, así que 10 botellas '
          'son 10 kg. Sirve para búlgara, zancadas, puente y remo.',
          etiqueta: 'Mochila cargada',
        ),
        ItemGuia(
          'cubren todos los ejercicios por años.',
          etiqueta: 'Mancuernas ajustables hasta 20 kg cada una',
        ),
        ItemGuia(
          'suma dominadas, el mejor ejercicio para la espalda, y puede reemplazar al remo '
          'invertido.',
          etiqueta: 'Barra de dominadas para el marco de la puerta',
        ),
      ], numerada: true),
    ],
  );
}
