# リファクタリング・チャレンジ （リバーシ編） iOS版

> 本チャレンジは、 _Fat View Controller_ として実装された[リバーシ](https://en.wikipedia.org/wiki/Reversi)アプリをリファクタリングし、どれだけクリーンな設計とコードを実現できるかというコンペティションです（ジャッジが優劣を判定するわけではなく、設計の技を競い合うのが目的です）。
>
> ![アプリのスクリーンショット](img/screenshot.png)
>
> [reversi-ios/README.md](https://github.com/refactoring-challenge/reversi-ios)


# リファクタリングの方針

このリポジトリはフルスクラッチで理想的な設計を目指しました。なお、作業者は以下のシチュエーションを想像しながら進めました：

* このアプリがクラッシュしたら人が死ぬ
* クラッシュじゃないバグでも大変なことになってしまう

一般的には、多少バグがあっても魅力的な機能のリリースを優先することもあります。しかしこのリポジトリでは多少のバグも許されないので、あの手この手でバグを防がねばなりません（ということになっています）。この結果は末尾の「[リファクタリングの結果](#リファクタリングの結果)」に記載してあります。



## 前提

バグを減らすための唯一の方法は **とにかく可能な入力を試す** ことです。可能な入力を試す手段には色々なものがあります：

* 手動ポチポチ
* 従来の自動テスト（XCTest/Quickなど）
* 型以外の静的検査（SwiftLintなど）
* 型検査
* モデル検査や証明

このうち、このリポジトリで採用したのはほぼ型検査と自動テスト（と少しだけ手動ポチポチ）です。中でも特に静的型検査に力を入れました。

これは「とにかく可能な入力を試す」を達成する方法として静的検査の優れるからです。手動ポチポチや自動テストは、どこかにバグ（欠陥）があってもそれが実行されなければ発見できませんが、型検査はどこか1箇所にでも入力される値の想定ミスがあれば実行せずとも発見できます。
このように、静的型検査を含む静的検査には広範な入力を網羅的に検証できるという特徴を備えています。中でも静的型検査は数ある静的検査の中でも軽量で手軽な手段です（モデル検査や正当性証明は手軽ではない）。

そのため、作者は自動テスト書いたら負けぐらいの気持ちで型検査に力を入れました（この状況を正当化しうるのは、主にリファクタリングの方針で説明されたようなミッションクリティカルシステムのような限定的な場合のみです）。そしてあわよくばモデルけんさと正当性証明を狙いました。



## 型設計で考えるべきこと

安全性を重視した型設計をする上でもっとも重要な考え方は **とにかく異常な値が許されないようにする** ことです。もしある型が異常な値を許してしまうとプログラマはその型を信用できません。結果として、プログラムのいたるところに値が意図通りか確かめるコードを書くことになるでしょう（あるいは書き忘れてバグになるかもしれません）。さて、このとき意図通りの値ではないことがわかったとして、常に適切なエラー処理ができるでしょうか？おそらくとそうできないことも多いでしょう。特に絶対に失敗しないように思える場所でのエラー処理は雑になりがちで、これがバグの温床になることもあります。そのため、安全な型設計では異常な値を主に次の2つの手段で排除します：

1. 値空間を削る
2. 動的検査後にインスタンスが手に入る

1に出てきた値空間とはある型に対してその型に属する値すべての集合です。例えば `Int32` の値空間には32bitで表現できる整数すべてが入っています。そして値空間を削るとは、この値空間を縮めて異常な値が含まないように型を定義し直すことです。例えば `Int32` から負の数を含まないようにしたのが `UInt32` です（厳密には `Int32` で表現できない大きな整数が代わりに値空間に入ってしまいます）。

さて、1の例をリバーシにおける Line で見てみましょう。Line とは盤面上でひっくり返すときの線を表現しています。次の図は盤面の左上端を抜粋したものです。いま黒い石（`x`）を A1（一番左上の座標）に置けるのは、D1に自分と同じ色の石がありここから左方向へ A1 までの間に相手の白い石（`o`）が連続して配置されているからです：

```
   ABCD
  +----
1 | oox
2 |
  :
```

このとき、このひっくり返せる線である Line を表現する型の定義には選択肢がたくさんあります。例としてもっとも素直な表現である始点と終点のみを記録する `((Int, Int), (Int, Int))` を考えましょう。この型で前図の例の Line 値を表現すると `((0, 0), (3, 0))` になります。

ここで Line の値空間を考えてみると、以下の `exampleN` はすべて Line の値空間に収まります。

```swift
let example1 = ((0, 0), (3, 0))
let example2 = ((0, 0), (10, -1))
let example3 = ((0, 0), (1, 2))
let example4 = ((0, 0), (0, 0))
```

しかし、このうち2-4は異常な値です（2:盤面の範囲外、3:縦横斜めの線上にない、4:長さが0）。つまり、この Line の型では異常な値が数多く含まれてしまいます。

そこで、今回のリファクタリングではこれらの異常な値を許さない極めて厳密な型を用意しました：

```swift
public struct Line {
    public let start: Coordinate
    public let end: Coordinate
    public let directedDistance: DirectedDistance
}


public struct Coordinate {
    public let x: CoordinateX
    public let y: CoordinateY
}


public enum CoordinateX: Int, CaseIterable {
    case a = 1
    case b
    case c
    case d
    case e
    case f
    case g
    case h
}


public enum CoordinateY: Int, CaseIterable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
}


public struct DirectedDistance {
    public let direction: Direction
    public let distance: Distance
}


public enum Direction: CaseIterable {
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
    case topLeft
}


public enum Distance: Int, CaseIterable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
}
```

この型の座標は、整数の組の代わりに `CoordinateX` などの `enum` を用いているため盤面の外の座標の値は存在できません。ただし、これだけだとまだ `start` と `end` と `directedDistance` が不整合を起こす可能性があります。

そこで、2つめの方法である動的検査後にインスタンスを手に入れられるようにしてみましょう。次の `init` は整合性の動的検査に成功した場合のみ値を生成できるようになっています：


```swift
public struct Line {
    public let start: Coordinate
    public let end: Coordinate
    public let directedDistance: DirectedDistance


    public init?(start: Coordinate, directedDistance: DirectedDistance) {
        guard let end = start.moved(to: directedDistance) else {
            return nil
        }
        self.start = start
        self.end = end
        self.directedDistance = directedDistance
    }
}


public struct Coordinate {
    public let x: CoordinateX
    public let y: CoordinateY


    public func moved(to directedDistance: DirectedDistance) -> Coordinate? {
        // NOTE: Be nil if the X is out of boards.
        let unsafeX: CoordinateX?
        switch directedDistance.direction {
        case .top, .bottom:
            unsafeX = self.x
        case .left, .topLeft, .bottomLeft:
            unsafeX = CoordinateX(rawValue: self.x.rawValue - directedDistance.distance.rawValue)
        case .right, .topRight, .bottomRight:
            unsafeX = CoordinateX(rawValue: self.x.rawValue + directedDistance.distance.rawValue)
        }

        // NOTE: Be nil if the Y is out of boards.
        let unsafeY: CoordinateY?
        switch directedDistance.direction {
        case .left, .right:
            unsafeY = self.y
        case .top, .topLeft, .topRight:
            unsafeY = CoordinateY(rawValue: self.y.rawValue - directedDistance.distance.rawValue)
        case .bottom, .bottomLeft, .bottomRight:
            unsafeY = CoordinateY(rawValue: self.y.rawValue + directedDistance.distance.rawValue)
        }

        switch (unsafeX, unsafeY) {
        case (.none, _), (_, .none):
            return nil
        case (.some(let x), .some(let y)):
            return Coordinate(x: x, y: y)
        }
    }
}
```

2つめの方法は実際のiOSアプリでもバリデーションまわりに応用できます。次のコードは8文字以上のパスワードのみを許す Password 型を定義しています：

```swift
// NOTE: 実際の iOS アプリのバリデーションなどでよく使われる。
public struct Password {
    public init?(rawValue: String) {
        guard rawValue.count >= 8 else { return nil }
        self.rawValue = rawValue
    }
}
```

なお、1はより安全ですが自由度が低く、2は自由度が高いですが安全性の担保には動的テストを必要とするでしょう。

今回のリファクタリングでは以下がそれぞれの実例になっています：

1. 値空間を削る
    * [`Coordinate`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Coordinate.swift)
    * [`NonEmptyArray`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/NonEmptyArray.swift)
    * [`Board`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Board.swift)
    * [`GameResult`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameResult.swift)
2. 動的検査後にインスタンスが手に入る
    * [`Line`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Line.swift)
    * [`FlippableLine`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/FlippableLine.swift)



## アーキテクチャについて

このリポジトリは古典的な MVC（not Cocoa MVC）を iOS に書きやすく適応した亜種を採用しています。

まずは ViewController をご覧ください：

```swift
public class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var resetButton: UIButton!

    public private(set) var composer: BoardMVCComposer?
    private var modalPresenterQueue: ModalPresenterQueueProtocol?


    public override func viewDidLoad() {
        super.viewDidLoad()

        let modalPresenter = UIKitTestable.ModalPresenter(wherePresentOn: .weak(self))
        let modalPresenterQueue = ModalPresenterQueue()
        self.modalPresenterQueue = modalPresenterQueue

        let boardViewHandle = BoardViewHandle(boardView: self.boardView)

        self.composer = BoardMVCComposer(
            userDefaults: UserDefaults.standard,
            boardViewHandle: boardViewHandle,
            boardAnimationHandle: boardViewHandle,
            gameAutomatorProgressViewHandle: GameAutomatorProgressViewHandle(
                firstActivityIndicator: self.playerActivityIndicators[0],
                secondActivityIndicator: self.playerActivityIndicators[1]
            ),
            gameAutomatorControlHandle: GameAutomatorControlHandle(
                firstSegmentedControl: self.playerControls[0],
                secondSegmentedControl: self.playerControls[1]
            ),
            passConfirmationViewHandle: PassConfirmationHandle(
                willModalsPresentOn: modalPresenter,
                orEnqueueIfViewNotAppeared: modalPresenterQueue
            ),
            resetConfirmationViewHandle: ResetConfirmationHandle(
                button: self.resetButton,
                willModalsPresentOn: modalPresenter,
                orEnqueueIfViewNotAppeared: modalPresenterQueue
            ),
            diskCountViewHandle: DiskCountViewHandle(
                firstPlayerCountLabel: self.countLabels[0],
                secondPlayerCountLabel: self.countLabels[1]
            ),
            turnMessageViewHandle: TurnMessageViewHandle(
                messageLabel: self.messageLabel,
                messageDiskView: self.messageDiskView,
                messageDiskViewConstraint: self.messageDiskSizeConstraint
            )
        )
    }


    public override func viewDidAppear(_ animated: Bool) {
        self.modalPresenterQueue?.viewDidAppear()
    }


    public override func viewWillDisappear(_ animated: Bool) {
        self.modalPresenterQueue?.viewWillDisappear()
    }
}
```

やっていることは、`viewDidLoad` の後でしか手に入らない UIView を View Handle というもの（後述）に包んで `BoardMVCComposer` に渡しているだけです。あとはライフサイクルを必要なコンポーネントへ通知しているだけです。これによって、`UIViewController` は本来の責務であったライフサイクルイベントの管理だけに集中できるようになりました。

さて、中身の `BoardMVCComposer` は古典的な MVC パターンの Model と View（コード上の名前は View Binding） と Controller を接続する責務があります：

```swift
public class BoardMVCComposer {
    public let animatedGameWithAutomatorsModel: AnimatedGameWithAutomatorsModelProtocol

    // ...

    private let boardViewBinding: BoardViewBinding

    // ...

    private let boardController: BoardController

    // ...



    public init(
        userDefaults: UserDefaults,
        // ...
        isEventTracesEnabled: Bool = isDebug
    ) {
        // STEP-1: Constructing Models and Model Aggregates that are needed by the screen.
        //         And models should be shared across multiple screens will arrive as parameters.

        let animatedGameWithAutomatorsModel = AnimatedGameWithAutomatorsModel(/* ... */)
        self.animatedGameWithAutomatorsModel = animatedGameWithAutomatorsModel

        // ...


        // STEP-2: Constructing ViewBindings.
        self.boardViewBinding = BoardViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: boardViewHandle
        )

        // ...


        // STEP-3: Constructing Controllers.
        self.boardController = BoardController(
            observing: boardViewHandle,
            requestingTo: animatedGameWithAutomatorsModel
        )

        // ...
    }
```

この中では次の6種類のコンポーネントが登場します：

* MVC Model に相当するもの
    * Model: 変更を外へ通知する状態機械
        * [`GameModel`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/GameModel.swift)
        * [`BoardAnimationModel`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModel.swift)
        * [`UserDefaultsModel`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/UserDefaultsModel.swift)
        * [...](https://github.com/Kuniwak/reversi-ios/tree/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models)
    * Model Aggregates: Model を複数集めて Model 同士を接続したもの
        * [`AutoBackupGameModel`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AutoBackupGameModel.swift) = `GameModel` + `UserDefaultsModel`
        * [`AnimatedGameModel`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AnimatedGameModel.swift) = `GameModel` + `BoardAnimationModel`
        * [...](https://github.com/Kuniwak/reversi-ios/tree/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates)
* MVC View に相当するもの
    * Viewi Binding: Model の変更を View Handle へ伝達するもの（単方向データバインディング）
        * [`BoardViewBinding`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Views/ViewBindings/BoardViewBinding.swift)
        * [`DiskCountViewBinding`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Views/ViewBindings/DiskCountViewBinding.swift)
        * [...](https://github.com/Kuniwak/reversi-ios/tree/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Views/ViewBindings)
    * View Handle: UIView を内部にもち、View Binding から受け取った Model の状態を反映して UI イベントを外へ通知するもの
        * [`BoardViewHandle`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Views/ViewHandles/BoardViewHandle.swift)
        * [`ResetConfirmatioinHandle`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Views/ViewHandles/ResetConfirmationHandle.swift)
        * [...](https://github.com/Kuniwak/reversi-ios/tree/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Views/ViewHandles)
* MVC Controller に相当するもの
    * Controller: ViewHandle から UI イベントを受け取り Model へと転送するもの
        * [`BoardAnimationController`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Controllers/BoardAnimationController.swift)
        * [`ResetConfirmationController`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Controllers/ResetConfirmationController.swift)
        * [...](https://github.com/Kuniwak/reversi-ios/tree/00964987051e643141c2e9d85030073e2e424bd3/Reversi/MVCArchitecture/Controllers)

ここでは特に重要な Model と Model Aggregates について解説します。



### Model とは

このリポジトリにおける Model は状態機械として設計されています。この状態機械は外からの要求に応じて内部状態を変化させ、変化を外部へ通知するようになっています。

ここではリバーシのゲームの状態を管理する `GameModel` をみてみましょう。`GameModel` が内部にもつ状態は次の2つの状態のグループをもちます：

```swift
public enum GameModelState {
    // ゲームは進行中
    case ready(GameState, Set<AvailableCandidate>)

    // ゲームは決着した
    case completed(GameState, GameResult)
}
```

もし `GameModel` の公開しているメソッドである `pass()` `place(...)` `reset(...)` が呼ばれると、それが妥当な要求なら Model は内部状態を次のように変化させます：

```
  +-------+                        +-----------+
  | ready | ---- (pass/place) ---> | completed |
  +-------+                        +-----------+
      A                                  |
      |                                  |
      +----------- (reset) --------------+
```

```swift
public protocol GameCommandReceivable: class {
    @discardableResult
    func pass() -> GameCommandResult

    @discardableResult
    func place(at coordinate: Coordinate) -> GameCommandResult

    @discardableResult
    func reset() -> GameCommandResult
}
```

ここで妥当な要求か否かは Model が判断します。例えば、ルール上置けない場所への `place(...)` やゲームが決着したあとの `pass()` は妥当でないので、Model はこれを無視します。逆に、パスしかできない場面での `pass()` など妥当な要求を受け取ると内部状態が変化します。この内部状態の変化は `ReactiveSwift.Property` などのイベントストリームから観測できます：

```swift
public protocol GameModelProtocol: GameCommandReceivable {
    var gameModelStateDidChange: ReactiveSwift.Property<GameModelState> { get }
    var gameCommandDidAccepted: ReactiveSwift.Signal<GameState.AcceptedCommand, Never> { get }
}
```

そして、最終的にこの状態変化を監視している View Binding や Model Aggregate に通知が届き、表示や次の処理が開始されます。

次に Model Aggregate の解説です。



### Model Aggregate とは

Model Aggregate は複数の Model を意味のある単位で束ねたものです。Model は基本的にとても小さな状態機械として設計するので（理由は後述）、これらを適切に組み合わせてより大きな状態機械を構成するための手段です。

例えば、次の `AutoBackupGameModel` は、先ほどの `GameModel` と UserDefaults への書き込み状況をもつ `UserDefaultsModel` の2つを集約した Model Aggregate です。このクラスの責務は、ゲームの盤面を管理する `GameModel` の状態を `UserDefaultsModel` から読み込み、そして `GameModel` の変更を監視して `UserDefaults` へ書き込みを要求します：

```swift
public class AutoBackupGameModel: AutoStoredGameModelProtocol {
    private let userDefaultsModel: AnyUserDefaultsModel<GameState, UserDefaultsJSONReadWriterError>
    private let gameModel: GameModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()

    private static let key = UserDefaultsKey.gameStateKey


    public init(userDefaults: UserDefaults, defaultValue: GameState) {
        let userDefaultsModel = UserDefaultsModel<GameState, UserDefaultsJSONReaderError, UserDefaultsJSONWriterError>(
            userDefaults: userDefaults,
            reader: userDefaultsJSONReader(forKey: AutoBackupGameModel.key, defaultValue: defaultValue),
            writer: userDefaultsJSONWriter(forKey: AutoBackupGameModel.key)
        ).asAny()
        self.userDefaultsModel = userDefaultsModel

        let initialGameState: GameState
        switch userDefaultsModel.userDefaultsValue {
        case .failure:
            initialGameState = defaultValue
        case .success(let storedGameState):
            initialGameState = storedGameState
        }
        self.gameModel = GameModel(initialState: .next(by: initialGameState))

        self.start()
    }


    private func start() {
        self.gameModel.gameModelStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .utility))
            .on(value: { [weak self] gameModelState in
                self?.userDefaultsModel.store(value: gameModelState.gameState)
            })
            .start()
    }
}



extension AutoBackupGameModel: GameCommandReceivable {
    public func pass() -> GameCommandResult { self.gameModel.pass() }


    public func place(at coordinate: Coordinate) -> GameCommandResult { self.gameModel.place(at: coordinate) }


    public func reset() -> GameCommandResult { self.gameModel.reset() }
}



extension AutoBackupGameModel: GameModelProtocol {
    public var gameModelStateDidChange: Property<GameModelState> {
        self.gameModel.gameModelStateDidChange
    }

    public var gameCommandDidAccepted: Signal<GameState.AcceptedCommand, Never> {
        self.gameModel.gameCommandDidAccepted
    }
}
```

これによって、ゲームの盤面を管理するだけの小さな Model と UserDefaults を管理するだけの小さな Model から、より大きな自動バックアップ機能つきのモデルを構成できます。他にも、オートプレイはオートプレイのオンオフをもつ Model とゲームロジックだけの Model、コンピュータの思考状況の Model から構成されています。また、これらを組み合わせたあとでないと実装できないロジック（思考中のユーザー操作無視など）も集約の責務です。

なお、なぜ Model を小さく設計して Model Aggregates で合成していくのかというと、**このほうが自動テストをしやすいから** です。

具体的には、ゲームロジックとオートプレイだけの確認をしたい場合に、アニメーション機能が搭載されていてるとテストの邪魔になります（テストが長くなる/テストに余計なコードが増える/テストの実行時間が増えるなど）。回避方法の一案として最初にゲームロジックとオートプレイだけを実装してテストを書き、後からここに機能を追加していく方法もありえますがいい方法ではありません。これだとあとになってのリファクタリングのときには機能が増えてしまっているためリファクタリングのためのテストの邪魔になるからです。

そこで、小さな Model やその階層的な集約をつくれれば、必要な要素だけが揃った状況を狙ってテストできます（例: アニメーションを排除しつつオートプレイをテストする [`GameWithAutomatorsModelTests`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/GameWithAutomatorsModelTests.swift)）

補足すると、そもそも Model や Model Aggregate のテストは Rx などのイベントストリームが絡むので面倒になりがちという問題があり、もし Model から離れられるものは離した方が自動テストが楽になります（例: モデルから離れてゲームロジックだけをテストする [`GameStateTests`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameStateTests.swift) や [`BoardAnimationModelTests`](https://github.com/Kuniwak/reversi-ios/blob/00964987051e643141c2e9d85030073e2e424bd3/ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModelTests.swift)）。

これらをまとめると、動作確認のやりやすさためにより小さな Model/Model Aggregate が望ましく、もしそれで必要な仕様を満たせないならさらに Model Aggregate で集約していくという方針を取っているということです。しかしここには大きな落とし穴があります。

一般に、並行並列動作する状態機械の組み合わせの数は人間の想像を超えてきます。よく並行並列システム（特にマルチスレッドプログラミング）の開発が難しいと言われるのは、この膨大な数の組み合わせのなかのごくわずかな部分にデッドロックや無限ループなどの欠陥が潜んでいることに気づけないからです。そして、このような膨大の入力の組み合わせ数があるとき自動テストを含む動的検査は無力です。静的検査においてはモデル検査と呼ばれる技術がこの種の網羅的な検証を得意としています。なお今回はモデル検査を試みていますが、いくつかの事情によって断念することになりました（後述）。

さて、残りの View Binding/Handle についても軽く解説します。



### View Binding とは

View Binding とは、Model/Model Aggregate の変更をイベントストリーム経由で監視し、変化を View Handle へ反映する役割をもちます：

```swift
public class BoardViewBinding {
    private let boardAnimationModel: BoardAnimationModelProtocol
    private let viewHandle: BoardViewHandleProtocol

    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing boardAnimationModel: BoardAnimationModelProtocol,
        updating viewHandle: BoardViewHandleProtocol
    ) {
        self.boardAnimationModel = boardAnimationModel
        self.viewHandle = viewHandle

        boardAnimationModel
            .boardAnimationStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] state in
                self?.viewHandle.apply(by: state.animationRequest)
            })
            .start()
    }
}
```

View Binding はこの例のように1つの View Handle だけを持ちます。複数の View Handle を持ちたくなった場合は次のように View Binding の分割か View Handle の合成を検討するとよいでしょう：

* 順序不定で複数の View Handle へ反映したい → View Binding を分割する
* 決まった順序で View Handle へ反映したい → 複数の View Handle を 1 つの新しい View Handle に包んで順序を固定して呼び出す

次は View Handle の解説です。


### View Handle とは

View Handle は View Binding から受け取った変更指示を UIView へ伝え、かつ UIView からの UI イベントを外部へイベントストリームとして公開する役割をもちます。よくある開発では View Handle 相当のクラスを UIView の派生クラスにするようですが、このリポジトリでは特に派生クラスを強制していません。なぜなら UIView を外から受け取って保持するだけで十分機能を果たせるのであれば、UIView の面倒な部分（生成経路が複数あって UINib 側の経路が面倒）を回避できるからです。

なお、View Handle と View Binding が分離されている理由は、View Handle 側でサードパーティ製の UIView の API を取り回しやすくする調整に専念させたいからです。UIKit を含む多くの View 層のライブラリにイベントストリームの用意などは期待できませんから、この API の調整役が必要なのです。また、もし View Binding に簡易的なテストを用意したくなった場合に偽物の View Handle を差し込むことで、どのような変化を View Binding が指示したかを検証できるという利点もあります。

では具体例を見てみましょう。次の例はリファクタリング前からあった BoardView に対応する View Handle です。この View Handle は次の 3 つの調整をしています：

* BoardViewBinding からの個々のアニメーションの指示を BoardView へ伝える
* BoardView の座標選択イベントをイベントストリームへ変換する
* BoardView のアニメーション完了イベントをイベントストリームへ変換する

```swift
public protocol BoardViewHandleProtocol {
    var coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never> { get }

    func apply(by request: BoardAnimationRequest)
}



public protocol BoardAnimationHandleProtocol {
    var animationDidComplete: ReactiveSwift.Signal<BoardAnimationRequest, Never> { get }
}



public class BoardViewHandle: BoardViewHandleProtocol, BoardAnimationHandleProtocol {
    public let coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never>
    public let animationDidComplete: ReactiveSwift.Signal<BoardAnimationRequest, Never>

    private let coordinateDidSelectObserver: ReactiveSwift.Signal<Coordinate, Never>.Observer
    private let animationDidCompleteObserver: ReactiveSwift.Signal<BoardAnimationRequest, Never>.Observer

    private let boardView: BoardView


    public init(boardView: BoardView) {
        self.boardView = boardView

        (self.coordinateDidSelect, self.coordinateDidSelectObserver) =
            ReactiveSwift.Signal<Coordinate, Never>.pipe()

        (self.animationDidComplete, self.animationDidCompleteObserver) =
            ReactiveSwift.Signal<BoardAnimationRequest, Never>.pipe()

        boardView.delegate = self
    }


    public func apply(by request: BoardAnimationRequest) {
        switch request {
        case .shouldSyncImmediately(board: let board):
            self.syncImmediately(to: board)
        case .shouldAnimate(disk: let disk, at: let coordinate, shouldSyncBefore: let boardToSyncIfExists):
            if let board = boardToSyncIfExists {
                self.syncImmediately(to: board)
            }
            self.animate(disk: disk, at: coordinate, shouldSyncBefore: boardToSyncIfExists)
        }
    }


    private func syncImmediately(to board: Board) {
        self.boardView.layer.removeAllAnimations()
        Coordinate.allCases.forEach { coordinate in
            self.set(disk: board[coordinate], at: coordinate, animated: false, completion: nil)
        }
        self.animationDidCompleteObserver.send(value: .shouldSyncImmediately(board: board))
    }


    private func animate(disk: Disk, at coordinate: Coordinate, shouldSyncBefore board: Board?) {
        self.set(disk: disk, at: coordinate, animated: true) { isFinished in
            if isFinished {
                self.animationDidCompleteObserver.send(value: .shouldAnimate(
                    disk: disk,
                    at: coordinate,
                    shouldSyncBefore: board
                ))
            }
        }
    }


    private func set(disk: Disk?, at coordinate: Coordinate, animated: Bool, completion: ((Bool) -> Void)?) {
        self.boardView.setDisk(
            disk,
            atX: coordinate.x.rawValue - 1,
            y: coordinate.y.rawValue - 1,
            animated: animated,
            completion: completion
        )
    }
}



extension BoardViewHandle: BoardViewDelegate {
    public func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let coordinateX = CoordinateX(rawValue: x + 1) else { return }
        guard let coordinateY = CoordinateY(rawValue: y + 1) else { return }
        self.coordinateDidSelectObserver.send(value: Coordinate(x: coordinateX, y: coordinateY))
    }
}
```

また、少し特殊な View Handle としてリセットボタンが押されたら UIAlertViewController を表示してリセットの意思を再確認するクラスもみてみましょう。注目して欲しいのは本来 `UIAlertViewController` の表示には `UIViewController.present(...)` が必要なため `UIViewController` への依存（大抵は継承）が必要なはずですが、[UIKitTestable](https://github.com/Kuniwak/UIKitTestable) の `ModalPresenter` を使うことでこれを避けています：

```swift
public protocol ResetConfirmationHandleProtocol {
    var resetDidAccept: ReactiveSwift.Signal<Bool, Never> { get }
}



public class ResetConfirmationHandle: ResetConfirmationHandleProtocol {
    private let confirmationViewHandle: UserConfirmationViewHandle<Bool>
    private let button: UIButton


    public let resetDidAccept: ReactiveSwift.Signal<Bool, Never>


    public init(
        button: UIButton,
        willModalsPresentOn modalPresenter: UIKitTestable.ModalPresenterProtocol,
        orEnqueueIfViewNotAppeared modalPresenterQueue: ModalPresenterQueueProtocol
    ) {
        self.button = button

        let confirmationViewHandle = UserConfirmationViewHandle(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert,
            actions: [
                (title: "Cancel", style: .cancel, false),
                // BUG13: Unexpectedly use false instead of true.
                (title: "OK", style: .default, true),
            ],
            willPresentOn: modalPresenter,
            orEnqueueIfViewNotAppeared: modalPresenterQueue
        )
        self.confirmationViewHandle = confirmationViewHandle
        self.resetDidAccept = self.confirmationViewHandle.userDidConfirm

        button.addTarget(self, action: #selector(self.confirm(_:)), for: .touchUpInside)
    }


    @objc private func confirm(_ sender: Any) {
        self.confirmationViewHandle.confirm()
    }
}
```

この `UIKitTestable.ModalPresenter` は次のようにとても薄い `UIViewController.present` の wrapper class です（他にも [`UINavigationiController.push` に対応するもの](https://github.com/Kuniwak/UIKitTestable/blob/17bd00de1746003b96120d7ef7f101a4113a6755/UIKitTestable/UIKitTestable/Navigator.swift) などもあります）：

```swift
/// A wrapper class to encapsulate a implementation of `UIViewController#present(_: UIViewController, animated: Bool)`.
/// You can replace the class with the stub or spy for testing.
/// - SeeAlso: [`ModalPresenterUsages`](https://kuniwak.github.io/UIKitTestable/UIKitTestableAppTests/Classes/ModalPresenterUsages.html).
public final class ModalPresenter<ViewController: UIViewController>: ModalPresenterProtocol {
    private let groundViewController: WeakOrUnowned<ViewController>


    /// Returns newly initialized ModalPresenter with the UIViewController.
    /// Some UIViewControllers will be present on the specified UIViewController of the function.
    public init(wherePresentOn groundViewController: WeakOrUnowned<ViewController>) {
        self.groundViewController = groundViewController
    }


    /// Presents a view controller modally.
    /// This method behave like `UIViewController#present(UIViewController, animated: Bool, completion: (() -> Void)?)`
    public func present(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        switch self.groundViewController {
        case .weakReference(let weak):
            weak.do { groundViewController in
                groundViewController?.present(viewController, animated: animated, completion: completion)
            }
        case .unownedReference(let unowned):
            unowned.do { groundViewController in
                groundViewController.present(viewController, animated: animated, completion: completion)
            }
        }
    }
}
```

これらを駆使して ViewHandle は UIKit やサードパーティ製の View ライブラリを、本体プロジェクトで扱いやすい形へ変換しています。

さて、このリファクタリングの結果をみてみましょう。



## リファクタリングの結果
### 設計はよくなったのか

チャレンジの目的は Fat ViewController をなんとかしたいということだったので、UIViewController の本来の責務であったライフサイクルの管理に専念できるようになったということで最終的な設計は成功していると思います。

なお、ViewController 以外のファイルの行数にも着目してみましょう：

* リファクタリング前→後
	* 平均: 135行 → 69行
	* 最大: 573行 → 308行
	* 全体: 1080行 → 5276行

<details>
<summary>内訳</summary>

#### Before
```connsole
$ ./list-filestats
      29 Reversi/AppDelegate.swift
     176 Reversi/BoardView.swift
     139 Reversi/CellView.swift
      26 Reversi/Disk.swift
      66 Reversi/DiskView.swift
      45 Reversi/SceneDelegate.swift
     573 Reversi/ViewController.swift
      26 ReversiTests/ReversiTests.swift
avg: 135        max: 573        total: 1080
```

#### After
```console
$ ./tools/list-filestats
      29 Reversi/AppDelegate.swift
     130 Reversi/MVCArchitecture/BoardMVCComposer.swift
      32 Reversi/MVCArchitecture/Controllers/BoardAnimationController.swift
      25 Reversi/MVCArchitecture/Controllers/BoardController.swift
      25 Reversi/MVCArchitecture/Controllers/GameAutomatorController.swift
      26 Reversi/MVCArchitecture/Controllers/PassConfirmationController.swift
      27 Reversi/MVCArchitecture/Controllers/ResetConfirmationController.swift
      61 Reversi/MVCArchitecture/DebugHub.swift
      10 Reversi/MVCArchitecture/Models/DebuggableGameAutomator.swift
      29 Reversi/MVCArchitecture/Views/ViewBindings/BoardViewBinding.swift
      27 Reversi/MVCArchitecture/Views/ViewBindings/DiskCountViewBinding.swift
      17 Reversi/MVCArchitecture/Views/ViewBindings/GameAutomatorControlBinding.swift
      26 Reversi/MVCArchitecture/Views/ViewBindings/GameAutomatorProgressViewBinding.swift
      29 Reversi/MVCArchitecture/Views/ViewBindings/PassConfirmationBinding.swift
      29 Reversi/MVCArchitecture/Views/ViewBindings/TurnMessageViewBinding.swift
      97 Reversi/MVCArchitecture/Views/ViewHandles/BoardViewHandle.swift
      29 Reversi/MVCArchitecture/Views/ViewHandles/DiskCountViewHandle.swift
      73 Reversi/MVCArchitecture/Views/ViewHandles/GameAutomatorControlHandle.swift
      38 Reversi/MVCArchitecture/Views/ViewHandles/GameAutomatorProgressViewHandle.swift
      86 Reversi/MVCArchitecture/Views/ViewHandles/ModalPresenterQueue.swift
      40 Reversi/MVCArchitecture/Views/ViewHandles/PassConfirmationHandle.swift
      50 Reversi/MVCArchitecture/Views/ViewHandles/ResetConfirmationHandle.swift
      49 Reversi/MVCArchitecture/Views/ViewHandles/TurnMessageViewHandle.swift
      93 Reversi/MVCArchitecture/Views/ViewHandles/UserConfirmationViewHandle.swift
      45 Reversi/SceneDelegate.swift
     177 Reversi/ThirdPartyViews/BoardView.swift
     141 Reversi/ThirdPartyViews/CellView.swift
      67 Reversi/ThirdPartyViews/DiskView.swift
      71 Reversi/ViewController.swift
     188 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Board.swift
     112 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift
      29 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Buffer.swift
     128 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Coordinate.swift
       5 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/CoordinateSelector.swift
      30 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/DirectedDistance.swift
      14 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Direction.swift
      43 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Disk.swift
      24 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/DiskCount.swift
      30 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Distance.swift
       7 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Dump.swift
     120 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/FlippableLine.swift
     136 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/FlippableLineTests.swift
      49 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameAutomator.swift
      30 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameAutomatorAvailabilities.swift
      12 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameAutomatorAvailability.swift
      47 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameCommand.swift
       7 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameResult.swift
     146 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameState.swift
     120 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/GameStateTests.swift
      55 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Line.swift
      68 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/LineContents.swift
     118 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/NonEmptyArray.swift
      44 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Turn.swift
      55 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/UserDefaultsJSON.swift
      18 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/UserDefaultsKey.swift
       4 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/UserDefaultsReadWriter.swift
       5 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/UserDefaultsReader.swift
       5 ReversiCore/ReversiCore/MVCArchitecture/DataTypes/UserDefaultsWriter.swift
      45 ReversiCore/ReversiCore/MVCArchitecture/Models/AutomatableGameModel.swift
     308 ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModel.swift
     218 ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModelTests.swift
      29 ReversiCore/ReversiCore/MVCArchitecture/Models/DiskCountModel.swift
      37 ReversiCore/ReversiCore/MVCArchitecture/Models/GameAutomatorAvailabilitiesModel.swift
     134 ReversiCore/ReversiCore/MVCArchitecture/Models/GameAutomatorModel.swift
      10 ReversiCore/ReversiCore/MVCArchitecture/Models/GameCommandReceivable.swift
      33 ReversiCore/ReversiCore/MVCArchitecture/Models/GameModel+AutomatableGameModel.swift
     155 ReversiCore/ReversiCore/MVCArchitecture/Models/GameModel.swift
      27 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AnimatedGameModel+AutomatableGameModel.swift
     166 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AnimatedGameModel.swift
     116 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AnimatedGameWithAutomatorsModel.swift
      75 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AutoBackupGameAutomatorAvailabilitiesModel.swift
      74 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AutoBackupGameModel.swift
     277 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/GameWithAutomatorsModel.swift
     189 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/GameWithAutomatorsModelTests.swift
      74 ReversiCore/ReversiCore/MVCArchitecture/Models/ModelTracker.swift
      82 ReversiCore/ReversiCore/MVCArchitecture/Models/UserDefaultsModel.swift
avg: 69.4211    max: 308        total: 5276
```
</details>

個々のファイルは小さくなり小さなコンポーネントへ分割できているようですが、このためになんと全体の行数が5倍になりました。一般的にコンポーネントの分割は全体のコード行数を増やしがちですので、まあこんなもんかなという印象でした。



### バグはどれだけ出たのか

おさらいですが、このリファクタリングではとにかくバグを出さないことを目指していました。そこで、リファクタリングの過程では達成状況を評価できるようにするため、バグを発見したら次のように原因コードの近くにコメントを残すようにしています：

```swift
public struct Board {
    private let array: [[Disk?]]


    // BUG1: Missing -1 for rawValue (CoordinateX and Y is 1-based)
    public subscript(_ coordinate: Coordinate) -> Disk? {
        // NOTE: all coordinates are bound by 8x8, so it must be success.
        self.array[coordinate.y.rawValue - 1][coordinate.x.rawValue - 1]
    }
}
```

<details>
<summary>バグの出現箇所一覧</summary>

```
$ ./tools/list-bugs
BUG 1: Missing -1 for rawValue (CoordinateX and Y is 1-based) (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Board.swift:34)
BUG 2: Missing addition for start. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Line.swift:32)
BUG 3: I expected `x == nil` mean x == .some(.none), but it mean x == .none. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/FlippableLine.swift:85)
BUG 4: Misunderstood that the line.coordinates is sorted as start to end. But it was a Set. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/LineContents.swift:24)
BUG 5: Misunderstand that the break without any labels break from lineContentsLoop. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Board.swift:138)
BUG 6: Loop forever because using continue cause unchanged nextLineContents. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Board.swift:133)
BUG 7: Wrongly use base lines that have constant distance for all search. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Board.swift:143)
BUG 8: Signal from Property does not receive the current value at first. (at ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/GameWithAutomatorsModel.swift:70)
BUG 9: Removing .one to limit line lengths caused that users of .allCases or .init(rawValue:_) get broken. (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/Distance.swift:2)
BUG 10: Did not apply board at BoardView because forgot notify accepted commands to boardAnimationModel. (at ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/AnimatedGameModel.swift:37)
BUG 11: Forgot observing. (at Reversi/MVCArchitecture/Views/ViewHandles/GameAutomatorControlHandle.swift:32)
BUG 12: Missing first because the code was NonEmptyArray(first: self.last, rest: self.rest.reversed()). (at ReversiCore/ReversiCore/MVCArchitecture/DataTypes/NonEmptyArray.swift:58)
BUG 13: Unexpectedly use false instead of true. (at Reversi/MVCArchitecture/Views/ViewHandles/ResetConfirmationHandle.swift:34)
BUG 14: Forgot binding pass confirmation. (at Reversi/MVCArchitecture/BoardMVCComposer.swift:103)
BUG 15: This order followed the order in README.md, but the line direction is inverted. (at ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModel.swift:290)
BUG 16: Initial sync are not applied because markResetAsCompleted was sent before observing. (at Reversi/MVCArchitecture/Controllers/BoardAnimationController.swift:19)
BUG 17: Should not sync in flipping because both ends of the transaction did not match to transitional boards. (at ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModel.swift:182)
BUG 18: Alert not appeared because it called before viewDidAppear. (at Reversi/MVCArchitecture/Views/ViewBindings/PassConfirmationBinding.swift:25)
```
</details>

今回は自動テスト時にクラッシュ2件とバグが7件、手動ポチポチ時に9件のバグを発生させてしまいました。つまり、**動作試験時に死者2名と7名が大変なことになり、本番運用時に9名が大変なことになってしまいました（大惨事）**。

内訳はこんな感じです（原因と発見方法は後からまとめているので不正確なところあっても許してください）：

| ID | 現象 | 原因 | 発見方法 | 
|---:|:-----|:-----|:-------|
| 1  | 起動即クラッシュ | 盤面クラスの内部的な配列は 0-based インデックスだが、座標クラスは 1-based インデックスで out of bounds になった | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 2  | 石をどこにも置けない | Line に沿った盤面の石を取得した LineContents のループ条件にバグがあり開始地点の石が取得できてなかった | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 3  | 石をどこにも置けない | `Optional<Optional<Foo>>` な変数の `== nil` が `.some(nil)` で `false` になるとは思っていなかった | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 4  | 石を置けるはずの場所に置けないことがある | Line 上の座標の配列を返す API に順序があると期待していたが実際には Set だった | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 5  | 遅い | ループの脱出のつもりで `break` を書いたが、`swift` 分の内部だったのでループを脱出できなかった | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 6  | 無反応（無限ループ） | ループの終わりに条件を更新するべきだったがこれをせずに `continue` でループを再開したためずっと同じ条件でループしていた | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 7  | 距離が2より大きい位置へ石を置けない | ループ内で、適切な長さの Line ではなくループ開始条件のための長さ2固定の Line を取り違えて使ってしまったため | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 8  | 起動直後にオートプレイが有効になっていても何も起こらない | ReactiveSwift.Property の購読直後に現在の値が Signal へ流されると勘違いしていた（それは SignalProducer じゃないとできない） | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/master/ReversiCore/ReversiCore/MVCArchitecture/Models/ModelAggregates/GameWithAutomatorsModelTests.swift) |
| 9  | 石をどこにも置けない | 欲を出して Line をより安全な型にしようと Distatnce の 1 を消して 2 始まりにしたら 1 がくることを期待していた配置可能判定が壊れた | [自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/DataTypes/BoardTests.swift) |
| 10 | 1度画面に石を配置すると次はどこにも置けなくなる | アニメーション完了判定を Model へ通知する Controller が接続されておらず Model はずっとアニメーション中だと判断してユーザーの操作を無視した | 手動ポチポチ |
| 11 | オートプレイを有効にしても何も起きない | オートプレイ切り替えの `UISegmentedControl` の UI イベント検知を View Handle で忘れた | 手動ポチポチ |
| 12 | 長さ3以上の Line をひっくり返すアニメーションの最後だけひっくり返らない（ただし見た目だけでゲームロジックは正常） | NonEmptyArray の reversed 実装にバグがあり、末尾が先頭で重複する代わりに先頭要素が抜けてしまった | 手動ポチポチで発見、[自動テスト](https://github.com/Kuniwak/reversi-ios/blob/a219d83ef1b962789bfa52c1eca3cce61b3fb344/ReversiCore/ReversiCore/MVCArchitecture/Models/BoardAnimationModelTests.swift)で再現条件確認 |
| 13 | リセットの確認モーダルで OK を押しても何も起きない | リセットの確認結果の Bool がコピペにより OK と Cancel で両方同じ値になっていた | 手動ポチポチ |
| 14 | パス画面が表示されずパスできない | パス画面を表示させる View Binding の接続忘れ | 手動ポチポチ |
| 15 | 元のアニメーション順序と逆の順序でアニメーションされる | README 通りの順序を設定したつもりが Line の向きの表現が README と逆だった（README は配置地点が基準、Line は対応する自分の石地点が基準だった） | 手動ポチポチ |
| 16 | パスしかない状態で終了するとパス確認画面がでず進行できない | Controller は View Handle からのリセット完了イベントを Model に転送しなければならないが、Controller が接続される前にリセット完了イベントが流れてしまったため Model はリセット完了待ち状態のままになった | 手動ポチポチ |
| 17 | ひっくり返すアニメーションがチラつく | アニメーションが未完了の状態でさらなるアニメーション要求がきた場合に備えてアニメーションの前に盤面を sync する指示を石の配置アニメーション指示に加えたが、間違って石をひっくり返す指示にも加わってしまったためアニメーションの途中で一連のアニメーション前の状態に戻される処理が挟まってしまった | 手動ポチポチ |
| 18 | パスしかできない状態でアプリを再起動するとパス確認画面が再度表示されない | `viewDidAppear` の前に `UIViewController.present` しようとしてしまい無視された | 手動ポチポチ |

この結果が多少のバグが許されるフルスクラッチな開発現場だった場合に、多いと考えるか少ないと考えるかは各自にお任せします。次にそれぞれから見えてきた課題をみてみましょう。



### 原因の分類

* 依存コンポーネントの振る舞いの誤解系: 1, 3, 4, 8
* アルゴリズムの誤記（意図とコードの振る舞いが違った）: 5, 6
* アルゴリズムの誤解（意図がそもそも間違ってた）: 2, 9, 12, 15, 17
* 同じ型の値の取り違え系: 7, 13
* 接続忘れ系: 10, 11, 14
* 実行タイミングの誤解: 16, 18

それぞれの対策を考えてみましたが次のようになりました：

* 依存コンポーネントの振る舞いの誤解系:
	* REPL 駆動開発
* アルゴリズムの誤記（意図とコードの振る舞いが違った）:
	* より強力な静的検査（アドホックに事前条件と事後条件書いて証明するなど（Swift の意味論のモデル化が必要））
* アルゴリズムの誤解（意図がそもそも間違ってた）:
	* より強力な静的検査（アドホックに事前条件と事後条件書いて証明するなど（Swift の意味論のモデル化が必要））
* 同じ型の値の取り違え系:
	* 変数に適切でそれなりに長い名前をつける（7 は `line` ではなく `baseLine` のように）
	* 用途によって型を分ける（Line と FlippableLine のように）
* 接続忘れ系:
	* Unusedクラスの警告とかができれば…
* 実行タイミングの誤解:
	* モデル検査とかができれば（モデル検査は CSP やアクタモデルのようなよく知られたモデルの上で動くのですが、今回は自分のよく使っていた設計の理論的理解が足りておらず苦戦してタイムアウトしました）



## 感想

次からは REPL 駆動開発やモデル検査、証明を駆使してバグを撲滅して死者が出ないようにしようと思いました（過激派）。



## License

[MIT License](LICENSE)
