# republish 中心の `ObservableObject` についての考察

ある View に対応した `ObservableObject` として `ViewState` を導入することを考える。

`ViewState` のプロパティの値が別のプロパティの値から導かれるときに、そのプロパティを computed property として実装するか、 `@Published` な Stored property として宣言し、 republish するかという二つの選択肢がある。

本文書では両者を比較し、 republish 中心にアプリを実装する効率的な方法について考察する。

## republish の問題点

- 実装が複雑でボイラープレートが多め
- 宣言と実装がコード上で分離する
- republish 忘れのリスクが存在する
- パフォーマンスが悪い

### 実装が複雑でボイラープレートが多め

例として、スライダーの値を整形して表示することを考える。

今、 `SliderViewState` がプロパティ `value` を持つものとする。

```swift
public final class SliderViewState: ObservableObject {
    @Published public var value: Float = 0
}
```

この `value` の値から、整形された文字列 `valueText` の値が導かれる。

```swift
// value を整形
let formatter: NumberFormatter = .init()
formatter.numberStyle = .decimal
formatter.minimumFractionDigits = 3
formatter.maximumFractionDigits = 3
return formatter.string(from: NSNumber(value: value)) ?? value.description
```

`valueText` を computed property で実装する場合は単純である。上記の整形のためのコードをそのまま computed property として実装すれば良い。

```swift
// computed property
public final class SliderViewState: ObservableObject {
    @Published public var value: Float = 0
    
    public var valueText: String {
        let formatter: NumberFormatter = .init()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        return formatter.string(from: NSNumber(value: value)) ?? value.description
    }
}
```

republish はこれと比べて複雑になりがちである。

```swift
// republish
public final class SliderViewState: ObservableObject {
    @Published public var value: Float = 0
    @Published public private(set) var valueText: String = ""
    
    public init() {
        $value.map { value in
            let formatter: NumberFormatter = .init()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
            return formatter.string(from: NSNumber(value: value)) ?? value.description
        }
        .assign(to: &$valueText)
    }
}
```

## 宣言と実装がコード上で分離する

前述の republish の例では、 `valueText` の宣言と実装が分かれてしまい、コードを追いづらいという問題もある。特に、 `valueText` の値が `value` から導かれるべきことがひと目でわからないと、誤ってプロパティに直接値を代入してしまうリスクがある。そのような場合、意図せずに不正な状態を生む可能性がある。

```swift
// 他の値から導かれるプロパティへの誤代入
public final class SliderViewState: ObservableObject {
    @Published public var value: Float = 0
    @Published public private(set) var valueText: String = ""

    ...
    
    public func reset() {
        value = 0
        valueText = "" // ⛔ value = 0 によって "0.000" が設定されるのに "" で初期化してしまった
    }
}
```

これに対処するには、次のように republish の処理をメソッドとして分離し、プロパティの宣言と並べることができる。

```swift
// republish （宣言と実装の分離への対処）
public final class SliderViewState: ObservableObject {
    @Published public var value: Float = 0
    
    @Published public private(set) var valueText: String = ""
    private func republishToValueText() {
        $value.map { value in
            let formatter: NumberFormatter = .init()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
            return formatter.string(from: NSNumber(value: value)) ?? value.description
        }
        .assign(to: &$valueText)
    }
    
    public init() {
        republishToValueText()
    }
}
```

こうすれば、 `valueText` が `value` から導かれることは、コードから比較的読み取りやすい。しかし、根本的に代入を防ぐことができるわけではない。

### republish 忘れのリスクが存在する

前述の例で、 `republishToValueText` をイニシャライザから呼び忘れる可能性がある。そうすると、 `value` への更新が `valueText` に伝播しないバグを生む。

### パフォーマンスが悪い

たとえば、 `users: [User]` から `userNames: [String]` に republish するようなケースを考える。 computed property だろうと republish だろうと、変換に　O(n) の処理が必要なことに変わりはない。

この O(n) を避けるために、 `[String]` の代わりに `LazySequence` を返すような実装を考える。この場合、変換自体は O(1) で実行でき、 `userNames` の利用側でだけループすればよい。しかし、 republish でこれを実現しようとする場合、 `users` の `Array` を `users` と `userNames` が二重に参照することになり、 `users` の変更で Copy-on-Write のコピーが実行され、 O(n) のコストがかかる。 computed property では（たとえば `users` に新しいユーザーを `append` するなどの）変更のコストは O(1) である。

ただし、この点に関しては、結局 View が `userNames` を利用する際にループしなければならず、全体の計算量としては O(n) で変わらない点には留意が必要である。計算量が同じとはいえ、 republish する度に O(n) のコストがかかるので、多段の republish や要素数が多い場合、また 60 fps のようなハイパフォーマンスが求められる環境では、この違いが問題になる可能性は存在する。

## computed property の問題点

しかし、 Computed property には次のような問題がある。

- View 側で `Publisher` として購読することができない。
- `ViewState` のプロパティの値が別の Model クラスのプロパティの値から導かれる場合、変更検知のために republish が必要である。
- `ViewState` の状態を自由に作り上げることができないので、 View の見た目を確認するコストが大きい。

TODO
