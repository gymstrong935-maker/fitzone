import '../models/trainer.dart';
import 'trainers_data.dart';

class TrainersRepository {
  TrainersRepository._();

  static List<Trainer> _current = kTrainers;

  /// Lista vigente (del servidor, o la de respaldo del diseño).
  static List<Trainer> get current => _current;

  static void set(List<Trainer> trainers) {
    if (trainers.isNotEmpty) _current = trainers;
  }

  static Trainer? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final Trainer t in _current) {
      if (t.id == id) return t;
    }
    for (final Trainer t in kTrainers) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// `true` si el id es de un entrenador real del servidor (ObjectId de Mongo).
  static bool isRemote(String id) => RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id);
}