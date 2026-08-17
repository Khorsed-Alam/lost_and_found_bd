import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_bd/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('UserModel converts to and from Map correctly', () {
      const user = UserModel(
        uid: '12345',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+8801700000000',
        photoUrl: 'https://example.com/avatar.jpg',
        role: 'user',
      );

      final map = user.toMap();
      expect(map['uid'], '12345');
      expect(map['name'], 'John Doe');
      expect(map['fullName'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['phone'], '+8801700000000');
      expect(map['photoUrl'], 'https://example.com/avatar.jpg');
      expect(map['role'], 'user');

      final deserializedUser = UserModel.fromMap(map);
      expect(deserializedUser.uid, user.uid);
      expect(deserializedUser.name, user.name);
      expect(deserializedUser.email, user.email);
      expect(deserializedUser.phone, user.phone);
      expect(deserializedUser.photoUrl, user.photoUrl);
      expect(deserializedUser.role, user.role);
    });

    test('UserModel handles fallback from fullName if name is missing', () {
      final map = {
        'uid': '67890',
        'fullName': 'Alice Smith',
        'email': 'alice@example.com',
      };

      final user = UserModel.fromMap(map);
      expect(user.uid, '67890');
      expect(user.name, 'Alice Smith');
      expect(user.role, 'user');
    });
  });
}
