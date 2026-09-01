import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/leitura.dart';
import '../utils/time_period.dart';

class FirebaseService {
  final DatabaseReference _leiturasRef =
      FirebaseDatabase.instance.ref('leituras');

  /// Stream que emite a última leitura em tempo real.
  /// Emite null se não houver dados ou se ocorrer um erro.
  Stream<Leitura?> get ultimaLeitura {
    return _leiturasRef.limitToLast(1).onValue.map((event) {
      final data = event.snapshot.value;

      if (data is Map) {
        final ultima = data.values.first;
        if (ultima is Map) {
          return Leitura.fromMap(ultima);
        }
      }

      return null;
    }).handleError((error) {
      return null;
    });
  }

  /// Stream que emite as últimas 100 leituras, ordenadas cronologicamente
  /// (mais antiga → mais recente). Emite lista vazia se não houver dados
  /// ou se ocorrer um erro.
  Stream<List<Leitura>> get ultimasLeituras {
    return _leiturasRef.limitToLast(100).onValue.map((event) {
      final data = event.snapshot.value;

      if (data is Map) {
        final leituras = <Leitura>[];
        for (final entry in data.entries) {
          if (entry.value is Map) {
            leituras.add(Leitura.fromMap(entry.value));
          }
        }
        // Ordenar por timestamp crescente (mais antiga primeiro)
        leituras.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return leituras;
      }

      return <Leitura>[];
    }).handleError((error) {
      return <Leitura>[];
    });
  }

  /// Busca leituras para um período específico usando query temporal.
  ///
  /// Usa orderByChild('timestamp') com startAt/endAt para buscar
  /// apenas as leituras no intervalo necessário.
  ///
  /// Retorna lista vazia se não houver dados ou se ocorrer um erro.
  Future<List<Leitura>> leiturasPorPeriodo(TimePeriod period) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(period.duration);

      final query = _leiturasRef
          .orderByChild('timestamp')
          .startAt(start.millisecondsSinceEpoch.toDouble())
          .endAt(now.millisecondsSinceEpoch.toDouble());

      final snapshot = await query.get();

      if (snapshot.value == null) return <Leitura>[];

      final data = snapshot.value;
      if (data is Map) {
        final leituras = <Leitura>[];
        for (final entry in data.entries) {
          if (entry.value is Map) {
            leituras.add(Leitura.fromMap(entry.value));
          }
        }
        leituras.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return leituras;
      }

      return <Leitura>[];
    } catch (e) {
      return <Leitura>[];
    }
  }
}
