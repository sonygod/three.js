要将这段 JavaScript 代码转换为 Haxe，可以按以下方式进行：

```haxe
import three.core.Object3D;

class Bone extends Object3D {

	public var isBone:Bool;
	public var type:String;

	public function new() {
		super();

		this.isBone = true;
		this.type = 'Bone';
	}

}
```

解释：
1. `import` 语句在 Haxe 中与 JavaScript 类似，但要根据 Haxe 的包结构调整路径。
2. `public var` 用于声明公开的类成员变量。
3. 构造函数 `new` 替代了 JavaScript 中的 `constructor`。
4. `super()` 调用了父类的构造函数。
5. 类的导出在 Haxe 中不需要显式声明，定义即导出。