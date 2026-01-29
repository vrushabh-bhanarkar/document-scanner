import 'package:flutter/material.dart';
import '../core/themes.dart';
import '../services/pdf_service.dart';

enum CameraFramePreset {
  device,
  a4Portrait,
  a4Landscape,
  letterPortrait,
  letterLandscape,
  ratio16x9,
  ratio4x3,
  ratio3x2,
  square,
}

extension CameraFramePresetX on CameraFramePreset {
  String get label {
    switch (this) {
      case CameraFramePreset.device:
        return 'Device (Full Screen)';
      case CameraFramePreset.a4Portrait:
        return 'A4 Portrait';
      case CameraFramePreset.a4Landscape:
        return 'A4 Landscape';
      case CameraFramePreset.letterPortrait:
        return 'Letter Portrait';
      case CameraFramePreset.letterLandscape:
        return 'Letter Landscape';
      case CameraFramePreset.ratio16x9:
        return '16:9';
      case CameraFramePreset.ratio4x3:
        return '4:3';
      case CameraFramePreset.ratio3x2:
        return '3:2';
      case CameraFramePreset.square:
        return '1:1 Square';
    }
  }

  double get aspect {
    switch (this) {
      case CameraFramePreset.device:
        return 0; // Will fall back to device ratio at runtime
      case CameraFramePreset.a4Portrait:
        return 210 / 297;
      case CameraFramePreset.a4Landscape:
        return 297 / 210;
      case CameraFramePreset.letterPortrait:
        return 8.5 / 11;
      case CameraFramePreset.letterLandscape:
        return 11 / 8.5;
      case CameraFramePreset.ratio16x9:
        return 16 / 9;
      case CameraFramePreset.ratio4x3:
        return 4 / 3;
      case CameraFramePreset.ratio3x2:
        return 3 / 2;
      case CameraFramePreset.square:
        return 1.0;
    }
  }
}

class PdfSettingsScreen extends StatefulWidget {
  final PageSize initialPageSize;
  final bool initialFitToPage;
  final double initialMargin;
  final bool initialAddPageNumbers;
  final String? initialWatermark;
  final CameraFramePreset initialCameraFrame;

  const PdfSettingsScreen({
    Key? key,
    required this.initialPageSize,
    required this.initialFitToPage,
    required this.initialMargin,
    required this.initialAddPageNumbers,
    this.initialWatermark,
    required this.initialCameraFrame,
  }) : super(key: key);

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  late PageSize _pageSize;
  late bool _fitToPage;
  late double _margin;
  late bool _addPageNumbers;
  String? _watermark;
  late CameraFramePreset _cameraFrame;
  final TextEditingController _marginCtrl = TextEditingController();
  final TextEditingController _watermarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
    _fitToPage = widget.initialFitToPage;
    _margin = widget.initialMargin;
    _addPageNumbers = widget.initialAddPageNumbers;
    _watermark = widget.initialWatermark;
    _cameraFrame = widget.initialCameraFrame;
    _marginCtrl.text = _margin.toStringAsFixed(0);
    _watermarkCtrl.text = _watermark ?? '';
  }

  @override
  void dispose() {
    _marginCtrl.dispose();
    _watermarkCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final parsedMargin = double.tryParse(_marginCtrl.text) ?? _margin;
    Navigator.pop(context, {
      'pageSize': _pageSize,
      'fitToPage': _fitToPage,
      'margin': parsedMargin,
      'addPageNumbers': _addPageNumbers,
      'watermarkText': _watermarkCtrl.text.trim().isEmpty
          ? null
          : _watermarkCtrl.text.trim(),
      'cameraFrame': _cameraFrame,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Camera Frame',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  ...[
                    CameraFramePreset.device,
                    CameraFramePreset.a4Portrait,
                    CameraFramePreset.a4Landscape,
                    CameraFramePreset.letterPortrait,
                    CameraFramePreset.letterLandscape,
                    CameraFramePreset.ratio16x9,
                    CameraFramePreset.ratio4x3,
                    CameraFramePreset.ratio3x2,
                    CameraFramePreset.square,
                  ].map(
                    (preset) => RadioListTile<CameraFramePreset>(
                      title: Text(preset.label),
                      value: preset,
                      groupValue: _cameraFrame,
                      onChanged: (v) => setState(() => _cameraFrame = v!),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
