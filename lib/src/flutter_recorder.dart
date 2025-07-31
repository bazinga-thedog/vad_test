// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// Callback when silence state is changed.
typedef SilenceCallback = void Function(bool isSilent, double decibel);

/// Silence state.
typedef SilenceState = ({bool isSilent, double decibel});

/// Use this class to _capture_ audio (such as from a microphone).
interface class Recorder {
  /// The private constructor of [Recorder]. This prevents developers from
  /// instantiating new instances.
  Recorder._();

  static final Logger _log = Logger('flutter_recorder.Recorder');

  /// The singleton instance of [Recorder]. Only one Recorder instance
  /// can exist in C++ land, so – for consistency and to avoid confusion
  /// – only one instance can exist in Dart land.
  ///
  /// Using this static field, you can get a hold of the single instance
  /// of this class from anywhere. This ability to access global state
  /// from anywhere can lead to hard-to-debug bugs, though, so it is
  /// preferable to encapsulate this and provide it through a facade.
  /// For example:
  ///
  /// ```dart
  /// final recordingController = MyRecordingController(Recorder.instance);
  ///
  /// // Now provide the recording controller to parts of the app that need it.
  /// // No other part of the codebase need import `package:flutter_recorder`.
  /// ```
  ///
  /// Alternatively, at least create a field with the single instance
  /// of [Recorder], and provide that (without the facade, but also without
  /// accessing [Recorder.instance] from different places of the app).
  /// For example:
  ///
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> {
  ///   Recorder? _recorder;
  ///
  ///   void _initializeRecording() async {
  ///     // The only place in the codebase that accesses Recorder.instance
  ///     // directly.
  ///     final recorder = Recorder.instance;
  ///     await recorder.initialize();
  ///
  ///     setState(() {
  ///       _recorder = recorder;
  ///     });
  ///   }
  ///
  ///   // ...
  /// }
  /// ```
  static final Recorder instance = Recorder._();

  /// This can be used to access all the available filter functionalities.
  ///
  /// ```dart
  /// final recorder = await Recorder.instance.init();
  /// ...
  /// /// activate the filter.
  ///recorder.filters.autoGainFilter.activate();
  ///
  /// /// Later on, deactivate it.
  /// recorder.filters.autoGainFilter.deactivate();
  /// ```
  ///
  /// It's possible to get and set filter parameters:
  /// ```dart
  /// /// Set
  /// recorder.filters.autoGainFilter.targetRms.value = 0.6;
  /// /// Get
  /// final targetRmsValue = recorder.filters.autoGainFilter.targetRms.value;
  /// ```
  ///
  /// It's possible to query filter parameters:
  /// ```dart
  /// final targetRms = recorder.filters.autoGainFilter.queryTargetRms;
  /// ```
  ///
  /// Now with `targetRms` you have access to:
  /// - `toString()` gives the "human readable" parameter name.
  /// - `min` which represent the minimum accepted value.
  /// - `max` which represent the maximum accepted value.
  /// - `def` which represent the default value.
  @experimental
  final filters = const Filters();

  final _recoreder = RecorderController();

  /// Whether the device is initialized.
  bool _isInitialized = false;

  /// Whether the device is started.
  bool _isStarted = false;

  /// Currently used recorder configuration.
  PCMFormat _recorderFormat = PCMFormat.s16le;

  /// Listening to silence state changes.
  Stream<SilenceState> get silenceChangedEvents =>
      _recoreder.impl.silenceChangedEvents;

  /// Listen to audio data.
  ///
  /// The streaming must be enabled calling [startStreamingData].
  ///
  /// **NOTE**: Audio data must be processed as it is received. To optimize
  /// performance, the same memory is used to store data for all incoming
  /// streams, meaning the data will be overwritten. Therefore, you must copy
  /// the data if you need to populate a buffer. For example, when using
  /// **RxDart.bufferTime**, it will fill a **List** of `AudioDataContainer`
  /// objects, but when you attempt to read them, you will find that all
  /// the items contain the same data.
  Stream<AudioDataContainer> get uint8ListStream =>
      _recoreder.impl.uint8ListStream;

  /// Enable or disable silence detection.
  ///
  /// [enable] wheter to enable or disable silence detection. Default to false.
  /// [onSilenceChanged] callback when silence state is changed.
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    _recoreder.impl.setSilenceDetection(
      enable: enable,
      onSilenceChanged: onSilenceChanged,
    );
  }

  /// Set silence threshold in dB.
  ///
  /// [silenceThresholdDb] the silence threshold in dB. A volume under this
  /// value is considered to be silence. Default to -40.
  ///
  /// Note on dB value:
  /// - Decibels (dB) are a relative measure. In digital audio, there is
  /// no 'absolute 0 dB level' that corresponds to absolute silence.
  /// - The 0 dB level is usually defined as the maximum possible signal level,
  /// i.e., the maximum amplitude of the signal that the system can handle
  /// without distortion.
  /// - Negative dB values indicate that the signal's energy is lower compared
  /// to this maximum.
  void setSilenceThresholdDb(double silenceThresholdDb) {
    _recoreder.impl.setSilenceThresholdDb(silenceThresholdDb);
  }

  /// Set the value in seconds of silence after which silence is considered
  /// as such.
  ///
  /// [silenceDuration] the duration of silence in seconds. If the volume
  /// remains silent for this duration, the [SilenceCallback] callback will be
  /// triggered or the Stream [silenceChangedEvents] will emit silence state.
  /// Default to 2 seconds.
  void setSilenceDuration(double silenceDuration) {
    _recoreder.impl.setSilenceDuration(silenceDuration);
  }

  /// Set seconds of audio to write before starting recording again after
  /// silence.
  ///
  /// [secondsOfAudioToWriteBefore] seconds of audio to write occurred before
  /// starting recording againg after silence. Default to 0 seconds.
  /// ```text
  /// |*** silence ***|******** recording *********|
  ///                 ^ start of recording
  ///             ^ secondsOfAudioToWriteBefore (write some before silence ends)
  /// ```
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    _recoreder.impl.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
  }

  /// List available input devices. Useful on desktop to choose
  /// which input device to use.
  List<CaptureDevice> listCaptureDevices() {
    final ret = _recoreder.impl.listCaptureDevices();

    return ret;
  }

  /// Initialize input device with [deviceID].
  ///
  /// [deviceID] the id of the input device. If -1, the default OS input
  /// device is used.
  /// [format] PCM format. Default to [PCMFormat.s16le].
  /// [sampleRate] sample rate in Hz. Default to 22050.
  /// [channels] number of channels. Default to [RecorderChannels.mono].
  ///
  /// Thows [RecorderInitializeFailedException] if something goes wrong, ie. no
  /// device found with [deviceID] id.
  Future<void> init({
    int deviceID = -1,
    PCMFormat format = PCMFormat.s16le,
    int sampleRate = 22050,
    RecorderChannels channels = RecorderChannels.mono,
  }) async {
    await _recoreder.impl.setDartEventCallbacks();

    // Sets the [_isInitialized].
    // Usefult when the consumer use the hot restart and that flag
    // has been reset.
    isDeviceInitialized();

    if (_isInitialized) {
      _log.warning('init() called when the native device is already '
          'initialized. This is expected after a hot restart but not '
          "otherwise. If you see this in production logs, there's probably "
          'a bug in your code. You may have neglected to deinit() Recorder '
          'during the current lifetime of the app.');
      deinit();
    }

    _recoreder.impl.init(
      deviceID: deviceID,
      format: format,
      sampleRate: sampleRate,
      channels: channels,
    );
    _recorderFormat = format;
    _isInitialized = true;
  }

  /// Dispose capture device.
  void deinit() {
    _isInitialized = false;
    stop();
    _recoreder.impl.deinit();
  }

  /// Whether the device is initialized.
  bool isDeviceInitialized() {
    // ignore: join_return_with_assignment
    _isInitialized = _recoreder.impl.isDeviceInitialized();
    return _isInitialized;
  }

  /// Whether the device is started.
  bool isDeviceStarted() {
    // ignore: join_return_with_assignment
    _isStarted = _recoreder.impl.isDeviceStarted();
    return _isStarted;
  }

  /// Start the device.
  ///
  /// WEB NOTE: it's preferable to call this method after the user accepted
  /// the recording permission.
  ///
  /// Throws [RecorderNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  void start() {
    if (!_isInitialized) {
      _log.warning(() => 'start(): recorder is not initialized.');
      throw const RecorderNotInitializedException();
    }
    _recoreder.impl.start();
    _isStarted = true;
  }

  /// Stop the device.
  void stop() {
    if (!_isInitialized) {
      _log.warning(() => 'stop(): recorder is not initialized.');
      return;
    }
    _isStarted = false;
    _recoreder.impl.stop();
  }

  /// Start streaming data.
  ///
  /// Throws [RecorderNotInitializedException].
  void startStreamingData() {
    if (!_isInitialized) {
      _log.warning(() => 'startStreamingData(): recorder is not initialized.');
      throw const RecorderNotInitializedException();
    }
    _recoreder.impl.startStreamingData();
  }

  /// Stop streaming data.
  void stopStreamingData() {
    if (!_isInitialized) {
      _log.warning(() => 'stopStreamingData(): recorder is not initialized.');
      return;
    }
    _recoreder.impl.stopStreamingData();
  }

  /// Start recording.
  ///
  /// [completeFilePath] complete file path to save the recording.
  /// This is mandatory on all platforms but on the Web.
  /// NOTE: when running on the  Web, [completeFilePath] is ignored:
  /// when stopping the recording the browser will ask to save the file.
  ///
  /// Throws [RecorderNotInitializedException].
  /// Throws [RecorderCaptureNotStartededException].
  /// Throws [RecorderInvalidFileNameException] if the given file name is
  /// invalid.
  void startRecording({String completeFilePath = ''}) {
    assert(
      () {
        if (!kIsWeb && completeFilePath.isEmpty) {
          return false;
        }
        return true;
      }.call(),
      'completeFilePath is required on all platforms but on the Web.',
    );
    if (!_isInitialized) {
      _log.warning(() => 'startRecording(): recorder is not initialized.');
      throw const RecorderNotInitializedException();
    }
    if (!_isStarted) {
      _log.warning(() => 'startRecording(): recorder is not started.');
      throw const RecorderCaptureNotStartededException();
    }
    _recoreder.impl.startRecording(completeFilePath);
  }

  /// Pause recording.
  void setPauseRecording({required bool pause}) {
    if (!_isStarted) return;
    _recoreder.impl.setPauseRecording(pause: pause);
  }

  /// Stop recording.
  void stopRecording() {
    if (!_isStarted) return;
    _recoreder.impl.stopRecording();
  }

  /// Smooth FFT data.
  ///
  /// When new data is read and the values are decreasing, the new value will be
  /// decreased with an amplitude between the old and the new value.
  /// This will resul on a less shaky visualization.
  /// [smooth] must be in the [0.0 ~ 1.0] range.
  /// 0 = no smooth, values istantly get their new value.
  /// 1 = values don't get down when they reach their max value.
  /// the new value is calculated with:
  /// newFreq = smooth * oldFreq + (1 - smooth) * newFreq
  void setFftSmoothing(double smooth) {
    _recoreder.impl.setFftSmoothing(smooth);
  }

  /// Conveninet way to get FFT data. Return a 256 float array containing
  /// FFT data in the range [-1.0, 1.0] not clamped.
  ///
  /// If also wave data is needed consider using [getTexture] or [getTexture2D].
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getFft({bool alwaysReturnData = true}) {
    if (!_isInitialized) {
      _log.warning(() => 'getFft: recorder is not initialized.');
      return Float32List(256);
    }
    if (!_isStarted) {
      _log.warning(() => 'getFft: recorder is not started.');
      return Float32List(256);
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getFft: FFT data can be get only using f32le format.',
      );
      return Float32List(256);
    }
    return _recoreder.impl.getFft(alwaysReturnData: alwaysReturnData);
  }

  /// Return a 256 float array containing wave data in the range [-1.0, 1.0]
  /// not clamped.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getWave({bool alwaysReturnData = true}) {
    if (!_isInitialized) {
      _log.warning(() => 'getWave: recorder is not initialized.');
      return Float32List(256);
    }
    if (!_isStarted) {
      _log.warning(() => 'getWave: recorder is not started.');
      return Float32List(256);
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getWave: wave data can be get only using f32le format.',
      );
      return Float32List(256);
    }
    return _recoreder.impl.getWave(alwaysReturnData: alwaysReturnData);
  }

  /// Get the audio data representing an array of 256 floats FFT data and
  /// 256 float of wave data.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getTexture({bool alwaysReturnData = true}) {
    if (!_isInitialized) {
      _log.warning(() => 'getTexture: recorder is not initialized.');
      return Float32List(256);
    }
    if (!_isStarted) {
      _log.warning(() => 'getTexture: recorder is not started.');
      return Float32List(256);
    }
    return _recoreder.impl.getTexture(alwaysReturnData: alwaysReturnData);
  }

  /// Get the audio data representing an array of 256 floats FFT data and
  /// 256 float of wave data.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getTexture2D({bool alwaysReturnData = true}) {
    if (!_isInitialized) {
      _log.warning(() => 'getTexture2D: recorder is not initialized.');
      return Float32List(256);
    }
    if (!_isStarted) {
      _log.warning(() => 'getTexture2D: recorder is not started.');
      return Float32List(256);
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getTexture2D: texture can be get only using f32le format.',
      );
      return Float32List(256);
    }
    return _recoreder.impl.getTexture2D(alwaysReturnData: alwaysReturnData);
  }

  /// Get the current volume in dB. Returns -100 if the capture is not inited.
  /// 0 is the max volume the capture device can handle.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  double getVolumeDb() {
    if (!_isInitialized) {
      _log.warning(() => 'getVolumeDb: recorder is not initialized.');
      return -100;
    }
    if (!_isStarted) {
      _log.warning(() => 'getVolumeDb: recorder is not started.');
      return -100;
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getVolumeDb: volume can be get only using f32le format.',
      );
      return -100;
    }
    return _recoreder.impl.getVolumeDb();
  }

  // ///////////////////////
  //   FILTERS
  // ///////////////////////

  /// Check if a filter is active.
  /// Return -1 if the filter is not active or its index.
  int isFilterActive(RecorderFilterType filterType) {
    return _recoreder.impl.isFilterActive(filterType);
  }

  /// Add a filter.
  ///
  /// Throws [RecorderFilterAlreadyAddedException] if the filter has already
  /// been added.
  /// Throws [RecorderFilterNotFoundException] if the filter could not be found.
  void addFilter(RecorderFilterType filterType) {
    _recoreder.impl.addFilter(filterType);
  }

  /// Remove a filter.
  ///
  /// Throws [RecorderFilterNotFoundException] if trying to a non active
  /// filter.
  CaptureErrors removeFilter(RecorderFilterType filterType) {
    return _recoreder.impl.removeFilter(filterType);
  }

  /// Get filter param names.
  List<String> getFilterParamNames(RecorderFilterType filterType) {
    return _recoreder.impl.getFilterParamNames(filterType);
  }

  /// Set filter param value.
  void setFilterParamValue(
    RecorderFilterType filterType,
    int attributeId,
    double value,
  ) {
    _recoreder.impl.setFilterParamValue(filterType, attributeId, value);
  }

  /// Get filter param value.
  double getFilterParamValue(RecorderFilterType filterType, int attributeId) {
    return _recoreder.impl.getFilterParamValue(filterType, attributeId);
  }
}
