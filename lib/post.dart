import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final GlobalKey _headkey = GlobalKey();
  final GlobalKey _buttonKey = GlobalKey();
  double _headHeight = 0.0;
  double _buttonHeight = 0.0;
  // Firebase Authenticationインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firebase Storageのインスタンス
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Firebase Firestoreのpostsリファレンス
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');
  // ImagePicker
  final ImagePicker _picker = ImagePicker();
  // 選択された画像
  File? _selectedImage;
  // ダウンロードURL
  String _downloadUrl = '';
  // 一言コメントの入力欄
  final TextEditingController _commentController = TextEditingController();

  // 画像を選択するメソッド
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      File compressedImage = await compressImage(imageFile);
      setState(() {
        _selectedImage = compressedImage;
      });
    }
  }

  // 画像を90%圧縮するメソッド
  Future<File> compressImage(File imageFile) async {
    // 画像ファイルを非同期で読み込み
    img.Image image =
        img.decodeImage(await imageFile.readAsBytes()) as img.Image;

    // 画像を圧縮
    List<int> compressedImageBytes = img.encodeJpg(image, quality: 10);

    // 圧縮した画像を新しいファイルに保存
    String path =
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}';
    File compressedFile = File(path)..writeAsBytesSync(compressedImageBytes);

    return compressedFile;
  }

  // 画像の設定を取り消すメソッド
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // 投稿メソッド
  Future<void> _post() async {
    if (_selectedImage != null) {
      bool isUploaded = false;
      bool isSaved = false;

      // 画像のアップロード
      isUploaded = await uploadFire(_selectedImage as File);

      // Firestoreに保存
      if (isUploaded) {
        isSaved = await save();
      }

      // メイン画面にtrueを送信
      if (isSaved) {
        Navigator.pop(context, true);
      }
    } else {
      showSnackBar('画像が選択されていません');
    }
  }

  // Firebase Storageにアップロードするメソッド
  Future<bool> uploadFire(File file) async {
    bool isUploaded = false;
    try {
      // ファイル名
      String filename = Timestamp.now().millisecondsSinceEpoch.toString();

      // postsのリファレンス取得
      Reference postRef = _storage.ref('posts/$filename');

      // ファイルをアップロード
      UploadTask uploadTask = postRef.putFile(file);

      // アップロードが終わるまで待機
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      // ダウンロードURLを取得
      _downloadUrl = await snapshot.ref.getDownloadURL();

      isUploaded = true;
    } catch (e) {
      // エラー処理
      String errMsg = e.toString();
      if (e is FirebaseException) {
        if (e.code == 'storage/unauthorized') {
          errMsg = 'アップロードする権限がありません';
        } else if (e.code == 'storage/invalid-argument') {
          errMsg = '無効なファイルです';
        } else if (e.code == 'storage/invalid-argumen') {
          errMsg = 'リクエストが多すぎます';
        } else if (e.code == 'storage/canceled') {
          errMsg = 'アップロードがキャンセルされました';
        } else if (e.code == 'storage/unknown') {
          errMsg = '不明なエラーです';
        }
      }
      showSnackBar(errMsg);
    }

    return isUploaded;
  }

  // Firebase Storageのファイルを削除するメソッド
  Future<void> deleteFile(String downloadUrl) async {
    try {
      // ファイルのリファレンス取得
      Reference fileRef = _storage.refFromURL(downloadUrl);

      // ファイル削除
      await fileRef.delete();
    } catch (e) {
      showSnackBar('ファイルの削除中にエラーが発生しました');
    }
  }

  // Firebase Firestoreに投稿情報を保存するメソッド
  Future<bool> save() async {
    bool isSaved = false;
    String username = _auth.currentUser!.displayName as String;
    String comment = _commentController.text;
    Timestamp timestamp = Timestamp.now();

    try {
      await _postsRef.doc().set({
        'username': username,
        'imageUrl': _downloadUrl,
        'comment': comment,
        'timestamp': timestamp
      });

      isSaved = true;
    } catch (e) {
      String errMsg = e.toString();
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          errMsg = 'データベースに書き込む権限がありません';
        } else if (e.code == 'network-request-failed') {
          errMsg = 'ネットワークに接続されていません';
        } else {
          errMsg = e.message as String;
        }
      }
      showSnackBar(errMsg);

      // ファイル削除
      if (_downloadUrl.isNotEmpty) {
        deleteFile(_downloadUrl);
      }
    }

    return isSaved;
  }

  // スナックバー表示
  void showSnackBar(msg) {
    SnackBar snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox headBox =
          _headkey.currentContext!.findRenderObject() as RenderBox;
      final RenderBox buttonBox =
          _buttonKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _headHeight = headBox.size.height;
        _buttonHeight = buttonBox.size.height;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final imageMaxHeight =
        (screenHeight - appBarHeight - _headHeight - _buttonHeight - 32.0) *
            0.9;
    return Scaffold(
      appBar: AppBar(
        title: Text('ポスト'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _post,
            tooltip: '投稿',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 一言コメント入力欄
            TextField(
              key: _headkey,
              controller: _commentController,
              decoration: InputDecoration(
                labelText: '一言コメント',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // 画像のプレビューまたは画像選択ボタン
            _selectedImage == null
                ? ElevatedButton(
                    key: _buttonKey,
                    onPressed: _pickImage,
                    child: Text('画像を選択'),
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _removeImage,
                        child: Text('選択を取り消す'),
                      ),
                      SizedBox(height: 16.0),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                          maxHeight: imageMaxHeight,
                        ),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
