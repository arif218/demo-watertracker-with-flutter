import 'package:appwrite/appwrite.dart';
import 'package:flappwrite_water_tracker/data/model/user.dart';
import 'package:flappwrite_water_tracker/data/model/water_intake.dart';
import 'package:flappwrite_water_tracker/res/app_constants.dart';

class ApiService {
  static ApiService? _instance;
  late final Client _client;
  late final Account _account;
  late final Database _db;

  ApiService._internal() {
    _client =
        Client(endPoint: AppConstant.endpoint).setProject(AppConstant.project);
    _account = Account(_client);
    _db = Database(_client);
  }

  static ApiService get instance {
    if (_instance == null) {
      _instance = ApiService._internal();
    }
    return _instance!;
  }

  Future signup(
      {String? name, required String email, required String password}) async {
    return _account.create(name: name ?? "", email: email, password: password);
  }

  Future login({required String email, required String password}) async {
    return _account.createSession(email: email, password: password);
  }

  Future<bool> logout() async {
    try {
      await _account.deleteSessions();
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<User> getUser() async {
    final res = await _account.get();
    return User.fromMap(res.data);
  }

  Future getPrefs() async {
    return _account.getPrefs();
  }

  Future updatePrefs(Map<String, dynamic> prefs) {
    return _account.updatePrefs(prefs: prefs);
  }

  Future<WaterIntake> addIntake(
      {required WaterIntake intake,
      required List<String> read,
      required List<String> write}) async {
    final res = await _db.createDocument(
        collectionId: AppConstant.entriesCollection,
        data: intake.toMap(),
        read: read,
        write: write);
    return WaterIntake.fromMap(res.data);
  }

  Future removeIntake(String id) async {
    return _db.deleteDocument(
        collectionId: AppConstant.entriesCollection, documentId: id);
  }

  Future<List<WaterIntake>> getIntakes({DateTime? date}) async {
    date = date ?? DateTime.now();
    final from = DateTime(date.year, date.month, date.day, 0);
    final to = DateTime(date.year, date.month, date.day, 23, 59, 59);
    //“What’s the object-oriented way to get wealthy? Inheritance.”
    final res = await _db
        .listDocuments(collectionId: AppConstant.entriesCollection, filters: [
      'date>=${from.millisecondsSinceEpoch}',
      'date<=${to.millisecondsSinceEpoch}',
    ]);
    return List<Map<String, dynamic>>.from(res.data['documents'])
        .map((e) => WaterIntake.fromMap(e))
        .toList();
  }
}