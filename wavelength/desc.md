# 開発メモ


## ゲームルール
https://boku-boardgame.net/wavelength

- 少人数（3~5人）で遊べるように、↑の①~⑤, ⑦をプレイ
  - 親が単語を言い、他のプレイヤーが数値を予測するまで

1. プレイヤーの中から「親」を決定
2. 「親」に得点の目盛り（ターゲット）を公開
3. 他のプレイヤーで相談しながら、目盛り（赤い針）を調整
4. ターゲットを公開し、得点計算
5. 楽しいね

## 画面遷移

```mermaid
sequenceDiagram
  participant 0 as ログイン
  participant 1 as 待機部屋
  participant 2 as ゲーム画面
  0 ->> 1: 入室
  1 ->>+ 2: 揃ったらゲーム開始
  Note over 2: 楽しいね
  2 ->>- 1: ゲーム終了
  1 ->> 0: ログアウト
```

## ファイル構造
+ /wavelength
  + /core
    + .core.nim --> front/backで共通の単位をenum/objectとして共有
      + ApiSend: enum
      + ApiReceive: enum
      + UserStatus: enum 
      + Room: enum
      + User: ref object
      + Range: ref object
      + Dial: range[1..100]
  + /front --> 適当な単位でxxutils.nimに切り分け
    + .canvasutils.nim --> 描画（切り分け例
    + .front.nim --> 画面遷移/通信/演出
  + /back --> 適当な単位でxxutils.nimに切り分け
    + .back.nim --> webページ/流れ管理/通信
+ .main.nim --> nimgameのrouting


