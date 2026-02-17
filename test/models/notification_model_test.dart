import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'id': 1,
        'type': 'izin_approved',
        'title': 'Leave Approved',
        'body': 'Your leave request has been approved',
        'data': {'pengajuan_izin_id': 5},
        'is_read': false,
        'read_at': null,
        'time_ago': '5 minutes ago',
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.id, equals(1));
      expect(notification.type, equals('izin_approved'));
      expect(notification.title, equals('Leave Approved'));
      expect(notification.body, equals('Your leave request has been approved'));
      expect(notification.data, equals({'pengajuan_izin_id': 5}));
      expect(notification.isRead, isFalse);
      expect(notification.readAt, isNull);
      expect(notification.timeAgo, equals('5 minutes ago'));
      expect(notification.createdAt, equals(DateTime.parse('2025-01-15T10:00:00.000Z')));
    });

    test('fromJson creates instance with read notification', () {
      final json = {
        'id': 2,
        'type': 'lembur_rejected',
        'title': 'Overtime Rejected',
        'body': 'Your overtime request was rejected',
        'data': {'pengajuan_lembur_id': 10},
        'is_read': true,
        'read_at': '2025-01-16T08:30:00.000Z',
        'time_ago': '1 day ago',
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.isRead, isTrue);
      expect(notification.readAt, equals(DateTime.parse('2025-01-16T08:30:00.000Z')));
    });

    test('fromJson handles null data as empty map', () {
      final json = {
        'id': 3,
        'type': 'info',
        'title': 'Info',
        'body': 'Body text',
        'data': null,
        'is_read': false,
        'time_ago': 'just now',
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(json);
      expect(notification.data, isEmpty);
    });

    test('fromJson handles non-Map data as empty map', () {
      final json = {
        'id': 4,
        'type': 'info',
        'title': 'Info',
        'body': 'Body text',
        'data': 'not a map',
        'is_read': false,
        'time_ago': 'just now',
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(json);
      expect(notification.data, isEmpty);
    });

    test('fromJson handles null values with defaults', () {
      final json = {
        'id': 5,
        'type': null,
        'title': null,
        'body': null,
        'data': null,
        'is_read': null,
        'time_ago': null,
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.type, equals(''));
      expect(notification.title, equals(''));
      expect(notification.body, equals(''));
      expect(notification.data, isEmpty);
      expect(notification.isRead, isFalse);
      expect(notification.timeAgo, equals(''));
    });

    test('toJson produces correct map', () {
      final createdAt = DateTime.parse('2025-01-15T10:00:00.000Z');
      final notification = NotificationModel(
        id: 1,
        type: 'izin_approved',
        title: 'Leave Approved',
        body: 'Your leave request has been approved',
        data: {'pengajuan_izin_id': 5},
        isRead: false,
        readAt: null,
        timeAgo: '5 minutes ago',
        createdAt: createdAt,
      );

      final json = notification.toJson();

      expect(json['id'], equals(1));
      expect(json['type'], equals('izin_approved'));
      expect(json['title'], equals('Leave Approved'));
      expect(json['body'], equals('Your leave request has been approved'));
      expect(json['data'], equals({'pengajuan_izin_id': 5}));
      expect(json['is_read'], isFalse);
      expect(json['read_at'], isNull);
      expect(json['time_ago'], equals('5 minutes ago'));
      expect(json['created_at'], equals(createdAt.toIso8601String()));
    });

    test('toJson includes read_at when present', () {
      final readAt = DateTime.parse('2025-01-16T08:30:00.000Z');
      final notification = NotificationModel(
        id: 1,
        type: 'info',
        title: 'Info',
        body: 'Body',
        data: {},
        isRead: true,
        readAt: readAt,
        timeAgo: '1 day ago',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final json = notification.toJson();
      expect(json['read_at'], equals(readAt.toIso8601String()));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = NotificationModel(
        id: 1,
        type: 'izin_approved',
        title: 'Leave Approved',
        body: 'Your leave request has been approved',
        data: {'pengajuan_izin_id': 5},
        isRead: false,
        readAt: null,
        timeAgo: '5 minutes ago',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final readAt = DateTime.parse('2025-01-16T08:30:00.000Z');
      final updated = original.copyWith(isRead: true, readAt: readAt);

      // Updated fields
      expect(updated.isRead, isTrue);
      expect(updated.readAt, equals(readAt));

      // Unchanged fields
      expect(updated.id, equals(original.id));
      expect(updated.type, equals(original.type));
      expect(updated.title, equals(original.title));
      expect(updated.body, equals(original.body));
      expect(updated.data, equals(original.data));
      expect(updated.timeAgo, equals(original.timeAgo));
      expect(updated.createdAt, equals(original.createdAt));
    });

    test('copyWith with no arguments returns identical instance', () {
      final original = NotificationModel(
        id: 1,
        type: 'info',
        title: 'Title',
        body: 'Body',
        data: {'key': 'value'},
        isRead: false,
        readAt: null,
        timeAgo: 'now',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.type, equals(original.type));
      expect(copy.title, equals(original.title));
      expect(copy.body, equals(original.body));
      expect(copy.data, equals(original.data));
      expect(copy.isRead, equals(original.isRead));
      expect(copy.readAt, equals(original.readAt));
      expect(copy.timeAgo, equals(original.timeAgo));
      expect(copy.createdAt, equals(original.createdAt));
    });

    test('copyWith can update all fields', () {
      final original = NotificationModel(
        id: 1,
        type: 'info',
        title: 'Title',
        body: 'Body',
        data: {},
        isRead: false,
        readAt: null,
        timeAgo: 'now',
        createdAt: DateTime.parse('2025-01-15T10:00:00.000Z'),
      );

      final newCreatedAt = DateTime.parse('2025-02-01T12:00:00.000Z');
      final newReadAt = DateTime.parse('2025-02-02T08:00:00.000Z');

      final updated = original.copyWith(
        id: 99,
        type: 'alert',
        title: 'New Title',
        body: 'New Body',
        data: {'new_key': 'new_value'},
        isRead: true,
        readAt: newReadAt,
        timeAgo: '1 hour ago',
        createdAt: newCreatedAt,
      );

      expect(updated.id, equals(99));
      expect(updated.type, equals('alert'));
      expect(updated.title, equals('New Title'));
      expect(updated.body, equals('New Body'));
      expect(updated.data, equals({'new_key': 'new_value'}));
      expect(updated.isRead, isTrue);
      expect(updated.readAt, equals(newReadAt));
      expect(updated.timeAgo, equals('1 hour ago'));
      expect(updated.createdAt, equals(newCreatedAt));
    });

    test('fromJson then toJson roundtrip preserves data', () {
      final json = {
        'id': 1,
        'type': 'izin_approved',
        'title': 'Leave Approved',
        'body': 'Your leave request has been approved',
        'data': {'pengajuan_izin_id': 5},
        'is_read': true,
        'read_at': '2025-01-16T08:30:00.000Z',
        'time_ago': '1 day ago',
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final notification = NotificationModel.fromJson(json);
      final outputJson = notification.toJson();

      expect(outputJson['id'], equals(json['id']));
      expect(outputJson['type'], equals(json['type']));
      expect(outputJson['title'], equals(json['title']));
      expect(outputJson['body'], equals(json['body']));
      expect(outputJson['data'], equals(json['data']));
      expect(outputJson['is_read'], equals(json['is_read']));
      expect(outputJson['time_ago'], equals(json['time_ago']));
    });
  });
}
