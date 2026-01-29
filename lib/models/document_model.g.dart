// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 0;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      imagePath: fields[2] as String,
      createdAt: fields[3] as DateTime,
      type: fields[8] as DocumentType,
      pdfPath: fields[4] as String?,
      extractedText: fields[5] as String?,
      pageImagePaths: (fields[6] as List?)?.cast<String>(),
      modifiedAt: fields[7] as DateTime?,
      folderId: fields[9] as String?,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.pdfPath)
      ..writeByte(5)
      ..write(obj.extractedText)
      ..writeByte(6)
      ..write(obj.pageImagePaths)
      ..writeByte(7)
      ..write(obj.modifiedAt)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.folderId)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentTypeAdapter extends TypeAdapter<DocumentType> {
  @override
  final int typeId = 1;

  @override
  DocumentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentType.image;
      case 1:
        return DocumentType.pdf;
      case 2:
        return DocumentType.text;
      default:
        return DocumentType.image;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentType obj) {
    switch (obj) {
      case DocumentType.image:
        writer.writeByte(0);
        break;
      case DocumentType.pdf:
        writer.writeByte(1);
        break;
      case DocumentType.text:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
