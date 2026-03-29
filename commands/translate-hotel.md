# /translate-hotel — 宿泊業特化の多言語翻訳

宿泊施設の案内文・ハウスルール・設備説明を、文化的ニュアンスを含めて多言語に翻訳します。一般的な翻訳ツールでは対応できない「宿泊業の文脈」に最適化。

## 使い方

```
/translate-hotel [翻訳したいテキスト]
```

または

```
/translate-hotel
（Claude が内容を聞いてきます）
```

## 動作

### Step 1: テキストの種類を判定
- ハウスルール
- チェックイン/アウト案内
- 設備の使い方説明
- 緊急時案内（避難経路、連絡先）
- 地域ガイド（レストラン、観光地）
- ゲストへのメッセージ

### Step 2: 5 言語に翻訳
1. **日本語**（原文 or 生成）
2. **英語**（欧米ゲスト向け）
3. **中国語 簡体字**（中国本土ゲスト向け）
4. **韓国語**（韓国ゲスト向け）
5. **中国語 繁体字**（台湾・香港ゲスト向け）

### Step 3: 文化的ニュアンスを付加

日本の宿泊マナーは外国人にとって分かりにくい。翻訳だけでなく「なぜそうするのか」の説明を付加:

| 日本語 | 文化説明（英語の場合） |
|--------|---------------------|
| 「靴を脱いでください」 | In Japan, shoes are removed before entering the living space to keep it clean. Please leave your shoes at the entrance. |
| 「ゴミの分別にご協力ください」 | Japan has detailed waste sorting rules. We've placed labeled bins to make it easy — thank you for helping! |
| 「22 時以降はお静かに」 | Our neighbors are local residents. Please keep noise to a minimum after 10 PM. |
| 「布団の敷き方」 | Japanese futon beds are laid directly on tatami mats. Here's how to set up your bedding: ... |

### Step 4: 出力

```
=== 日本語（原文）===
（テキスト）

=== English ===
（翻訳 + 文化説明）

=== 简体中文 ===
（翻訳 + 文化説明）

=== 한국어 ===
（翻訳 + 文化説明）

=== 繁體中文 ===
（翻訳 + 文化説明）
```

## 印刷用フォーマット

`/translate-hotel --print` で以下のフォーマットも生成:

- **A4 サイズ**: 館内掲示用（5 言語並列）
- **ポストカードサイズ**: テーブルに置く案内カード
- **LINE サイズ**: メッセージで送れる短縮版

## よく翻訳するもの

### ハウスルール
- 靴を脱ぐ、ゴミ分別、夜間の音、喫煙ルール、ペット、駐車場

### 設備説明
- WiFi 接続方法、エアコン操作、洗濯機の使い方、IH コンロ、お風呂

### 緊急時
- 地震発生時の行動、避難経路、緊急連絡先、最寄りの病院

### 地域ガイド
- 近隣レストラン、コンビニ、ATM、観光スポット、交通機関

## 注意
- 機械翻訳ではなく、宿泊業の文脈に合わせた自然な翻訳を行います
- 専門用語（「露天風呂」「囲炉裏」等）はローマ字 + 説明を併記
- 法的文書（約款等）の翻訳は、専門家の確認を推奨します
