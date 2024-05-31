将给定的 JavaScript 代码转换为 Haxe 的代码如下：

```haxe
import three.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public var isArrayCamera:Bool;
    public var cameras:Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = []) {
        super();
        this.isArrayCamera = true;
        this.cameras = array;
    }

}
```

### 解释：
1. `import { PerspectiveCamera } from './PerspectiveCamera.js';` 对应 Haxe 中的 `import three.cameras.PerspectiveCamera;`，假设 `PerspectiveCamera` 类在 `three.cameras` 包下。
2. JavaScript 中的 `constructor( array = [] )` 在 Haxe 中转换为 `public function new(array:Array<PerspectiveCamera> = [])`。
3. Haxe 使用 `var` 关键字声明类成员变量，因此 `this.isArrayCamera = true;` 转换为 `public var isArrayCamera:Bool;` 并在构造函数中赋值。
4. 类成员 `cameras` 声明为 `Array<PerspectiveCamera>` 类型，以便与 JavaScript 中的 `array` 保持一致。

确保你的 Haxe 项目结构和类路径设置正确，以便能够正确导入 `PerspectiveCamera`。