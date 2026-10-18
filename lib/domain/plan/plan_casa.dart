import '../models/ejercicio.dart';
import '../models/semana_plan.dart';

/// Datos del "Plan de entrenamiento en casa" tal como figuran en el PDF.
class PlanCasa {
  const PlanCasa._();

  static const ejerciciosA = <Ejercicio>[
    Ejercicio(
      id: 'sentadilla_bulgara',
      nombre: 'Sentadilla búlgara con mancuernas',
      rutina: Rutina.a,
      orden: 1,
      repeticiones: '8–12 por pierna',
      repsMinimas: 8,
      repsMaximas: 12,
      descansoSegundos: 90,
      descansoTexto: '90 s',
      porLado: true,
      cuartaSerieSemanas11y12: true,
      niveles: [
        'Sin peso, mano en la pared',
        'Con las mancuernas de 5 kg',
        'Mancuernas + mochila, o "1 y ½": bajás, subís a mitad, bajás otra vez y subís',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'De espaldas a la silla, a un paso largo. Apoyás el empeine del pie de atrás en el asiento, una mancuerna en cada mano.',
        ),
        NotaTecnica(
          'Movimiento',
          'Bajás en vertical en 2–3 s hasta que la rodilla de atrás casi toque el piso, con el torso apenas inclinado. Subís empujando con todo el pie de adelante, sobre todo el talón.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Pie de adelante muy cerca de la silla, rodilla que se cae hacia adentro, rebotar abajo.',
        ),
        NotaTecnica(
          'Ojo',
          'Empezá siempre por la pierna más débil y hacé las mismas repeticiones con la otra.',
        ),
      ],
    ),
    Ejercicio(
      id: 'flexiones',
      nombre: 'Flexiones de brazos',
      rutina: Rutina.a,
      orden: 2,
      repeticiones: '8–15',
      repsMinimas: 8,
      repsMaximas: 15,
      descansoSegundos: 90,
      descansoTexto: '90 s',
      cuartaSerieSemanas11y12: true,
      niveles: ['Manos en la mesa', 'En el piso', 'Pies sobre la silla'],
      notas: [
        NotaTecnica(
          'Posición',
          'Manos un poco más abiertas que los hombros, cuerpo en línea recta de cabeza a talones, glúteos y abdomen apretados.',
        ),
        NotaTecnica(
          'Movimiento',
          'Bajás en 2 s con los codos a unos 45° del cuerpo hasta dejar el pecho a 2–3 cm del piso. Subís empujando el piso lejos.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Cadera caída o en punta, codos abiertos en cruz, bajar a medias.',
        ),
        NotaTecnica(
          'Ojo',
          'Si no llegás a 8 repeticiones limpias, usá la variante con manos en la mesa (ver "Cómo progresar").',
        ),
      ],
    ),
    Ejercicio(
      id: 'remo_mancuerna',
      nombre: 'Remo con mancuerna apoyado en silla',
      rutina: Rutina.a,
      orden: 3,
      repeticiones: '12–15 por brazo',
      repsMinimas: 12,
      repsMaximas: 15,
      descansoSegundos: 60,
      descansoTexto: '60 s',
      porLado: true,
      niveles: [
        'Ritmo normal',
        'Pausa 2 s arriba + bajada 4 s',
        'Remando con la mochila cargada',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'Mano y rodilla del mismo lado sobre la silla, espalda plana y paralela al piso. La otra mano sostiene la mancuerna colgando.',
        ),
        NotaTecnica(
          'Movimiento',
          'Llevás el codo hacia la cadera, como arrancando una motosierra. Pausa de 1–2 s arriba apretando el omóplato, y bajás en 3 s.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Girar el torso para subir, encoger el hombro hacia la oreja, tirar solo con el bíceps.',
        ),
        NotaTecnica(
          'Ojo',
          '5 kg acá es liviano, así que la pausa y la bajada lenta son las que hacen el trabajo.',
        ),
      ],
    ),
    Ejercicio(
      id: 'curl_femoral_toalla',
      nombre: 'Curl femoral con toalla',
      rutina: Rutina.a,
      orden: 4,
      repeticiones: '8–12',
      repsMinimas: 8,
      repsMaximas: 12,
      descansoSegundos: 90,
      descansoTexto: '90 s',
      niveles: [
        'Solo la parte de estirar: subís la cadera, estirás en 4 s, bajás',
        'Completo, dos piernas',
        'A una pierna',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'Boca arriba en piso liso (cerámica o madera), talones sobre una toalla doblada, brazos al costado.',
        ),
        NotaTecnica(
          'Movimiento',
          'Levantás la cadera como en un puente. Con la cadera arriba, arrastrás los talones hacia la cola y después estirás las piernas despacio, en 3 s.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Bajar la cadera al estirar, hacerlo sobre alfombra (no desliza).',
        ),
      ],
    ),
    Ejercicio(
      id: 'plancha_frontal',
      nombre: 'Plancha frontal',
      rutina: Rutina.a,
      orden: 5,
      repeticiones: '30–45 s',
      repsMinimas: 30,
      repsMaximas: 45,
      descansoSegundos: 45,
      descansoTexto: '45 s',
      esTiempo: true,
      niveles: [
        'Rodillas apoyadas',
        'Antebrazos y pies',
        'Pies sobre la silla',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'Antebrazos en el piso, codos debajo de los hombros, cuerpo recto.',
        ),
        NotaTecnica(
          'Cómo sostenerla',
          'Apretás glúteos, empujás el piso con los antebrazos y respirás normal.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Cadera caída, cola para arriba, aguantar la respiración.',
        ),
      ],
    ),
    Ejercicio(
      id: 'plancha_lateral',
      nombre: 'Plancha lateral',
      rutina: Rutina.a,
      orden: 6,
      repeticiones: '20–30 s por lado',
      repsMinimas: 20,
      repsMaximas: 30,
      descansoSegundos: 45,
      descansoTexto: '45 s',
      esTiempo: true,
      porLado: true,
      seriesTope: 2,
      niveles: [
        'Rodillas apoyadas',
        'Pies apilados',
        'Levantando la pierna de arriba',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'De costado, antebrazo debajo del hombro, pies uno sobre otro.',
        ),
        NotaTecnica(
          'Cómo sostenerla',
          'Cadera arriba, en línea con hombros y tobillos, mirando al frente.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Dejar caer la cadera, rotar el torso hacia el piso.',
        ),
      ],
    ),
  ];

  static const ejerciciosB = <Ejercicio>[
    Ejercicio(
      id: 'zancadas_atras',
      nombre: 'Zancadas hacia atrás con mancuernas',
      rutina: Rutina.b,
      orden: 1,
      repeticiones: '10–12 por pierna',
      repsMinimas: 10,
      repsMaximas: 12,
      descansoSegundos: 90,
      descansoTexto: '90 s',
      porLado: true,
      niveles: [
        'Sin peso, mano en la silla',
        'Con las mancuernas de 5 kg',
        'Pie de adelante sobre un libro grueso o escalón de 5–10 cm',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'Parado, pies al ancho de la cadera, una mancuerna en cada mano.',
        ),
        NotaTecnica(
          'Movimiento',
          'Das un paso largo hacia atrás y bajás hasta que la rodilla de atrás casi toque el piso, con ambas rodillas cerca de 90°. Volvés empujando con el talón de adelante.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Paso corto, torso que se va hacia adelante, rodilla de adelante que se cae hacia adentro.',
        ),
        NotaTecnica(
          'Ojo',
          'Hacer todas las repeticiones de una pierna y después la otra es más duro que alternar. Arrancá alternando.',
        ),
      ],
    ),
    Ejercicio(
      id: 'press_militar',
      nombre: 'Press militar con mancuernas, de pie',
      rutina: Rutina.b,
      orden: 2,
      repeticiones: '10–15',
      repsMinimas: 10,
      repsMaximas: 15,
      descansoSegundos: 90,
      descansoTexto: '60–90 s',
      niveles: [
        'Dos brazos a la vez',
        'Un brazo por vez',
        'Bajada en 4 s + pausa abajo',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'De pie, pies al ancho de la cadera, glúteos y abdomen apretados. Mancuernas a la altura de los hombros, palmas enfrentadas (es lo más cómodo para el hombro).',
        ),
        NotaTecnica(
          'Movimiento',
          'Empujás hacia arriba hasta estirar los brazos y bajás en 3 s.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Arquear la zona lumbar para empujar, bajar a medias, tirar la cabeza hacia adelante.',
        ),
      ],
    ),
    Ejercicio(
      id: 'remo_invertido',
      nombre: 'Remo invertido bajo la mesa',
      rutina: Rutina.b,
      orden: 3,
      repeticiones: '6–12',
      repsMinimas: 6,
      repsMaximas: 12,
      descansoSegundos: 90,
      descansoTexto: '90 s',
      niveles: [
        'Rodillas dobladas, pies cerca',
        'Piernas estiradas',
        'Pies sobre una silla',
      ],
      notas: [
        NotaTecnica(
          'Prueba de seguridad',
          'Solo con una mesa maciza y pesada. Nada de mesas plegables, con caballetes o de vidrio. Antes de la primera serie, colgate de a poco y fijate que no se levanten las patas del lado opuesto.',
        ),
        NotaTecnica(
          'Posición',
          'Boca arriba debajo de la mesa, manos en el borde al ancho de los hombros, cuerpo recto y talones en el piso.',
        ),
        NotaTecnica(
          'Movimiento',
          'Llevás el pecho hacia el borde juntando los omóplatos arriba, y bajás en 2–3 s.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Cadera que se cae, tirones con impulso, hombros encogidos.',
        ),
        NotaTecnica(
          'Sin mesa que aguante',
          'Repetí el remo con mancuerna de Fuerza A, con bajada de 4 s.',
        ),
      ],
    ),
    Ejercicio(
      id: 'puente_gluteo_sillon',
      nombre: 'Puente de glúteo a una pierna en el sillón',
      rutina: Rutina.b,
      orden: 4,
      repeticiones: '10–15 por lado',
      repsMinimas: 10,
      repsMaximas: 15,
      descansoSegundos: 60,
      descansoTexto: '60 s',
      porLado: true,
      niveles: [
        'Dos piernas, mancuerna sobre la cadera',
        'Una pierna',
        'Una pierna con mancuerna sobre la cadera',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'La parte alta de la espalda, justo debajo de los omóplatos, apoyada en el borde del sillón. Un pie en el piso, debajo de la rodilla, y la otra pierna doblada en el aire.',
        ),
        NotaTecnica(
          'Movimiento',
          'Subís la cadera hasta que el torso quede en línea con el muslo, apretás el glúteo 1–2 s arriba y bajás en 2 s.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Arquear la zona lumbar arriba, empujar con la punta del pie.',
        ),
        NotaTecnica(
          'Ojo',
          'Mantené el mentón levemente adentro y la mirada hacia adelante; eso evita arquear la espalda.',
        ),
      ],
    ),
    Ejercicio(
      id: 'fondos_silla',
      nombre: 'Fondos en silla',
      rutina: Rutina.b,
      orden: 5,
      repeticiones: '8–12',
      repsMinimas: 8,
      repsMaximas: 12,
      descansoSegundos: 90,
      descansoTexto: '90 s',
      niveles: [
        'Piernas dobladas',
        'Piernas estiradas',
        'Pies sobre otra silla',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'Silla firme contra la pared. Manos en el borde del asiento, dedos hacia adelante, piernas dobladas.',
        ),
        NotaTecnica(
          'Movimiento',
          'Bajás doblando los codos hasta unos 90°, con los codos apuntando hacia atrás, y subís empujando.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Bajar demasiado, codos abiertos hacia los costados, hombros subiendo a las orejas.',
        ),
      ],
    ),
    Ejercicio(
      id: 'bicho_muerto',
      nombre: 'Bicho muerto',
      rutina: Rutina.b,
      orden: 6,
      repeticiones: '8 por lado',
      repsMinimas: 8,
      repsMaximas: 8,
      descansoSegundos: 45,
      descansoTexto: '45 s',
      porLado: true,
      niveles: [
        'Solo piernas',
        'Brazo y pierna opuestos',
        'Sosteniendo una mancuerna con los brazos',
      ],
      notas: [
        NotaTecnica(
          'Posición',
          'Boca arriba, brazos estirados hacia el techo, rodillas dobladas a 90° encima de la cadera. Zona lumbar pegada al piso.',
        ),
        NotaTecnica(
          'Movimiento',
          'Estirás a la vez el brazo derecho hacia atrás y la pierna izquierda hacia adelante, exhalando y sin despegar la lumbar. Volvés y cambiás de lado.',
        ),
        NotaTecnica(
          'Errores comunes',
          'Despegar la zona lumbar, hacerlo rápido.',
        ),
      ],
    ),
  ];

  static List<Ejercicio> ejerciciosDe(Rutina rutina) =>
      rutina == Rutina.a ? ejerciciosA : ejerciciosB;

  static Ejercicio? ejercicioPorId(String id) {
    for (final ejercicio in [...ejerciciosA, ...ejerciciosB]) {
      if (ejercicio.id == id) return ejercicio;
    }
    return null;
  }

  static const semanas = <SemanaPlan>[
    SemanaPlan(
      numero: 1,
      fase: FasePlan.base,
      fuerzaTexto: '2 series, piso del rango de repeticiones, foco en técnica',
      martesMinutos: 25,
      tipoSabado: TipoSabado.suave,
      sabadoMinutos: 20,
      hito: 'Mediciones del día 0 antes de arrancar',
    ),
    SemanaPlan(
      numero: 2,
      fase: FasePlan.base,
      fuerzaTexto: '2 series, sumás 1–2 repeticiones donde puedas',
      martesMinutos: 25,
      tipoSabado: TipoSabado.suave,
      sabadoMinutos: 20,
    ),
    SemanaPlan(
      numero: 3,
      fase: FasePlan.base,
      fuerzaTexto: '3 series en los primeros 3 ejercicios, 2 en el resto',
      martesMinutos: 30,
      tipoSabado: TipoSabado.suave,
      sabadoMinutos: 25,
    ),
    SemanaPlan(
      numero: 4,
      fase: FasePlan.base,
      fuerzaTexto: '3 series en todo',
      martesMinutos: 30,
      tipoSabado: TipoSabado.suave,
      sabadoMinutos: 30,
      hito: 'Primera medición',
    ),
    SemanaPlan(
      numero: 5,
      fase: FasePlan.construccion,
      fuerzaTexto: '3 series; donde llegaste al tope, pasás a bajada lenta',
      martesMinutos: 35,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 3,
    ),
    SemanaPlan(
      numero: 6,
      fase: FasePlan.construccion,
      fuerzaTexto: '3 series',
      martesMinutos: 35,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 3,
    ),
    SemanaPlan(
      numero: 7,
      fase: FasePlan.construccion,
      fuerzaTexto: '3 series; primeros cambios de nivel',
      martesMinutos: 40,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 4,
    ),
    SemanaPlan(
      numero: 8,
      fase: FasePlan.construccion,
      fuerzaTexto: '3 series',
      martesMinutos: 40,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 4,
      hito: 'Segunda medición',
    ),
    SemanaPlan(
      numero: 9,
      fase: FasePlan.intensificacion,
      fuerzaTexto: '3 series, nivel 3 donde puedas',
      martesMinutos: 40,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 4,
      hito: 'Evaluá si hace falta peso extra',
    ),
    SemanaPlan(
      numero: 10,
      fase: FasePlan.intensificacion,
      fuerzaTexto: '3 series',
      martesMinutos: 45,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 5,
    ),
    SemanaPlan(
      numero: 11,
      fase: FasePlan.intensificacion,
      fuerzaTexto: '4 series en búlgara y flexiones, 3 en el resto',
      martesMinutos: 45,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 5,
    ),
    SemanaPlan(
      numero: 12,
      fase: FasePlan.intensificacion,
      fuerzaTexto: 'Igual que la 11, dejando 1 repetición en reserva',
      martesMinutos: 45,
      tipoSabado: TipoSabado.intervalos,
      sabadoVueltas: 5,
      hito: 'Prueba: máximo de flexiones y de plancha',
    ),
    SemanaPlan(
      numero: 13,
      fase: FasePlan.descarga,
      fuerzaTexto: '2 series, 2 repeticiones menos que la semana 12',
      martesMinutos: 25,
      tipoSabado: TipoSabado.caminata,
      sabadoMinutos: 30,
      hito: 'Tercera medición',
    ),
  ];

  /// Semana del plan, de 1 a 13.
  static SemanaPlan semana(int numero) => semanas[numero - 1];

  /// Trote para quien arranca desde cero, según la semana efectiva del plan.
  static BloqueTrote troteDesdeCero(int semanaEfectiva) {
    if (semanaEfectiva <= 2) {
      return const BloqueTrote(vueltas: 6, trotarMin: 1, caminarMin: 2);
    }
    if (semanaEfectiva <= 4) {
      return const BloqueTrote(vueltas: 6, trotarMin: 2, caminarMin: 1);
    }
    if (semanaEfectiva <= 6) {
      return const BloqueTrote(vueltas: 3, trotarMin: 5, caminarMin: 1);
    }
    // Desde la semana 7: 20 min seguidos y 5 min más cada 2 semanas.
    return BloqueTrote(
      vueltas: 1,
      trotarMin: 20 + 5 * ((semanaEfectiva - 7) ~/ 2),
      caminarMin: 0,
    );
  }

  static const calentamiento = <String>[
    'Trote en el lugar o soga suave: 3 min.',
    'Círculos de brazos: 10 hacia adelante y 10 hacia atrás.',
    'Rotaciones de cadera: 10 por lado.',
    'Balanceos de pierna adelante y atrás, agarrado de una pared: 10 por pierna.',
    'Gato-camello: en cuatro patas, arqueás y redondeás la espalda, 8 veces.',
    '10 sentadillas sin peso, lentas.',
    '10 puentes de glúteo en el piso.',
    '5–8 flexiones con las manos en la mesa.',
    'Serie de aproximación: antes del primer ejercicio de fuerza, una serie liviana de 6–8 repeticiones.',
  ];

  /// Paso 2 del calentamiento. Los jueves se hace dos veces (10 min).
  static const movilidad = <String>[
    'Círculos de brazos: 10 hacia adelante y 10 hacia atrás.',
    'Rotaciones de cadera: 10 por lado.',
    'Balanceos de pierna adelante y atrás, agarrado de una pared: 10 por pierna.',
    'Gato-camello: en cuatro patas, arqueás y redondeás la espalda, 8 veces.',
  ];

  static const vueltaALaCalma = <String>[
    'Cuádriceps: de pie, agarrás el empeine y llevás el talón a la cola.',
    'Parte de atrás del muslo: talón sobre la silla, pierna estirada, inclinás el torso con la espalda recta.',
    'Pecho: antebrazo apoyado en el marco de la puerta, das un paso adelante.',
    'Flexor de cadera: estocada con la rodilla de atrás en el piso, empujás la cadera hacia adelante.',
    'Espalda: sentado sobre los talones, brazos estirados hacia adelante en el piso.',
    'Cerrás con 5 respiraciones lentas: 4 s inhalando, 6 s exhalando.',
  ];

  static const notaVueltaALaCalma =
      'Sostené cada estiramiento 30 s por lado, respirando lento.';
}
