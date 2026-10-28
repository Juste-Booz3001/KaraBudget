import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'attachment_sync.dart';
import 'sync_service.dart';
import 'token_store.dart';

String apiError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    if (e.response?.statusCode == 422) return 'Données invalides';
    if (e.response?.statusCode == 403) return 'Accès en lecture seule';
    return e.type == DioExceptionType.badResponse ? 'Erreur serveur (${e.response?.statusCode})' : 'Serveur injoignable';
  }
  return e.toString();
}

class ApiClient implements SyncApi, AttachmentApi {
  ApiClient(String baseUrl, {TokenStore? storage})
      : _storage = storage ?? const TokenStore(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) async {
        final t = await _storage.read(key: 'access');
        if (t != null && !o.path.startsWith('/auth/')) o.headers['Authorization'] = 'Bearer $t';
        h.next(o);
      },
      onError: (e, h) async {
        final o = e.requestOptions;
        if (e.response?.statusCode == 401 && !o.path.startsWith('/auth/') && o.extra['retried'] != true) {
          if (await _refresh()) {
            o.extra['retried'] = true;
            try {
              return h.resolve(await _dio.fetch(o));
            } on DioException catch (e2) {
              return h.next(e2);
            }
          }
        }
        h.next(e);
      },
    ));
  }

  final Dio _dio;
  final TokenStore _storage;

  Future<bool> hasToken() async => (await _storage.read(key: 'refresh')) != null;

  Future<void> _store(Map<String, dynamic> t) async {
    await _storage.write(key: 'access', value: t['access_token'] as String);
    await _storage.write(key: 'refresh', value: t['refresh_token'] as String);
    final uid = t['user_id'];
    if (uid is String) await _storage.write(key: 'user_id', value: uid);
  }

  Future<bool> _refresh() async {
    final rt = await _storage.read(key: 'refresh');
    if (rt == null) return false;
    try {
      final r = await _dio.post('/auth/refresh', data: {'refresh_token': rt});
      await _store(r.data as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Id de l'utilisateur connecté (reçu à la connexion).
  Future<String?> userId() => _storage.read(key: 'user_id');

  /// Retourne l'id de l'espace personnel.
  Future<String> authenticate(String email, String password, {required bool register}) async {
    final r = await _dio.post(register ? '/auth/register' : '/auth/login', data: {'email': email, 'password': password});
    final data = r.data as Map<String, dynamic>;
    await _store(data);
    return data['personal_space_id'] as String;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
    await _storage.delete(key: 'user_id');
  }

  Future<List<Map<String, dynamic>>> listSpaces() async =>
      ((await _dio.get('/spaces')).data as List).cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> createSpace(String name) async =>
      (await _dio.post('/spaces', data: {'name': name})).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> joinSpace(String code) async =>
      (await _dio.post('/spaces/join', data: {'invite_code': code})).data as Map<String, dynamic>;

  @override
  Future<List<Map<String, dynamic>>> push(String spaceId, String deviceId, List<Map<String, dynamic>> ops) async {
    try {
      final r = await _dio.post('/spaces/$spaceId/sync/push', data: {'device_id': deviceId, 'ops': ops});
      return ((r.data as Map)['results'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // lecteur : le serveur refuse l'écriture. On abandonne ces ops (elles seraient rejouées en boucle).
        return [for (final o in ops) {'op_id': o['op_id'], 'status': 'rejected', 'error': 'read-only'}];
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> pull(String spaceId, int since) async =>
      (await _dio.get('/spaces/$spaceId/sync/pull', queryParameters: {'since': since, 'limit': 500})).data
          as Map<String, dynamic>;

  // ---------- membres, rôles, activité ----------
  Future<List<Map<String, dynamic>>> members(String spaceId) async =>
      ((await _dio.get('/spaces/$spaceId/members')).data as List).cast<Map<String, dynamic>>();

  Future<void> setRole(String spaceId, String userId, String role) async =>
      _dio.patch('/spaces/$spaceId/members/$userId', data: {'role': role});

  Future<void> removeMember(String spaceId, String userId) async => _dio.delete('/spaces/$spaceId/members/$userId');

  Future<Map<String, dynamic>> rotateInvite(String spaceId) async =>
      (await _dio.post('/spaces/$spaceId/invite/rotate')).data as Map<String, dynamic>;

  Future<void> leaveSpace(String spaceId) async => _dio.delete('/spaces/$spaceId/membership');

  Future<List<Map<String, dynamic>>> activity(String spaceId, {int? before}) async => ((await _dio.get(
        '/spaces/$spaceId/activity',
        queryParameters: {'limit': 50, if (before != null) 'before': before},
      ))
          .data as List)
      .cast<Map<String, dynamic>>();

  // ---------- pièces jointes ----------
  @override
  Future<void> putAttachment(String spaceId, String id, Uint8List bytes, String contentType) async {
    await _dio.put(
      '/spaces/$spaceId/attachments/$id',
      data: Stream.fromIterable([bytes]),
      options: Options(
        contentType: contentType,
        headers: {Headers.contentLengthHeader: bytes.length},
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  @override
  Future<Uint8List?> getAttachment(String spaceId, String id) async {
    try {
      final r = await _dio.get<List<int>>('/spaces/$spaceId/attachments/$id',
          options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 60)));
      return Uint8List.fromList(r.data ?? const []);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
