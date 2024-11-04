# Firebase Authのテスト
Discordに添付したファイルを以下のフォルダに配置してください。  
- firebase_options.dart→firebase_test/lib
- google-services.json→firebase_test/android/app(Androidのみ)
- GoogleService-Info.plist→firebase_test/ios/Runner(iosのみ)  
---
以下のコマンドを実行してください。
```bash
flutter pub get
```
---
ログイン情報
- ユーザー名（重複×）
- パスワード（8文字以上）