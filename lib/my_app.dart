import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_test/post.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Firebase Firestoreのpostリファレンス
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');
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

  // 投稿メソッド
  Future<void> _post() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostScreen()),
    );

    if (result != null && result) {
      showSnackBar('投稿しました');
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

  // Post表示
  Widget _buildPostItem(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // username
            Text(
              data['username'] ?? 'unknown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),

            // text
            Text(
              data['comment'],
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(
              height: 8.0,
            ),

            // image
            GestureDetector(
              onTap: () {
                _showImageModal(context, data['imageUrl']);
              },
              child: Image.network(
                data['imageUrl'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text('画像が存在しません'),
              ),
            ),
            SizedBox(
              height: 8.0,
            ),

            // timestamp
            Text(
              data['timestamp'].toDate().toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.height * 0.8, // 画面の80%の高さ
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity, // ボタンの横幅を最大にする
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // モーダルを閉じる
                  },
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0), // ボタンの縦の余白を追加
                    backgroundColor: Colors.grey[200], // ボタンの背景色を設定
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user != null ? _username as String : 'Guest'),
        backgroundColor: Colors.blue,
        actions: showIcons(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _postsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // 取得中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // データが存在しない
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("投稿がありません"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              return _buildPostItem(data);
            }).toList(),
          );
        },
      ),
      floatingActionButton: Visibility(
        visible: _user != null,
        child: FloatingActionButton(
          onPressed: _post,
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}
