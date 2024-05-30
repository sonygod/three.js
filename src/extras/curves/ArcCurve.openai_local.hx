要将上述 JavaScript 代码转换为 Haxe，可以按照以下步骤进行：Haxe 中的类定义、继承和导入模块都与 JavaScript 有所不同。具体转换如下：

```haxe
import threejs.extras.curves.EllipseCurve;

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

在这个转换过程中：

1. `import { EllipseCurve } from './EllipseCurve.js';` 被替换为 `import threejs.extras.curves.EllipseCurve;`。注意，这里的导入路径需要根据 Haxe 的模块路径进行调整。

2. 构造函数 `constructor` 在 Haxe 中变为 `new`。

3. `super( aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise );` 保持不变，但语法稍有不同。

4. `this.isArcCurve = true;` 和 `this.type = 'ArcCurve';` 被直接转换为 Haxe 的属性赋值，并且在类中声明它们的类型。

Haxe 的类型系统要求在定义属性时明确其类型，这与 JavaScript 的动态类型系统有所不同。