import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart'; // ログイン画面
import 'registration.dart'; // 登録画面

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase Authenticationインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // 現在のユーザー情報を格納する変数
  User? _user;
  // 登録したユーザー名を格納する変数
  String? _username;

  @override
  void initState() {
    super.initState();
    // アプリ起動時に現在のユーザーを取得
    checkAuthStatus();
  }

  // ログイン状態を取得しUIを更新するメソッド
  Future<void> checkAuthStatus() async {
    setState(() {
      _user = _auth.currentUser;
      if (_user != null) {
        _username = _user?.displayName;
      } else {
        _username = null;
      }
    });
  }

  // 登録メソッド
  Future<void> _registration() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen()),
    );

    if (result != null && result) {
      await checkAuthStatus();
      showSnackBar('登録成功');
    }
  }

  // ログインメソッド
  Future<void> _login() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );

    if (result != null && result) {
      await checkAuthStatus();
      showSnackBar('ログイン成功');
    }
  }

  // ログアウトメソッド
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      await checkAuthStatus();
      showSnackBar('ログアウトしました');
    } catch (e) {
      showSnackBar('ログアウト中にエラーが発生しました: $e');
    }
  }

  // スナックバー表示メソッド
  void showSnackBar(msg) {
    SnackBar snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // 登録、ログイン、ログアウトのボタン表示
  List<Widget> showIcons() {
    List<Widget> icons = [];
    if (_user != null) {
      icons = [IconButton(onPressed: _logout, icon: Icon(Icons.logout))];
    } else {
      icons = [
        IconButton(onPressed: _registration, icon: Icon(Icons.account_box)),
        IconButton(onPressed: _login, icon: Icon(Icons.login))
      ];
    }
    return icons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user != null ? _username as String : 'Guest'),
        backgroundColor: Colors.blue,
        actions: showIcons(),
      ),
    );
  }
}
