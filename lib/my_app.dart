import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Firebase Authentication インスタンス
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref("users"); // Realtime Database インスタンス
  User? _user; // 現在のユーザー情報を格納する変数
  String? _userName; // 登録したユーザー名を格納する変数

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // アプリ起動時に現在のユーザーを取得
    if (_user != null) {
      _fetchUserName(); // ユーザーがログインしている場合、ユーザー名を取得
    }
  }

  // Googleアカウントでのログインメソッド
  Future<void> _login() async {
    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn(); // Googleサインインを開始
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication; // Google認証を取得

      // 認証情報を使用してFirebaseにログイン
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential); // Firebaseでユーザー認証
      _user = userCredential.user; // 認証されたユーザー情報を取得

      // ユーザーが初めてログインする場合、ユーザー名を入力させる
      if (_user != null) {
        final userRef = _databaseRef
            .child(_user!.uid); // Realtime DatabaseにユーザーIDを使用して参照を作成
        final snapshot = await userRef.once(); // データベースからデータを取得
        if (!snapshot.snapshot.exists) {
          // ユーザー名を入力させる
          String userName = await _promptUserName();
          userRef.set({'name': userName}); // ユーザー名をデータベースに保存
          _userName = userName;
        } else {
          Map<String, dynamic> userData =
              Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          _userName = userData['name']; // 既存のユーザー名を取得
        }
        final snackBar = SnackBar(content: Text('ログインしました'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      setState(() {}); // ステートを更新してUIを再描画
    } catch (e) {
      final snackBar = SnackBar(content: Text('Login failed: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  // ログアウトメソッド
  Future<void> _logout() async {
    await _auth.signOut(); // Firebaseからサインアウト
    await GoogleSignIn().signOut(); // Googleからもサインアウト
    final snackBar = SnackBar(content: Text('ログアウトしました'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    setState(() {
      _user = null; // ステートをリセット
      _userName = null; // ユーザー名もリセット
    });
  }

  // ユーザー名を入力させるダイアログメソッド
  Future<String> _promptUserName() async {
    String userName = ""; // ユーザー名を格納する変数
    bool isValid = false; // 入力の検証フラグ

    while (!isValid) {
      // 有効なユーザー名が入力されるまでループ
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter your username'),
            content: TextField(
              onChanged: (value) {
                userName = value; // ユーザー名が変更されたときの処理
              },
              decoration:
                  InputDecoration(hintText: "Username"), // ユーザー名のヒントテキスト
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (userName.isNotEmpty) {
                    // ユーザー名が空でないことを検証
                    isValid = true; // 入力が有効な場合、フラグを更新
                    Navigator.pop(context); // ダイアログを閉じる
                  } else {
                    // ユーザー名が空の場合、エラーメッセージを表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid username')),
                    );
                  }
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
    return userName; // 有効なユーザー名を返す
  }

  // データベースからユーザー名を取得するメソッド
  Future<void> _fetchUserName() async {
    final userRef = _databaseRef.child(_user!.uid); // ユーザーの参照を取得
    final snapshot = await userRef.once(); // データベースからデータを取得
    if (snapshot.snapshot.exists) {
      setState(() {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        _userName = userData['name']; // ユーザー名を取得してステートを更新
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(_user != null
              ? (_userName ?? "User")
              : "Guest"), // ログイン状況に応じたタイトル表示
        ),
        actions: [
          IconButton(
            icon: Icon(
                _user != null ? Icons.logout : Icons.login), // ログイン状況に応じたアイコン表示
            onPressed:
                _user != null ? _logout : _login, // ボタン押下時にログインまたはログアウトを実行
          ),
        ],
      ),
    );
  }
}
