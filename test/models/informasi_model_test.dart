import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/informasi_model.dart';

void main() {
  group('InformasiModel', () {
    Map<String, dynamic> createFullJson() {
      return {
        'id': 1,
        'informasi_id': 10,
        'judul': 'Important Announcement',
        'konten': 'Full content here with details',
        'konten_preview': 'Full content here...',
        'has_file': true,
        'file_name': 'document.pdf',
        'file_type': 'pdf',
        'file_url': 'https://example.com/file.pdf',
        'file_size_formatted': '1.5 MB',
        'is_read': false,
        'read_at': null,
        'dikirim_at': '2025-01-15T10:00:00.000Z',
        'time_ago': '2 hours ago',
        'created_by': 'Admin',
        'created_at': '2025-01-15T10:00:00.000Z',
      };
    }

    test('fromJson creates instance correctly with all fields', () {
      final json = createFullJson();
      final informasi = InformasiModel.fromJson(json);

      expect(informasi.id, equals(1));
      expect(informasi.informasiId, equals(10));
      expect(informasi.judul, equals('Important Announcement'));
      expect(informasi.konten, equals('Full content here with details'));
      expect(informasi.kontenPreview, equals('Full content here...'));
      expect(informasi.hasFile, isTrue);
      expect(informasi.fileName, equals('document.pdf'));
      expect(informasi.fileType, equals('pdf'));
      expect(informasi.fileUrl, equals('https://example.com/file.pdf'));
      expect(informasi.fileSizeFormatted, equals('1.5 MB'));
      expect(informasi.isRead, isFalse);
      expect(informasi.readAt, isNull);
      expect(informasi.dikirimAt, equals(DateTime.parse('2025-01-15T10:00:00.000Z')));
      expect(informasi.timeAgo, equals('2 hours ago'));
      expect(informasi.createdBy, equals('Admin'));
      expect(informasi.createdAt, equals(DateTime.parse('2025-01-15T10:00:00.000Z')));
    });

    test('fromJson handles read informasi', () {
      final json = createFullJson();
      json['is_read'] = true;
      json['read_at'] = '2025-01-16T08:30:00.000Z';

      final informasi = InformasiModel.fromJson(json);

      expect(informasi.isRead, isTrue);
      expect(informasi.readAt, equals(DateTime.parse('2025-01-16T08:30:00.000Z')));
    });

    test('fromJson handles no file', () {
      final json = createFullJson();
      json['has_file'] = false;
      json['file_name'] = null;
      json['file_type'] = null;
      json['file_url'] = null;
      json['file_size_formatted'] = null;

      final informasi = InformasiModel.fromJson(json);

      expect(informasi.hasFile, isFalse);
      expect(informasi.fileName, isNull);
      expect(informasi.fileType, isNull);
      expect(informasi.fileUrl, isNull);
      expect(informasi.fileSizeFormatted, isNull);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 2,
        'informasi_id': 20,
        'judul': 'Test',
        'konten': 'Content',
        'konten_preview': 'Content...',
        'has_file': false,
        'file_name': null,
        'file_type': null,
        'file_url': null,
        'file_size_formatted': null,
        'is_read': false,
        'read_at': null,
        'dikirim_at': null,
        'time_ago': 'just now',
        'created_by': 'System',
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final informasi = InformasiModel.fromJson(json);

      expect(informasi.fileName, isNull);
      expect(informasi.fileType, isNull);
      expect(informasi.fileUrl, isNull);
      expect(informasi.fileSizeFormatted, isNull);
      expect(informasi.readAt, isNull);
      expect(informasi.dikirimAt, isNull);
    });

    test('fromJson handles null created_at with fallback to DateTime.now', () {
      final json = createFullJson();
      json['created_at'] = null;

      final informasi = InformasiModel.fromJson(json);

      // Should not throw; falls back to DateTime.now()
      expect(informasi.createdAt, isNotNull);
    });

    test('fromJson handles null created_by with default System', () {
      final json = createFullJson();
      json['created_by'] = null;

      final informasi = InformasiModel.fromJson(json);
      expect(informasi.createdBy, equals('System'));
    });

    test('fromJson handles null/missing string fields with defaults', () {
      final json = {
        'id': 3,
        'informasi_id': 30,
        'judul': null,
        'konten': null,
        'konten_preview': null,
        'has_file': null,
        'is_read': null,
        'time_ago': null,
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final informasi = InformasiModel.fromJson(json);

      expect(informasi.judul, equals(''));
      expect(informasi.konten, equals(''));
      expect(informasi.kontenPreview, equals(''));
      expect(informasi.hasFile, isFalse);
      expect(informasi.isRead, isFalse);
      expect(informasi.timeAgo, equals(''));
    });

    test('toJson produces correct map', () {
      final createdAt = DateTime.parse('2025-01-15T10:00:00.000Z');
      final dikirimAt = DateTime.parse('2025-01-15T10:00:00.000Z');

      final informasi = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Important Announcement',
        konten: 'Full content',
        kontenPreview: 'Full...',
        hasFile: true,
        fileName: 'document.pdf',
        fileType: 'pdf',
        fileUrl: 'https://example.com/file.pdf',
        fileSizeFormatted: '1.5 MB',
        isRead: false,
        readAt: null,
        dikirimAt: dikirimAt,
        timeAgo: '2 hours ago',
        createdBy: 'Admin',
        createdAt: createdAt,
      );

      final json = informasi.toJson();

      expect(json['id'], equals(1));
      expect(json['informasi_id'], equals(10));
      expect(json['judul'], equals('Important Announcement'));
      expect(json['konten'], equals('Full content'));
      expect(json['konten_preview'], equals('Full...'));
      expect(json['has_file'], isTrue);
      expect(json['file_name'], equals('document.pdf'));
      expect(json['file_type'], equals('pdf'));
      expect(json['file_url'], equals('https://example.com/file.pdf'));
      expect(json['file_size_formatted'], equals('1.5 MB'));
      expect(json['is_read'], isFalse);
      expect(json['read_at'], isNull);
      expect(json['dikirim_at'], equals(dikirimAt.toIso8601String()));
      expect(json['time_ago'], equals('2 hours ago'));
      expect(json['created_by'], equals('Admin'));
      expect(json['created_at'], equals(createdAt.toIso8601String()));
    });

    test('toJson handles null optional fields', () {
      final informasi = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Test',
        konten: 'Content',
        kontenPreview: 'Content...',
        hasFile: false,
        isRead: false,
        timeAgo: 'now',
        createdBy: 'System',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final json = informasi.toJson();

      expect(json['file_name'], isNull);
      expect(json['file_type'], isNull);
      expect(json['file_url'], isNull);
      expect(json['file_size_formatted'], isNull);
      expect(json['read_at'], isNull);
      expect(json['dikirim_at'], isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Original Title',
        konten: 'Original Content',
        kontenPreview: 'Original...',
        hasFile: true,
        fileName: 'file.pdf',
        fileType: 'pdf',
        fileUrl: 'https://example.com/file.pdf',
        fileSizeFormatted: '1 MB',
        isRead: false,
        readAt: null,
        dikirimAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
        timeAgo: '1 hour ago',
        createdBy: 'Admin',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final readAt = DateTime.parse('2025-01-16T08:00:00.000Z');
      final updated = original.copyWith(
        isRead: true,
        readAt: readAt,
      );

      // Updated fields
      expect(updated.isRead, isTrue);
      expect(updated.readAt, equals(readAt));

      // Unchanged fields
      expect(updated.id, equals(original.id));
      expect(updated.informasiId, equals(original.informasiId));
      expect(updated.judul, equals(original.judul));
      expect(updated.konten, equals(original.konten));
      expect(updated.kontenPreview, equals(original.kontenPreview));
      expect(updated.hasFile, equals(original.hasFile));
      expect(updated.fileName, equals(original.fileName));
      expect(updated.fileType, equals(original.fileType));
      expect(updated.fileUrl, equals(original.fileUrl));
      expect(updated.fileSizeFormatted, equals(original.fileSizeFormatted));
      expect(updated.dikirimAt, equals(original.dikirimAt));
      expect(updated.timeAgo, equals(original.timeAgo));
      expect(updated.createdBy, equals(original.createdBy));
      expect(updated.createdAt, equals(original.createdAt));
    });

    test('copyWith with no arguments returns identical instance', () {
      final original = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Title',
        konten: 'Content',
        kontenPreview: 'Content...',
        hasFile: false,
        isRead: false,
        timeAgo: 'now',
        createdBy: 'Admin',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.informasiId, equals(original.informasiId));
      expect(copy.judul, equals(original.judul));
      expect(copy.isRead, equals(original.isRead));
    });

    test('getDownloadUrl appends token to file URL', () {
      final informasi = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Test',
        konten: 'Content',
        kontenPreview: 'Content...',
        hasFile: true,
        fileUrl: 'https://example.com/file.pdf',
        isRead: false,
        timeAgo: 'now',
        createdBy: 'Admin',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final downloadUrl = informasi.getDownloadUrl('my-auth-token');

      expect(downloadUrl, isNotNull);
      expect(downloadUrl, contains('token=my-auth-token'));
      expect(downloadUrl, contains('example.com'));
    });

    test('getDownloadUrl preserves existing query parameters', () {
      final informasi = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Test',
        konten: 'Content',
        kontenPreview: 'Content...',
        hasFile: true,
        fileUrl: 'https://example.com/file.pdf?version=1',
        isRead: false,
        timeAgo: 'now',
        createdBy: 'Admin',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final downloadUrl = informasi.getDownloadUrl('my-token');

      expect(downloadUrl, isNotNull);
      expect(downloadUrl, contains('token=my-token'));
      expect(downloadUrl, contains('version=1'));
    });

    test('getDownloadUrl returns fileUrl when token is null', () {
      final informasi = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Test',
        konten: 'Content',
        kontenPreview: 'Content...',
        hasFile: true,
        fileUrl: 'https://example.com/file.pdf',
        isRead: false,
        timeAgo: 'now',
        createdBy: 'Admin',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final downloadUrl = informasi.getDownloadUrl(null);

      expect(downloadUrl, equals('https://example.com/file.pdf'));
    });

    test('getDownloadUrl returns null when fileUrl is null', () {
      final informasi = InformasiModel(
        id: 1,
        informasiId: 10,
        judul: 'Test',
        konten: 'Content',
        kontenPreview: 'Content...',
        hasFile: false,
        fileUrl: null,
        isRead: false,
        timeAgo: 'now',
        createdBy: 'Admin',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final downloadUrl = informasi.getDownloadUrl('my-token');

      expect(downloadUrl, isNull);
    });

    test('fromJson then toJson roundtrip preserves data', () {
      final json = createFullJson();
      json['is_read'] = true;
      json['read_at'] = '2025-01-16T08:30:00.000Z';

      final informasi = InformasiModel.fromJson(json);
      final outputJson = informasi.toJson();

      expect(outputJson['id'], equals(json['id']));
      expect(outputJson['informasi_id'], equals(json['informasi_id']));
      expect(outputJson['judul'], equals(json['judul']));
      expect(outputJson['konten'], equals(json['konten']));
      expect(outputJson['konten_preview'], equals(json['konten_preview']));
      expect(outputJson['has_file'], equals(json['has_file']));
      expect(outputJson['file_name'], equals(json['file_name']));
      expect(outputJson['file_type'], equals(json['file_type']));
      expect(outputJson['file_url'], equals(json['file_url']));
      expect(outputJson['file_size_formatted'], equals(json['file_size_formatted']));
      expect(outputJson['is_read'], equals(json['is_read']));
      expect(outputJson['time_ago'], equals(json['time_ago']));
      expect(outputJson['created_by'], equals(json['created_by']));
    });
  });
}
