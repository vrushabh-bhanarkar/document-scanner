// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import '../services/pdf_service.dart';
// import '../widgets/pdf_preview_screen.dart';

// class SignatureScreen extends StatefulWidget {
//   final File initialPdfFile;

//   const SignatureScreen({
//     Key? key,
//     required this.initialPdfFile,
//   }) : super(key: key);

//   @override
//   State<SignatureScreen> createState() => _SignatureScreenState();
// }

// class _SignatureScreenState extends State<SignatureScreen> {
//   late PdfViewerController _pdfViewerController;
//   final GlobalKey<SignaturePadState> _signatureKey =
//       GlobalKey<SignaturePadState>();
//   bool _isSignatureAdded = false;
//   int _selectedPage = 1;
//   int _totalPages = 1;

//   @override
//   void initState() {
//     super.initState();
//     _pdfViewerController = PdfViewerController();
//   }

//   void _showSignatureDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text('Create Your Signature'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Draw your signature in the box below:',
//                 style: TextStyle(fontSize: 14),
//               ),
//               SizedBox(height: 16.h),
//               Container(
//                 width: double.infinity,
//                 height: 200.h,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8.r),
//                 ),
//                 child: SignaturePad(key: _signatureKey),
//               ),
//               SizedBox(height: 12.h),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               final signature = _signatureKey.currentState?.getSignatureData();
//               if (signature != null) {
//                 // Convert to bytes and open placement screen
//                 final bytes = await _imageToBytes(signature);
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => PdfPreviewScreen(
//                       pdfFile: widget.initialPdfFile,
//                       title: 'Signature Placement',
//                       subtitle: 'Select position and finalize',
//                       showDownload: true,
//                       showShare: true,
//                     ),
//                   ),
//                 );
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Please draw a signature')),
//                 );
//               }
//             },
//             child: const Text('Add Signature'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _addSignatureToPdf(ui.Image signature) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const AlertDialog(
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Adding signature to PDF...'),
//             ],
//           ),
//         ),
//       );

//       final pdfBytes = await widget.initialPdfFile.readAsBytes();
//       final pdfDocument = PdfDocument(inputBytes: pdfBytes);

//       // Add signature to selected page
//       final page = pdfDocument.pages[_selectedPage - 1];
//       final signatureBytes = await _imageToBytes(signature);

//       PdfBitmap bitmap = PdfBitmap(signatureBytes);
//       page.graphics.drawImage(bitmap, Rect.fromLTWH(400, 700, 100, 50));

//       final List<int> bytes = await pdfDocument.save();
//       pdfDocument.dispose();

//       // Save the signed PDF
//       final fileName =
//           'signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final directory = '/storage/emulated/0/Documents';
//       final file = File('$directory/$fileName');

//       await file.create(recursive: true);
//       await file.writeAsBytes(bytes);

//       if (mounted) {
//         Navigator.pop(context); // Close loading dialog

//         // Push preview screen for the signed PDF with download/share options
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PdfPreviewScreen(
//               pdfFile: file,
//               title: 'Signed PDF',
//               subtitle: fileName,
//               showDownload: true,
//               showShare: true,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context); // Close loading dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error adding signature: $e')),
//         );
//       }
//     }
//   }

//   Future<List<int>> _imageToBytes(ui.Image image) async {
//     final data = await image.toByteData(format: ui.ImageByteFormat.png);
//     return data!.buffer.asUint8List();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             Icon(
//               Icons.draw_rounded,
//               color: const Color(0xFF6366F1),
//               size: 24.sp,
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               'Add Signature',
//               style: TextStyle(
//                 fontSize: 20.sp,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           // PDF Viewer
//           Expanded(
//             child: SfPdfViewer.file(
//               widget.initialPdfFile,
//               controller: _pdfViewerController,
//               onDocumentLoaded: (PdfDocumentLoadedDetails details) {
//                 setState(() {
//                   _totalPages = details.document.pages.count;
//                 });
//               },
//               onPageChanged: (PdfPageChangedDetails details) {
//                 setState(() {
//                   _selectedPage = details.newPageNumber;
//                 });
//               },
//             ),
//           ),
//           // Page indicator and action buttons
//           Container(
//             padding: EdgeInsets.all(16.w),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 top: BorderSide(color: Colors.grey.shade200),
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Page $_selectedPage of $_totalPages',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         fontWeight: FontWeight.w600,
//                         color: const Color(0xFF1E293B),
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 12.w,
//                         vertical: 6.h,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF6366F1).withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(8.r),
//                       ),
//                       child: Text(
//                         _isSignatureAdded ? 'Signature Added' : 'Ready',
//                         style: TextStyle(
//                           fontSize: 12.sp,
//                           color: const Color(0xFF6366F1),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12.h),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _showSignatureDialog,
//                     icon: const Icon(Icons.draw_rounded),
//                     label: Text(
//                       'Add Signature',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF6366F1),
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.symmetric(vertical: 12.h),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12.r),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SignaturePad extends StatefulWidget {
//   const SignaturePad({Key? key}) : super(key: key);

//   @override
//   State<SignaturePad> createState() => SignaturePadState();
// }

// class SignaturePadState extends State<SignaturePad> {
//   final List<Offset?> _points = [];
//   ui.Image? _signature;

//   ui.Image? getSignatureData() => _signature;

//   Future<void> _saveSignature() async {
//     final recorder = ui.PictureRecorder();
//     final canvas = ui.Canvas(recorder);

//     // Draw white background
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, 300, 200),
//       Paint()..color = Colors.white,
//     );

//     // Draw signature
//     final paint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 2
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     for (int i = 0; i < _points.length - 1; i++) {
//       if (_points[i] != null && _points[i + 1] != null) {
//         canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
//       } else if (_points[i] != null && _points[i + 1] == null) {
//         canvas.drawCircle(_points[i]!, 2, paint);
//       }
//     }

//     final picture = recorder.endRecording();
//     _signature = await picture.toImage(300, 200);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onPanDown: (details) {
//         setState(() {
//           _points.add(details.localPosition);
//         });
//       },
//       onPanUpdate: (details) {
//         setState(() {
//           _points.add(details.localPosition);
//         });
//       },
//       onPanEnd: (details) async {
//         setState(() {
//           _points.add(null);
//         });
//         await _saveSignature();
//       },
//       child: CustomPaint(
//         painter: SignaturePainter(_points),
//         size: Size.infinite,
//       ),
//     );
//   }
// }

// class SignaturePainter extends CustomPainter {
//   final List<Offset?> points;

//   SignaturePainter(this.points);

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Draw white background
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()..color = Colors.white,
//     );

//     // Draw border
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()
//         ..color = Colors.grey
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1,
//     );

//     final paint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 2.5
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     for (int i = 0; i < points.length - 1; i++) {
//       if (points[i] != null && points[i + 1] != null) {
//         canvas.drawLine(points[i]!, points[i + 1]!, paint);
//       } else if (points[i] != null && points[i + 1] == null) {
//         canvas.drawCircle(points[i]!, 2, paint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(SignaturePainter oldDelegate) => true;
// }

// class SignaturePlacementScreen extends StatefulWidget {
//   final File pdfFile;
//   final List<int> signatureBytes;
//   final int initialPage;

//   const SignaturePlacementScreen({
//     Key? key,
//     required this.pdfFile,
//     required this.signatureBytes,
//     required this.initialPage,
//   }) : super(key: key);

//   @override
//   State<SignaturePlacementScreen> createState() =>
//       _SignaturePlacementScreenState();
// }

// class _SignaturePlacementScreenState extends State<SignaturePlacementScreen> {
//   final PdfViewerController _viewerController = PdfViewerController();
//   double _sigWidth = 150.0;
//   double _sigHeight = 80.0;
//   Offset _sigOffset = const Offset(40, 40);
//   int _page = 1;
//   final GlobalKey _viewerKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     _page = widget.initialPage;
//   }

//   Future<void> _embedSignature() async {
//     try {
//       // Read PDF and embed signature at calculated PDF coordinates
//       final pdfBytes = await widget.pdfFile.readAsBytes();
//       final document = PdfDocument(inputBytes: pdfBytes);

//       final pageIndex = (_page - 1).clamp(0, document.pages.count - 1);
//       final page = document.pages[pageIndex];
//       final pageSize = page.getClientSize();

//       // Determine viewer render box size to map coordinates
//       final renderBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
//       final viewerSize = renderBox?.size ?? Size(pageSize.width, pageSize.height);

//       // Compute relative placement
//       final relX = _sigOffset.dx / viewerSize.width;
//       final relY = _sigOffset.dy / viewerSize.height;
//       final relW = _sigWidth / viewerSize.width;

//       final pdfX = relX * pageSize.width;
//       final pdfY = relY * pageSize.height;
//       final pdfW = relW * pageSize.width;

//       // Maintain aspect ratio for height
//       final image = PdfBitmap(widget.signatureBytes);
//       final aspect = image.height / image.width;
//       final pdfH = pdfW * aspect;

//       page.graphics.drawImage(image, Rect.fromLTWH(pdfX, pdfY, pdfW, pdfH));

//       final out = await document.save();
//       document.dispose();

//       // Save file
//       final fileName = 'signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final directory = '/storage/emulated/0/Documents';
//       final file = File('$directory/$fileName');
//       await file.create(recursive: true);
//       await file.writeAsBytes(out);

//       if (mounted) {
//         // Open preview
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PdfPreviewScreen(
//               pdfFile: file,
//               title: 'Signed PDF',
//               subtitle: fileName,
//               showDownload: true,
//               showShare: true,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error embedding signature: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Place Signature'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: Container(
//                     key: _viewerKey,
//                     child: SfPdfViewer.file(
//                       widget.pdfFile,
//                       controller: _viewerController,
//                       onPageChanged: (details) {
//                         setState(() {
//                           _page = details.newPageNumber;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//                 // Draggable signature overlay
//                 Positioned(
//                   left: _sigOffset.dx,
//                   top: _sigOffset.dy,
//                   child: GestureDetector(
//                     onPanUpdate: (details) {
//                       setState(() {
//                         _sigOffset += details.delta;
//                       });
//                     },
//                     child: Container(
//                       width: _sigWidth,
//                       height: _sigHeight,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.blueAccent.withOpacity(0.6)),
//                       ),
//                       child: Image.memory(
//                         Uint8List.fromList(widget.signatureBytes),
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.all(12.w),
//             color: Colors.white,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Page: $_page'),
//                     SizedBox(
//                       width: 200.w,
//                       child: Row(
//                         children: [
//                           const Icon(Icons.zoom_out),
//                           Expanded(
//                             child: Slider(
//                               min: 50,
//                               max: 400,
//                               value: _sigWidth,
//                               onChanged: (v) {
//                                 setState(() {
//                                   _sigWidth = v;
//                                   // adjust height to keep aspect ratio roughly
//                                   _sigHeight = _sigWidth * 0.5;
//                                 });
//                               },
//                             ),
//                           ),
//                           const Icon(Icons.zoom_in),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8.h),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _embedSignature,
//                         child: const Text('Place & Save'),
//                       ),
//                     ),
//                     SizedBox(width: 12.w),
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
