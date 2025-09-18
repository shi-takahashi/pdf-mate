# PDF Mate（MVP）

## 概要
Flutter（Dart）でiOS/Android向けのシンプルなPDFツールを開発します。最大100時間でMVPリリースを目標に、以下の機能を実装します。

### MVP機能
- **PDF結合**：複数PDFを選択して1つにまとめる
- **PDF分割**：ページ範囲を抽出して新しいPDFを作成
- **PDF圧縮**：画像圧縮を中心にファイルサイズを軽量化
- **保存・共有**：ローカル保存と共有（メール・LINE等）

---

## 使用パッケージ（候補）
> 導入前に最新のライセンス・メンテ状況を確認してください。

- [`file_picker`](https://pub.dev/packages/file_picker)：ファイル選択
- [`path_provider`](https://pub.dev/packages/path_provider)：ローカルパス取得・保存
- [`permission_handler`](https://pub.dev/packages/permission_handler)：ストレージ権限
- [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress)：画像圧縮
- [`printing`](https://pub.dev/packages/printing)：PDFプリント・プレビュー
- [`pdf`](https://pub.dev/packages/pdf)：PDF生成
- [`syncfusion_flutter_pdf`](https://pub.dev/packages/syncfusion_flutter_pdf)（選択肢）：PDF結合・分割が簡単
- [`share_plus`](https://pub.dev/packages/share_plus)：共有
- [`pdfx`](https://pub.dev/packages/pdfx)：PDFプレビュー

---

## アーキテクチャ
- **状態管理**：`provider` または `riverpod`
- **構成**：
  - UI（Widgets）
  - ViewModel（状態管理）
  - Services：
    - FileService（読み書き）
    - PdfService（結合／分割／圧縮処理）

ファイルの流れ：
1. ファイル選択（file_picker）
2. PdfServiceで処理（結合・分割・圧縮）
3. 保存（path_provider）
4. プレビュー（pdfx等）
5. 共有（share_plus）

---

## 画面構成
1. 起動画面（ロゴ/説明）
2. ホーム（操作選択：結合 / 分割 / 圧縮）
3. ファイル選択画面（複数選択）
4. 結合プレビュー（順序変更、結合実行）
5. 分割設定画面（ページ範囲指定）
6. 圧縮設定画面（品質スライダ）
7. 保存完了画面（保存先と共有ボタン）

---

## 開発ステップ（時間見積もり）
**合計目安：100時間（週10時間ペース）**

1. プロジェクト作成・基本画面構成 — 8h
2. ファイル選択・保存基盤実装 — 12h
3. 結合機能 — 20h
4. 分割機能 — 16h
5. 圧縮機能 — 18h
6. 保存・共有処理 — 8h
7. テスト・デバッグ・調整 — 12h

---

## 優先順位（MVP割り切り）
- 結合 → 分割 → 圧縮
- 圧縮は簡易版（画像圧縮中心）で開始
- プレビューは最小限に留める

---

## 技術的注意点
- **ライブラリ依存**：Syncfusion等の商用ライブラリ利用はライセンス要確認
- **iOS制約**：ファイルアクセスはサンドボックス内に限定される
- **パフォーマンス**：大きなPDFはメモリ消費が大きいため、進捗表示や分割処理が必要
- **テスト**：多様なPDFで検証（画像中心・テキスト中心・混在など）

---

## サンプルコード
```dart
final result = await FilePicker.platform.pickFiles(
  allowMultiple: true,
  type: FileType.custom,
  allowedExtensions: ['pdf'],
);
if (result == null) return; // ユーザキャンセル
final files = result.paths.map((p) => File(p!)).toList();

final dir = await getApplicationDocumentsDirectory();
final outPath = path.join(dir.path, 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf');
// PdfServiceで結合処理を実行予定
```

---

## 次のアクション
1. プロジェクト雛形を作成
2. 結合機能のサンプル実装
3. パッケージ選定とライセンス確認

---

## ライセンス
このプロジェクトのコードはMITライセンスを想定。ただし使用する外部パッケージのライセンスは別途遵守してください。

