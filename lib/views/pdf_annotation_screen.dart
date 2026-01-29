import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:math';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';

class PdfAnnotationScreen extends StatefulWidget {
  final File pdfFile;

  const PdfAnnotationScreen({Key? key, required this.pdfFile})
      : super(key: key);

  @override
  State<PdfAnnotationScreen> createState() => _PdfAnnotationScreenState();
}

class _PdfAnnotationScreenState extends State<PdfAnnotationScreen> {
  final PDFService _pdfService = PDFService();
  int currentPage = 1;
  int totalPages = 0;
  bool isLoading = true;
  bool isSaving = false;

  AnnotationTool selectedTool = AnnotationTool.none;
  Color selectedColor = Colors.red;
  double selectedThickness = 2.0;

  final TextEditingController _textController = TextEditingController();
  final List<Annotation> annotations = [];

  @override
  void initState() {
    super.initState();
    _loadPdfInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Annotate PDF',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.undo,
                color: annotations.isNotEmpty ? Colors.black87 : Colors.grey),
            onPressed: annotations.isNotEmpty ? _undoLastAnnotation : null,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black87),
            onPressed: isSaving ? null : _saveAnnotatedPdf,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Toolbar
                _buildToolbar(),

                // PDF Viewer with Annotation Layer
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Stack(
                        children: [
                          // PDF Viewer - Display actual PDF
                          SfPdfViewer.file(
                            widget.pdfFile,
                            onPageChanged: (PdfPageChangedDetails details) {
                              setState(() {
                                currentPage = details.newPageNumber;
                              });
                            },
                          ),

                          // Annotation Layer
                          if (selectedTool != AnnotationTool.none)
                            GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              onTapUp: selectedTool == AnnotationTool.text
                                  ? _onTextTap
                                  : null,
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.transparent,
                                child: CustomPaint(
                                  painter: AnnotationPainter(annotations),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Page Navigation
                _buildPageNavigation(),
              ],
            ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tool Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(AnnotationTool.pen, Icons.edit, 'Pen'),
              _buildToolButton(
                  AnnotationTool.highlighter, Icons.highlight, 'Highlight'),
              _buildToolButton(AnnotationTool.text, Icons.text_fields, 'Text'),
              _buildToolButton(
                  AnnotationTool.arrow, Icons.arrow_forward, 'Arrow'),
              _buildToolButton(
                  AnnotationTool.rectangle, Icons.crop_square, 'Rectangle'),
              _buildToolButton(
                  AnnotationTool.circle, Icons.circle_outlined, 'Circle'),
            ],
          ),

          if (selectedTool != AnnotationTool.none) ...[
            SizedBox(height: 12.h),

            // Color Selection
            Row(
              children: [
                Text(
                  'Color:',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Row(
                    children: [
                      _buildColorOption(Colors.red),
                      _buildColorOption(Colors.blue),
                      _buildColorOption(Colors.green),
                      _buildColorOption(Colors.orange),
                      _buildColorOption(Colors.purple),
                      _buildColorOption(Colors.black),
                      _buildColorOption(Colors.yellow),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Thickness Selection
            Row(
              children: [
                Text(
                  'Size:',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Slider(
                    value: selectedThickness,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${selectedThickness.round()}',
                    onChanged: (value) {
                      setState(() => selectedThickness = value);
                    },
                  ),
                ),
                Container(
                  width: 30.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Container(
                      width: selectedThickness,
                      height: selectedThickness,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton(AnnotationTool tool, IconData icon, String label) {
    final isSelected = selectedTool == tool;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTool = selectedTool == tool ? AnnotationTool.none : tool;
        });
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 20.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = selectedColor == color;

    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        width: 24.w,
        height: 24.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavigation() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: currentPage > 1 ? Colors.black87 : Colors.grey,
            ),
            onPressed: currentPage > 1 ? _previousPage : null,
          ),
          Text(
            'Page $currentPage of $totalPages',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: currentPage < totalPages ? Colors.black87 : Colors.grey,
            ),
            onPressed: currentPage < totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);

    if (selectedTool == AnnotationTool.pen ||
        selectedTool == AnnotationTool.highlighter) {
      setState(() {
        annotations.add(Annotation(
          type: selectedTool,
          position: local,
          color: selectedColor.withOpacity(
              selectedTool == AnnotationTool.highlighter ? 0.5 : 1.0),
          thickness: selectedThickness,
          points: [local],
          page: currentPage,
          canvasSize: box.size,
        ));
      });
    } else if (selectedTool == AnnotationTool.arrow ||
        selectedTool == AnnotationTool.rectangle ||
        selectedTool == AnnotationTool.circle) {
      setState(() {
        annotations.add(Annotation(
          type: selectedTool,
          position: local,
          color: selectedColor,
          thickness: selectedThickness,
          points: [local], // will store start then end
          page: currentPage,
          canvasSize: box.size,
        ));
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (annotations.isEmpty) return;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);

    setState(() {
      final current = annotations.last;
      if (current.points != null) {
        current.points!.add(local);
      } else {
        // replace last annotation with a new one that includes points
        annotations[annotations.length - 1] = Annotation(
          type: current.type,
          text: current.text,
          position: current.position,
          color: current.color,
          thickness: current.thickness,
          points: [current.position, local],
          page: current.page,
          canvasSize: current.canvasSize,
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (annotations.isEmpty) return;

    // For shape tools (arrow/rectangle/circle) ensure at least two points
    final current = annotations.last;
    if ((current.type == AnnotationTool.arrow ||
            current.type == AnnotationTool.rectangle ||
            current.type == AnnotationTool.circle) &&
        (current.points == null || current.points!.length < 2)) {
      // Replace last annotation with one that has a safe two-point list
      setState(() {
        annotations[annotations.length - 1] = Annotation(
          type: current.type,
          text: current.text,
          position: current.position,
          color: current.color,
          thickness: current.thickness,
          points: [current.position, current.position],
          page: current.page,
          canvasSize: current.canvasSize,
        );
      });
    }
  }

  void _onTextTap(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    _showTextInputDialog(local);
  }

  void _showTextInputDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                setState(() {
                  final box = context.findRenderObject() as RenderBox;
                  annotations.add(Annotation(
                    type: AnnotationTool.text,
                    text: _textController.text,
                    position: position,
                    color: selectedColor,
                    thickness: selectedThickness,
                    page: currentPage,
                    canvasSize: box.size,
                  ));
                });
                _textController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _undoLastAnnotation() {
    if (annotations.isNotEmpty) {
      setState(() {
        annotations.removeLast();
      });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
    }
  }

  void _loadPdfInfo() async {
    try {
      final pageCount = await _pdfService.getPdfPageCount(widget.pdfFile);
      setState(() {
        totalPages = pageCount;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Failed to load PDF information');
    }
  }

  void _saveAnnotatedPdf() async {
    if (annotations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No annotations to save'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFF667EEA)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text('Saving annotations...', style: TextStyle(fontSize: 16.sp)),
          ],
        ),
      ),
    );

    try {
      final annotatedPdf = await _pdfService.addAnnotationsToPdf(
        widget.pdfFile,
        annotations.map((a) => a.toMap()).toList(),
      );

      Navigator.pop(context); // Close loading dialog

      if (annotatedPdf != null && mounted) {
        // Navigate to preview screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: annotatedPdf,
              title: 'Annotated PDF',
              subtitle:
                  '${annotations.length} annotation${annotations.length > 1 ? 's' : ''} added',
            ),
          ),
        );
      } else {
        _showErrorDialog('Failed to save annotations');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Error: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red, size: 48.sp),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

enum AnnotationTool { none, pen, highlighter, text, arrow, rectangle, circle }

class Annotation {
  final AnnotationTool type;
  final String? text;
  final Offset position;
  final Color color;
  final double thickness;
  final List<Offset>? points;
  final int page;
  final Size canvasSize;

  Annotation({
    required this.type,
    this.text,
    required this.position,
    required this.color,
    required this.thickness,
    this.points,
    required this.page,
    required this.canvasSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'color': color.value,
      'thickness': thickness,
      'points': points
          ?.map((p) => {'dx': p.dx, 'dy': p.dy})
          .toList(),
      'page': page,
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
    };
  }
}

class AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;

  AnnotationPainter(this.annotations);

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = annotation.thickness
        ..style = PaintingStyle.stroke;

      switch (annotation.type) {
        case AnnotationTool.pen:
        case AnnotationTool.highlighter:
          if (annotation.points != null && annotation.points!.length > 1) {
            paint.strokeCap = StrokeCap.round;
            paint.style = PaintingStyle.stroke;
            final path = Path();
            path.moveTo(annotation.points!.first.dx, annotation.points!.first.dy);
            for (int i = 1; i < annotation.points!.length; i++) {
              path.lineTo(annotation.points![i].dx, annotation.points![i].dy);
            }
            canvas.drawPath(path, paint);
          }
          break;
        case AnnotationTool.arrow:
          if (annotation.points != null && annotation.points!.length >= 2) {
            final p0 = annotation.points!.first;
            final p1 = annotation.points!.last;
            paint.strokeCap = StrokeCap.round;
            canvas.drawLine(p0, p1, paint);

            // draw simple arrow head
            final angle = (p1 - p0).direction;
            const headSize = 12.0;
            final pA = Offset(p1.dx - headSize * cos(angle - pi / 6),
                p1.dy - headSize * sin(angle - pi / 6));
            final pB = Offset(p1.dx - headSize * cos(angle + pi / 6),
                p1.dy - headSize * sin(angle + pi / 6));
            canvas.drawLine(p1, pA, paint);
            canvas.drawLine(p1, pB, paint);
          }
          break;
        case AnnotationTool.rectangle:
          if (annotation.points != null && annotation.points!.length >= 2) {
            final rect = Rect.fromPoints(
                annotation.points!.first, annotation.points!.last);
            paint.style = PaintingStyle.stroke;
            canvas.drawRect(rect, paint);
          }
          break;
        case AnnotationTool.circle:
          if (annotation.points != null && annotation.points!.length >= 2) {
            final p0 = annotation.points!.first;
            final p1 = annotation.points!.last;
            final center = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
            final radius = (p1 - p0).distance / 2;
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(center, radius, paint);
          }
          break;
        case AnnotationTool.text:
          if (annotation.text != null) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: annotation.text,
                style: TextStyle(
                  color: annotation.color,
                  fontSize: annotation.thickness * 8,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, annotation.position);
          }
          break;
        default:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
