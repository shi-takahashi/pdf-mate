# PDF Mate - 開発履歴

## プロジェクト概要
FlutterアプリでPDFファイルの結合・分割機能を提供するアプリケーション

## 2025-01-20 の進捗

### 実装した機能
1. **PDFファイル選択の改善**
   - Androidでファイルピッカー表示の問題を解決
   - `FileType.custom`から`FileType.any`に変更してPDFファイルが表示されるように修正
   - 初回のみヒント表示機能を追加（SharedPreferencesで管理）

2. **ネイティブPDF結合機能の実装**
   - Method Channelを使用してAndroid側でネイティブPDF結合を実装
   - iText7ライブラリを使用して各PDFのページサイズを完全に保持
   - Syncfusionライブラリでは異なるページサイズの結合時に右側が切れる問題を解決

### 技術的な改善
1. **ファイル選択UI**
   - 初回のみヒント表示（`pdf_picker_hint_shown`フラグで管理）
   - 分かりやすいファイル選択手順の説明を追加

2. **PDF結合の品質向上**
   - **Flutter側**: Method Channelでネイティブ実装を呼び出し、失敗時はSyncfusionにフォールバック
   - **Android側**: iText7ライブラリで完全なページサイズ保持を実現
   - FileProvider設定でセキュアなファイル共有を実装

### 追加した依存関係
```yaml
# pubspec.yaml
shared_preferences: ^2.2.2
```

```gradle
// android/app/build.gradle
dependencies {
    implementation 'com.itextpdf:itext7-core:7.2.5'
}
```

### ファイル構成
- `lib/viewmodels/pdf_viewmodel.dart`: Method Channel実装とフォールバック機能
- `android/app/src/main/kotlin/.../MainActivity.kt`: iText7を使用したネイティブPDF結合
- `android/app/src/main/res/xml/file_paths.xml`: FileProvider設定
- `lib/screens/pdf_merge_screen.dart`: ヒント表示機能

### 解決した問題
1. ✅ Androidでファイルピッカーにファイルが表示されない問題
2. ✅ 異なるページサイズのPDF結合時に右側が切れる問題
3. ✅ 毎回ヒントが表示される問題
4. ✅ ストレージ権限の複雑な設定問題（結果的にFilePickerの使用で解決）

## 2025-01-21 の進捗

### 実装した機能
1. **PDF分割機能の実装**
   - ページ数ごとの分割機能
   - ページ範囲指定での抽出機能
   - 分割モード選択UI（ラジオボタン）
   - スライダーによる直感的なページ指定

2. **PDF分割画面のUI**
   - ファイル選択セクション
   - 分割方法選択セクション（ページ数分割/範囲抽出）
   - PDFの総ページ数表示
   - 分割実行ボタン

3. **ViewModelの機能拡張**
   - `getPdfPageCount`: PDFのページ数取得
   - `splitPdfByPages`: ページ数ごとに分割
   - `splitPdfByRange`: ページ範囲で抽出
   - 分割後の自動シェア機能

### 技術的な実装
1. **ファイル名の管理**
   - タイムスタンプを使用した一意のファイル名生成
   - 元のファイル名を保持した分かりやすい命名規則

2. **UI/UXの改善**
   - スライダーによる直感的なページ指定
   - リアルタイムでの値表示
   - 選択したPDFの情報表示

### ファイル構成
- `lib/screens/pdf_split_screen.dart`: PDF分割画面の実装
- `lib/viewmodels/pdf_viewmodel.dart`: 分割ロジックの追加
- `lib/screens/home_screen.dart`: ナビゲーション追加

### 完了したタスク
1. ✅ PDF分割画面のUI作成
2. ✅ PDF分割ロジックの実装
3. ✅ 分割オプション（ページ範囲、分割数）の実装
4. ✅ 分割後のファイル保存機能
5. ✅ ナビゲーションへの追加
6. ✅ UI/UX統一化（保存オプション、完了ダイアログ）
7. ✅ ページサイズ保持問題の解決
8. ✅ エラーハンドリングの改善

### PDF分割機能のページサイズ問題の修正
1. **問題の発見**
   - 分割されたPDFファイルで右側が切れる問題
   - 結合と同様にSyncfusionの`drawPdfTemplate`がページサイズを正しく保持しない

2. **Androidネイティブ実装の追加**
   - iText7を使用したネイティブPDF分割機能を実装
   - `splitPdfByPagesNative`: ページ数ごとに分割（完全なページサイズ保持）
   - `splitPdfByRangeNative`: ページ範囲で抽出（完全なページサイズ保持）
   - `copyAsFormXObject`でページ内容を完璧にコピー

3. **Flutter側の改善**
   - Method Channelでネイティブ実装を優先的に使用
   - フォールバックとしてSyncfusionでの処理も保持
   - `drawPdfTemplate`に第3引数`pageSize`を追加（効果は限定的）

### 実装されたMethod Channel
```kotlin
// MainActivity.kt
"splitPdfByPages" -> ページ数ごとのPDF分割
"splitPdfByRange" -> ページ範囲での抽出
```

### UI/UX統一化の実装
1. **保存オプションダイアログの統一**
   - PDF結合と同じ3つのオプション：キャンセル、保存のみ、保存してシェア
   - 分割処理前にユーザーの選択を確認

2. **完了時のポップアップ統一**
   - 結合画面と同じスタイルの成功ダイアログ
   - ファイル数表示、保存場所説明、「今すぐシェア」ボタン

3. **エラーハンドリングの改善**
   - Sliderの`divisions`パラメータエラー修正
   - 1ページPDFの適切な処理（分割不可メッセージ表示）
   - エラーダイアログの統一

## 2025-01-22 の進捗

### PDF圧縮機能の実装
1. **機能概要**
   - 3段階の圧縮レベル（軽圧縮・標準圧縮・高圧縮）
   - 元ファイルサイズと圧縮後のサイズ比較表示
   - 削減率の計算と表示

2. **技術的実装**
   - **Syncfusion Flutter PDF**: 基本圧縮とクロスリファレンス最適化
   - **Android iText7**: より高度な圧縮レベル設定
   - Method Channelでネイティブ実装を優先、フォールバック機能付き

3. **UI/UX設計**
   - 結合・分割機能と統一されたデザイン
   - 圧縮レベル選択（ラジオボタン）
   - 保存オプションダイアログ（キャンセル・保存のみ・保存してシェア）
   - 圧縮結果の詳細表示（元サイズ・圧縮後・削減率）

### 圧縮技術の詳細
```dart
// Syncfusion実装
document.compressionLevel = PdfCompressionLevel.best;
document.fileStructure.incrementalUpdate = false;
document.fileStructure.crossReferenceType = PdfCrossReferenceType.crossReferenceStream;
```

```kotlin
// Android iText7実装
writer.setCompressionLevel(9) // 1-9の段階的圧縮
```

### ファイル構成
- `lib/screens/pdf_compress_screen.dart`: PDF圧縮画面の実装
- `lib/viewmodels/pdf_viewmodel.dart`: 圧縮ロジックの追加
- `android/app/src/main/kotlin/.../MainActivity.kt`: ネイティブ圧縮実装

### 完了したタスク
1. ✅ PDF圧縮画面のUI作成
2. ✅ 圧縮レベル選択機能の実装
3. ✅ ViewModelに圧縮ロジック実装
4. ✅ Android側ネイティブ圧縮機能
5. ✅ ホーム画面への機能追加

## 今後の予定
- PDFページの並び替え機能
- PDFへの透かし追加機能
- プレビュー機能の追加
- iOSでのページサイズ保持方法の実装

## 開発時の注意事項
- Syncfusion_flutter_pdfは異なるページサイズの処理に制限あり
- AndroidではiText7を使用することで完全な品質を保持（結合・分割共に）
- Method Channelのフォールバック機能により安定性を確保
- iOS版では現在Syncfusionのみの実装（ページサイズ問題あり）