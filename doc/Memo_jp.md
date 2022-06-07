# Cluster Set 実現に向けて

## Cluster Set とは？
- Windows Server 2019 から導入された機能。概要は以下を参照。
  - https://docs.microsoft.com/ja-jp/azure-stack/hci/deploy/cluster-set

- 福永の認識は以下。
  - Worker
    - 従来の Windows Server Failover Cluster (WSFC).
  - Master
    - これが新規の個所？各 WSFC で管理されている仮想マシンでクラスタを構築しており、この中のリーダーノードが Worker の制御をしている？
    - Kubernetes の Master と同じく、Master がクライアントのエンドポイントになる？
      - Referral (照会、委託) SoFS とあるのはそういうことか？

## Cluster Set を実現する意義
- 公式ページのメリットは以下。
  - https://docs.microsoft.com/ja-jp/azure-stack/hci/deploy/cluster-set#benefits

- ざっくり、以下の2つがメリット。
  1. 業務無停止でのスケールアウトが可能。
  2. 負荷分散が可能。

## Cluster Set を実現するためのには
- 最終目標
  - WSFC なしで ECX のみで Cluster Set と同等の機能を実現 (WSFC にとって優位かどうかは一旦横に置く)

### 制限事項
- Live Migration は対象外とする。
- データのレプリケーション方法は一旦横に置いておく。
  - まずは、ノード管理の方法に注力する。

### 構成案
- Microsoft の Cluster Set の図を見ると、Master は各 WSFC 上の VM にあることになっているが、簡単のため、Master と Worker を分けてみるのはどうだろう？
- VM として分かれていれば良しとし、VM の場所は同一物理マシンでも OK 。
- Witness Server も必須とする。
  - Witness Server にはサーバのステータスが含まれるためこの情報を利用できないか？
  - Witness Server に問い合わせて、起動しているサーバに RESTful API で状態を取得？
- 簡単のため、以下の図では Master, Worker ともに 2-node 構成とする。
- AD, DNS, クライアントは省略。全て同一ドメインに入れることを一旦考える。
- クライアントから Worker サーバへのアクセスは、DNS による名前解決を用いる。
```
                          +----------------+
                          | Master Cluster |
+---------+               | +---------+    |
| Witness |----------+-+----| Master1 |    |
+---------+          | |  | +---+-----+    |
                     | |  |     |          |
                     | |  | +---+-----+    |
                     | +----| Master2 |    |
                     |    | +---------+    |
                     |    +----------------+
                     |
                     |    +-----------------+
                     |    | Worker Cluster1 |
                     |    | +-----------+   |
                     +------| Worker1-1 |   |
                     |    | +---+-------+   |
                     |    |     |           |
                     |    | +-----------+   |
                     +------| Worker1-2 |   |
                     |    | +---+-------+   |
                     |    +-----------------+
                     |
                     |    +-----------------+
                     |    | Worker Cluster2 |
                     |    | +-----------+   |
                     +------| Worker2-1 |   |
                     |    | +---+-------+   |
                     |    |     |           |
                     |    | +-----------+   |
                     +------| Worker2-2 |   |
                          | +---+-------+   |
                          +-----------------+

```

### Master
- ~~ECX でクラスタを構築。~~ まずはシングルノードでの構築もありか？
- Worker のステータスを逐次確認する。
  - RESTful API などを活用。
- Referral SoFS
  - ECX の DDNS で一旦代替する。

### Worker
- ECX でクラスタを構築。
- RESTful API を有効化しておく。

## Milestone
### 1st step: Master から Worker を制御することを目的とする
- クラスタの状態取得、操作をできるようにする。
- クライアントからの接続可否を確認。

### 2nd step: Worker 間のデータの引き継ぎ
- ミラーディスクリソースやハイブリッドディスクリソースは使えないため、他の手段でデータを引き継ぐ方法の検討が必要となる。
- VM をフェイルオーバ対象とするのであれば、VM のバックアップリストアを活用できる？？？

### 3rd step: Master のクラスタ化
- Master が実行すべき Cluster Set を制御するスクリプト (もしくはプログラム) をどう冗長化するか。Split-Brain 対策をどうするか？