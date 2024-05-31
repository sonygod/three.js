将给定的 JavaScript 代码转换为 Haxe 代码，需要考虑 Haxe 语法和类结构。Haxe 中使用 `import` 来导入类，并且继承类使用 `extends` 关键字。以下是对应的 Haxe 代码：

文件路径: three.js/src/materials/RawShaderMaterial.hx

```haxe
import three.js.src.materials.ShaderMaterial;

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

### 说明
1. `import` 语句用于导入 `ShaderMaterial` 类。
2. `extends` 关键字用于继承 `ShaderMaterial` 类。
3. 构造函数 `new` 使用 `Dynamic` 类型来接受参数。
4. `isRawShaderMaterial` 和 `type` 变量在构造函数中初始化。

这样转换后，Haxe 代码与原始 JavaScript 代码的逻辑保持一致。