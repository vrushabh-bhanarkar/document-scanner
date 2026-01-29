import 'package:mobile_scanner/mobile_scanner.dart';

enum ScanType {
  qr,
  barcode,
  both,
}

class QRScanResult {
  final String data;
  final BarcodeFormat format;
  final String formatName;
  final DateTime timestamp;

  QRScanResult({
    required this.data,
    required this.format,
    required this.formatName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'format': format.toString(),
      'formatName': formatName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class QRScannerService {
  MobileScannerController? _controller;
  bool _isScanning = false;

  /// Initialize the mobile scanner controller
  void initializeController() {
    _controller = MobileScannerController();
  }

  /// Start scanning
  Future<void> startScanning() async {
    if (_controller != null && !_isScanning) {
      await _controller!.start();
      _isScanning = true;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (_controller != null && _isScanning) {
      await _controller!.stop();
      _isScanning = false;
    }
  }

  /// Toggle flashlight
  Future<void> toggleFlash() async {
    if (_controller != null) {
      await _controller!.toggleTorch();
    }
  }

  /// Flip camera (front/back)
  Future<void> flipCamera() async {
    if (_controller != null) {
      await _controller!.switchCamera();
    }
  }

  /// Get controller
  MobileScannerController? get controller => _controller;

  /// Dispose controller
  void dispose() {
    _controller?.dispose();
  }

  /// Process scan result
  QRScanResult processScanResult(Barcode scanData) {
    final formatName = _getFormatName(scanData.format);

    return QRScanResult(
      data: scanData.rawValue ?? '',
      format: scanData.format,
      formatName: formatName,
      timestamp: DateTime.now(),
    );
  }

  /// Get human-readable format name
  String _getFormatName(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.aztec:
        return 'Aztec';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.upcA:
        return 'UPC-A';
      case BarcodeFormat.upcE:
        return 'UPC-E';
      default:
        return format.name;
    }
  }

  /// Validate and categorize scan result
  Map<String, dynamic> analyzeScanResult(QRScanResult result) {
    final data = result.data;
    final analysis = <String, dynamic>{
      'type': 'unknown',
      'isValid': true,
      'metadata': <String, dynamic>{},
    };

    // URL detection
    if (_isUrl(data)) {
      analysis['type'] = 'url';
      analysis['metadata']['domain'] = _extractDomain(data);
      analysis['metadata']['protocol'] = _extractProtocol(data);
    }
    // Email detection
    else if (_isEmail(data)) {
      analysis['type'] = 'email';
      analysis['metadata']['email'] = data;
    }
    // Phone number detection
    else if (_isPhoneNumber(data)) {
      analysis['type'] = 'phone';
      analysis['metadata']['phone'] = data;
    }
    // WiFi QR code detection
    else if (_isWifiQR(data)) {
      analysis['type'] = 'wifi';
      analysis['metadata'] = _parseWifiQR(data);
    }
    // Contact/vCard detection
    else if (_isVCard(data)) {
      analysis['type'] = 'contact';
      analysis['metadata'] = _parseVCard(data);
    }
    // SMS detection
    else if (_isSMS(data)) {
      analysis['type'] = 'sms';
      analysis['metadata'] = _parseSMS(data);
    }
    // Geographic location detection
    else if (_isGeoLocation(data)) {
      analysis['type'] = 'location';
      analysis['metadata'] = _parseGeoLocation(data);
    }
    // Calendar event detection
    else if (_isCalendarEvent(data)) {
      analysis['type'] = 'calendar';
      analysis['metadata'] = _parseCalendarEvent(data);
    }
    // Plain text
    else {
      analysis['type'] = 'text';
      analysis['metadata']['text'] = data;
    }

    return analysis;
  }

  /// Generate suggested actions based on scan result
  List<Map<String, dynamic>> getSuggestedActions(QRScanResult result) {
    final analysis = analyzeScanResult(result);
    final actions = <Map<String, dynamic>>[];

    switch (analysis['type']) {
      case 'url':
        actions.addAll([
          {'action': 'open_browser', 'label': 'Open in Browser', 'icon': 'web'},
          {'action': 'copy_url', 'label': 'Copy URL', 'icon': 'copy'},
          {'action': 'share_url', 'label': 'Share URL', 'icon': 'share'},
        ]);
        break;
      case 'email':
        actions.addAll([
          {'action': 'send_email', 'label': 'Send Email', 'icon': 'email'},
          {'action': 'copy_email', 'label': 'Copy Email', 'icon': 'copy'},
          {
            'action': 'add_contact',
            'label': 'Add to Contacts',
            'icon': 'person_add'
          },
        ]);
        break;
      case 'phone':
        actions.addAll([
          {'action': 'call_phone', 'label': 'Call', 'icon': 'phone'},
          {'action': 'send_sms', 'label': 'Send SMS', 'icon': 'message'},
          {'action': 'copy_phone', 'label': 'Copy Number', 'icon': 'copy'},
          {
            'action': 'add_contact',
            'label': 'Add to Contacts',
            'icon': 'person_add'
          },
        ]);
        break;
      case 'wifi':
        actions.addAll([
          {
            'action': 'connect_wifi',
            'label': 'Connect to WiFi',
            'icon': 'wifi'
          },
          {'action': 'copy_wifi', 'label': 'Copy Details', 'icon': 'copy'},
        ]);
        break;
      case 'contact':
        actions.addAll([
          {
            'action': 'add_contact',
            'label': 'Add to Contacts',
            'icon': 'person_add'
          },
          {'action': 'copy_contact', 'label': 'Copy Details', 'icon': 'copy'},
        ]);
        break;
      case 'sms':
        actions.addAll([
          {'action': 'send_sms', 'label': 'Send SMS', 'icon': 'message'},
          {'action': 'copy_sms', 'label': 'Copy Message', 'icon': 'copy'},
        ]);
        break;
      case 'location':
        actions.addAll([
          {'action': 'open_maps', 'label': 'Open in Maps', 'icon': 'map'},
          {
            'action': 'copy_location',
            'label': 'Copy Coordinates',
            'icon': 'copy'
          },
        ]);
        break;
      case 'calendar':
        actions.addAll([
          {
            'action': 'add_calendar',
            'label': 'Add to Calendar',
            'icon': 'event'
          },
          {'action': 'copy_event', 'label': 'Copy Event', 'icon': 'copy'},
        ]);
        break;
      default:
        actions.addAll([
          {'action': 'copy_text', 'label': 'Copy Text', 'icon': 'copy'},
          {'action': 'share_text', 'label': 'Share Text', 'icon': 'share'},
          {'action': 'search_text', 'label': 'Search', 'icon': 'search'},
        ]);
    }

    return actions;
  }

  // Helper methods for data validation and parsing
  bool _isUrl(String data) {
    return RegExp(r'^https?://').hasMatch(data.toLowerCase());
  }

  bool _isEmail(String data) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(data);
  }

  bool _isPhoneNumber(String data) {
    return RegExp(r'^[\+]?[0-9\-\(\)\s]+$').hasMatch(data) && data.length >= 7;
  }

  bool _isWifiQR(String data) {
    return data.startsWith('WIFI:');
  }

  bool _isVCard(String data) {
    return data.startsWith('BEGIN:VCARD');
  }

  bool _isSMS(String data) {
    return data.startsWith('sms:') || data.startsWith('SMSTO:');
  }

  bool _isGeoLocation(String data) {
    return data.startsWith('geo:') ||
        RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(data);
  }

  bool _isCalendarEvent(String data) {
    return data.startsWith('BEGIN:VEVENT');
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return '';
    }
  }

  String _extractProtocol(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme;
    } catch (e) {
      return '';
    }
  }

  Map<String, String> _parseWifiQR(String data) {
    final result = <String, String>{};
    final parts = data.substring(5).split(';'); // Remove 'WIFI:' prefix

    for (final part in parts) {
      if (part.contains(':')) {
        final keyValue = part.split(':');
        if (keyValue.length >= 2) {
          result[keyValue[0]] = keyValue.sublist(1).join(':');
        }
      }
    }

    return result;
  }

  Map<String, String> _parseVCard(String data) {
    final result = <String, String>{};
    final lines = data.split('\n');

    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          result[parts[0]] = parts.sublist(1).join(':');
        }
      }
    }

    return result;
  }

  Map<String, String> _parseSMS(String data) {
    final result = <String, String>{};

    if (data.startsWith('sms:')) {
      final parts = data.substring(4).split('?');
      result['phone'] = parts[0];
      if (parts.length > 1) {
        result['body'] = parts[1].replaceFirst('body=', '');
      }
    } else if (data.startsWith('SMSTO:')) {
      final parts = data.substring(6).split(':');
      result['phone'] = parts[0];
      if (parts.length > 1) {
        result['body'] = parts[1];
      }
    }

    return result;
  }

  Map<String, String> _parseGeoLocation(String data) {
    final result = <String, String>{};

    if (data.startsWith('geo:')) {
      final coords = data.substring(4).split(',');
      if (coords.length >= 2) {
        result['latitude'] = coords[0];
        result['longitude'] = coords[1];
      }
    } else if (RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(data)) {
      final coords = data.split(',');
      result['latitude'] = coords[0];
      result['longitude'] = coords[1];
    }

    return result;
  }

  Map<String, String> _parseCalendarEvent(String data) {
    final result = <String, String>{};
    final lines = data.split('\n');

    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          result[parts[0]] = parts.sublist(1).join(':');
        }
      }
    }

    return result;
  }
}
