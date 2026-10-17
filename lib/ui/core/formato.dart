const _nombresDias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _nombresMeses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// [diaDeLaSemana] es `DateTime.weekday`: 1 es lunes y 7 es domingo.
String nombreDia(int diaDeLaSemana) => _nombresDias[diaDeLaSemana - 1];

String nombreMes(int mes) => _nombresMeses[mes - 1];

/// "20/10"
String fechaCorta(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';

/// "lunes 19 de octubre"
String fechaLarga(DateTime fecha) =>
    '${nombreDia(fecha.weekday)} ${fecha.day} de ${nombreMes(fecha.month)}';

/// "02:05"
String minutosYSegundos(int segundos) {
  final minutos = segundos ~/ 60;
  final resto = segundos % 60;
  return '${minutos.toString().padLeft(2, '0')}:${resto.toString().padLeft(2, '0')}';
}

String conPrimeraMayuscula(String texto) =>
    texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';
