import 'package:winamp/services/audio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final audioServiceProvider = Provider((ref) => AudioService());
