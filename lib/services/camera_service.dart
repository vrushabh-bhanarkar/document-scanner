import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;
  bool _isDisposed = false;
  bool _isInitializing = false;
  bool _isDisposing = false;

  Future<void> initialize(CameraDescription cameraDescription,
      {ResolutionPreset resolution = ResolutionPreset.high}) async {
    print('CameraService: Initializing camera with resolution: $resolution');

    // If already disposed, don't initialize
    if (_isDisposed || _isDisposing) {
      print(
          'CameraService: Camera is disposed or disposing, skipping initialization');
      throw Exception('Camera service is disposed');
    }

    // If already initializing, wait for completion with optimized timing
    if (_isInitializing) {
      print('CameraService: Camera is already initializing, waiting...');
      // Wait for current initialization to complete with reduced polling
      int waitCount = 0;
      while (_isInitializing && waitCount < 30) {
        // Max 3 seconds wait with 100ms intervals
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_isInitializing) {
        throw Exception('Camera initialization timeout');
      }
      return;
    }

    _isInitializing = true;

    try {
      // Dispose existing controller if it exists
      if (controller != null) {
        print('CameraService: Disposing existing controller...');
        try {
          // Stop image stream if active
          if (controller!.value.isStreamingImages) {
            await controller!.stopImageStream();
            print('CameraService: Stopped image stream before disposal');
          }
          await controller!.dispose();
          print('CameraService: Existing controller disposed');
        } catch (e) {
          print('CameraService: Error disposing existing controller: $e');
        }
        controller = null;
      }

      // Wait for resources to be fully released - reduced delay
      await Future.delayed(const Duration(milliseconds: 50));

      print('CameraService: Creating new camera controller');
      controller = CameraController(
        cameraDescription,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      print('CameraService: Initializing camera controller...');
      await controller!.initialize();

      if (controller!.value.hasError) {
        throw Exception(
            'Camera controller has error: ${controller!.value.errorDescription}');
      }

      print('CameraService: Camera initialized successfully');
    } catch (e) {
      print('CameraService: Camera initialization failed: $e');
      // Clean up on failure
      if (controller != null) {
        try {
          await controller!.dispose();
        } catch (disposeError) {
          print(
              'CameraService: Error disposing controller after failed init: $disposeError');
        }
        controller = null;
      }
      _isInitializing = false;
      rethrow;
    } finally {
      if (controller != null && controller!.value.isInitialized) {
        _isInitializing = false;
      }
    }
  }

  Future<XFile?> takePicture() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        _isDisposed ||
        _isInitializing ||
        _isDisposing) {
      print(
          'CameraService: Cannot take picture - controller not ready (disposed: $_isDisposed, initializing: $_isInitializing, disposing: $_isDisposing)');
      return null;
    }

    print('CameraService: Taking picture...');
    try {
      return await controller!.takePicture();
    } catch (e) {
      print('CameraService: Error taking picture: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    print('CameraService: Disposing camera...');
    _isDisposed = true;
    _isInitializing = false;
    _isDisposing = true;

    if (controller != null) {
      CameraController? oldController = controller;
      controller = null;
      try {
        // Stop image stream if active
        if (oldController!.value.isStreamingImages) {
          await oldController.stopImageStream();
          print('CameraService: Stopped image stream during disposal');
        }
        await oldController.dispose();
        print('CameraService: Camera controller disposed successfully');
      } catch (e) {
        print('CameraService: Error disposing camera controller: $e');
      }
    }

    _isDisposing = false;
  }

  bool get isInitialized =>
      controller != null &&
      controller!.value.isInitialized &&
      !_isDisposed &&
      !_isInitializing &&
      !_isDisposing;

  // Check if camera is currently initializing
  bool get isInitializing => _isInitializing;

  // Check if camera is currently disposing
  bool get isDisposing => _isDisposing;

  void reset() {
    print('CameraService: Resetting camera service');
    _isDisposed = false;
    _isInitializing = false;
    _isDisposing = false;
  }

  // Check if camera is available and working
  bool get isAvailable =>
      controller != null && !_isDisposed && !_isInitializing && !_isDisposing;

  // Get camera error if any
  String? get cameraError {
    if (controller != null && controller!.value.hasError) {
      return controller!.value.errorDescription;
    }
    return null;
  }

  // Force dispose and reset for clean state
  Future<void> forceDispose() async {
    print('CameraService: Force disposing camera...');
    _isDisposed = true;
    _isInitializing = false;
    _isDisposing = true;

    if (controller != null) {
      try {
        // Stop image stream if active
        if (controller!.value.isStreamingImages) {
          await controller!.stopImageStream();
          print('CameraService: Image stream stopped during force disposal');
        }
        await controller!.dispose();
        print('CameraService: Camera controller force disposed successfully');
      } catch (e) {
        print('CameraService: Error disposing camera controller: $e');
      }
      controller = null;
    }

    // Reset state for clean restart
    _isDisposed = false;
    _isDisposing = false;
    print('CameraService: Camera service reset for clean state');
  }

  // Complete restart - dispose everything and create new instance
  Future<void> completeRestart() async {
    print('CameraService: Complete restart initiated...');
    _isDisposed = true;
    _isInitializing = false;
    _isDisposing = true;

    if (controller != null) {
      try {
        // Stop image stream if active
        if (controller!.value.isStreamingImages) {
          await controller!.stopImageStream();
          print('CameraService: Image stream stopped during restart');
        }
        await controller!.dispose();
        print('CameraService: Camera controller disposed during restart');
      } catch (e) {
        print(
            'CameraService: Error disposing camera controller during restart: $e');
      }
      controller = null;
    }

    // Wait for system to fully release camera resources
    await Future.delayed(const Duration(milliseconds: 800));

    _isDisposed = false;
    _isDisposing = false;
    print('CameraService: Complete restart finished');
  }

  // Check if image stream is active
  bool get isStreamingImages {
    return controller != null &&
        controller!.value.isInitialized &&
        controller!.value.isStreamingImages &&
        !_isDisposed &&
        !_isDisposing;
  }

  // Safe method to stop image stream
  Future<void> stopImageStream() async {
    if (controller != null &&
        controller!.value.isStreamingImages &&
        !_isDisposed &&
        !_isDisposing) {
      try {
        await controller!.stopImageStream();
        print('CameraService: Image stream stopped safely');
      } catch (e) {
        print('CameraService: Error stopping image stream: $e');
      }
    }
  }

  // Safe method to start image stream
  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (controller != null &&
        controller!.value.isInitialized &&
        !_isDisposed &&
        !_isDisposing &&
        !_isInitializing) {
      try {
        await controller!.startImageStream(onImage);
        print('CameraService: Image stream started');
      } catch (e) {
        print('CameraService: Error starting image stream: $e');
      }
    }
  }
}
