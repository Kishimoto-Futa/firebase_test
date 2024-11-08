import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Firebase Authenticationインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firestoreのusersリファレンス
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registration() async {
    String username = _userController.text;
    String password = _passwordController.text;
    List<String> errMsgList = await check(username, password);

    if (errMsgList.isEmpty) {
      registrationAccount(username, password);
    } else {
      showSnackBar(errMsgList.join('\n'));
    }
  }

  // 入力チェック
  Future<List<String>> check(String username, String password) async {
    List<String> errMsgList = [];
    // ユーザー名
    if (username.isEmpty) {
      errMsgList.add('ユーザー名を入力してください');
    }
    // パスワード
    if (password.isEmpty) {
      errMsgList.add('パスワードを入力してください');
    } else if (password.length < 8) {
      errMsgList.add('パスワードは8文字以上で入力してください');
    }
    return errMsgList;
  }

  // 登録
  Future<void> registrationAccount(username, password) async {
    try {
      // Firebase Authで新規ユーザー作成
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
              email: '$username@user.com', password: password);

      // ユーザー名変更
      await userCredential.user?.updateDisplayName(username);

      // Firestoreにユーザー登録
      await _usersRef
          .doc(userCredential.user?.uid)
          .set({'icon': '', 'username': username});

      // メイン画面にtrueを送信
      Navigator.pop(context, true);
    } catch (e) {
      String errMsg = e.toString();
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errMsg = 'このユーザー名は既に使用されています';
        } else {
          errMsg = e.message as String;
        }
      } else if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          errMsg = 'データベースに書き込む権限がありません';
        } else if (e.code == 'network-request-failed') {
          errMsg = 'ネットワークに接続されていません';
        } else {
          errMsg = e.message as String;
        }
      }
      showSnackBar(errMsg);
    }
  }

  // スナックバー表示
  void showSnackBar(msg) {
    SnackBar snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登録'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: 'ユーザー名'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registration,
              child: Text('登録'),
            ),
          ],
        ),
      ),
    );
  }
}
