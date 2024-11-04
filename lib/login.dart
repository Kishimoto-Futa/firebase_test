import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Firebase Authenticationインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    String username = _userController.text;
    String password = _passwordController.text;
    List<String> errMsgList = await check(username, password);

    if (errMsgList.isEmpty) {
      loginAccount(username, password);
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

  // ログイン
  Future<void> loginAccount(username, password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: '$username@user.com', password: password);

      // メイン画面にtrueを送信
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String errMsg = '';
      switch (e.code) {
        case 'invalid-credential':
          errMsg = 'ユーザー名またはパスワードが間違っています';
          break;
        case 'user-not-found':
          errMsg = 'ユーザーが見つかりませんでした';
          break;
        case 'wrong-password':
          errMsg = 'パスワードが間違っています';
          break;
        case 'invalid-email':
          errMsg = 'メールアドレスの形式が不正です';
          break;
        case 'user-disabled':
          errMsg = 'このユーザーアカウントは無効化されています';
          break;
        case 'operation-not-allowed':
          errMsg = 'この認証方法は無効になっています';
          break;
        default:
          errMsg = e.message as String;
      }
      showSnackBar(errMsg);
    } catch (e) {
      showSnackBar('予期しないエラーが発生しました: $e');
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
        title: Text('ログイン'),
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
              onPressed: _login,
              child: Text('ログイン'),
            ),
          ],
        ),
      ),
    );
  }
}
