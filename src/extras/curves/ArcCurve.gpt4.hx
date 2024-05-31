将以下 JavaScript 代码转换为 Haxe，考虑上下文信息（文件路径：three.js/src/extras/curves/ArcCurve.js）：

### 原始 JavaScript 代码
```javascript
import { EllipseCurve } from './EllipseCurve.js';

class ArcCurve extends EllipseCurve {

	constructor( aX, aY, aRadius, aStartAngle, aEndAngle, aClockwise ) {

		super( aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise );

		this.isArcCurve = true;

		this.type = 'ArcCurve';

	}

}

export { ArcCurve };
```

### 转换后的 Haxe 代码
```haxe
import three.extras.curves.EllipseCurve;

class ArcCurve extends EllipseCurve {
    public var isArcCurve:Bool;
    public var type:String;

    public function new(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool) {
        super(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);

        this.isArcCurve = true;
        this.type = 'ArcCurve';
    }
}
```

### 解释
1. **导入**：`import { EllipseCurve } from './EllipseCurve.js';` 被转换为 `import three.extras.curves.EllipseCurve;`。假设 `EllipseCurve` 位于 `three.extras.curves` 包中。
2. **类声明**：JavaScript 的 `class ArcCurve extends EllipseCurve` 转换为 Haxe 的 `class ArcCurve extends EllipseCurve`。
3. **构造函数**：JavaScript 的 `constructor` 转换为 Haxe 的 `public function new`，并将参数类型指定为 `Float` 或 `Bool`。
4. **调用父类构造函数**：`super( aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise );` 保持不变。
5. **属性声明**：在 Haxe 中，类属性需要显式声明类型，所以 `isArcCurve` 和 `type` 被声明为 `Bool` 和 `String`。
6. **导出**：Haxe 不需要显式导出语句，文件名通常与类名相同。

这个转换假设 `EllipseCurve` 类已经在 `three.extras.curves` 包中定义，并且正确导入。