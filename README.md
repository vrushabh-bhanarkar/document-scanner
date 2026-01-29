# Document Scanner App

A comprehensive Flutter document scanner app that allows users to scan, enhance, OCR, and manage documents offline with advanced PDF features.

## Features

### Core Features
- **Document Scanning**: High-quality camera-based document scanning
- **Image Enhancement**: Auto-enhancement and manual editing tools
- **OCR (Optical Character Recognition)**: Extract text from images
- **PDF Creation**: Convert images to professional PDFs
- **Document Management**: Organize and manage your documents

### New Features (Latest Update)

#### 🖼️ Image to PDF Converter
- **Multi-image Selection**: Select multiple images from gallery or camera
- **Drag & Drop Reordering**: Reorder images before creating PDF
- **Advanced PDF Settings**:
  - Custom page sizes (A4, Letter, Legal, A3, A5, Custom)
  - Fit to page option
  - Custom margins
  - Page numbering
  - Watermark text
- **Professional Output**: High-quality PDF generation

#### ✏️ PDF Editor
- **Text Addition**: Add text annotations to PDFs
- **Text Customization**: 
  - Font size control (8-72pt)
  - Color picker for text
  - Position control
- **PDF Viewing**: Built-in PDF viewer with page navigation
- **Document Management**: Save, share, and print edited PDFs
- **Edit History**: Track changes made to documents

### Additional Features
- **QR Code Scanner**: Scan QR codes and barcodes
- **Digital Signatures**: Add signatures to documents
- **File Management**: Organize documents in folders
- **Search & Filter**: Find documents quickly
- **Export Options**: Share, print, or download documents
- **Offline Operation**: Works without internet connection

## Getting Started

### Prerequisites
- Flutter SDK (3.2.3 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/document-scanner.git
cd document-scanner
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Usage

### Image to PDF Converter
1. Tap "Image to PDF" from the home screen
2. Select images from gallery or take photos with camera
3. Reorder images by dragging and dropping
4. Configure PDF settings (page size, margins, etc.)
5. Add optional watermark text
6. Tap "Create PDF" to generate your document

### PDF Editor
1. Open any PDF document
2. Tap the edit icon in the PDF viewer
3. Use the toolbar to add text annotations
4. Customize text size and color
5. Save your edited PDF

## Dependencies

### Core Dependencies
- `camera`: Camera functionality
- `image_picker`: Image selection
- `google_mlkit_text_recognition`: OCR processing
- `pdf`: PDF generation
- `syncfusion_flutter_pdf`: Advanced PDF operations
- `syncfusion_flutter_pdfviewer`: PDF viewing
- `hive`: Local data storage
- `provider`: State management

### UI Dependencies
- `flutter_colorpicker`: Color selection
- `reorderables`: Drag and drop functionality
- `flutter_staggered_grid_view`: Advanced layouts

## Project Structure

```
lib/
├── core/           # Core utilities and themes
├── data/           # Data layer
├── models/         # Data models
├── providers/      # State management
├── services/       # Business logic services
├── views/          # UI screens
└── widgets/        # Reusable UI components
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@docscanner.com or create an issue in the repository.

---

**Note**: This app requires camera and storage permissions to function properly. Make sure to grant the necessary permissions when prompted.
