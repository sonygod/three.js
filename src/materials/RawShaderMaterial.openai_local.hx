将您提供的 JavaScript 代码转换为 Haxe 代码，同时考虑给定的上下文信息，转换后的 Haxe 代码如下所示：

```haxe
import three.materials.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {

	public var isRawShaderMaterial:Bool;
	public var type:String;

	public function new(parameters:Dynamic) {
		super(parameters);

		this.isRawShaderMaterial = true;
		this.type = 'RawShaderMaterial';
	}

}

```

这是代码的详细解释：

1. **导入模块**:
   - 在 Haxe 中，我们使用 `import` 语句来导入模块，与 JavaScript 类似。

2. **类定义**:
   - 使用 `class` 关键字定义 `RawShaderMaterial` 类，继承自 `ShaderMaterial`。

3. **构造函数**:
   - 构造函数使用 `new` 关键字，并且接受一个 `parameters` 参数。

4. **属性**:
   - 使用 `public var` 声明两个公共属性 `isRawShaderMaterial` 和 `type`。

5. **初始化属性**:
   - 在构造函数内部，调用父类的构造函数 `super(parameters)` 来初始化父类的属性。
   - 设置 `isRawShaderMaterial` 为 `true` 和 `type` 为 `'RawShaderMaterial'`。

注意：在 Haxe 中，类型系统比 JavaScript 更严格，因此我们需要明确声明属性的类型（例如，`isRawShaderMaterial` 是 `Bool` 类型，`type` 是 `String` 类型）。