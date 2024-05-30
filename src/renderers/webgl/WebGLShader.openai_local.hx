将所提供的 JavaScript 代码转换为 Haxe，可以按照以下步骤进行。首先需要了解 Haxe 与 JavaScript 之间的区别。Haxe 是一个多平台的编程语言，可以编译成多种不同的目标语言，包括 JavaScript。为了使 Haxe 代码能够与 WebGL API 兼容，我们需要使用 Haxe 的 externs 来引用 WebGL 的类型和方法。

以下是转换后的 Haxe 代码：

```haxe
package three.renderers.webgl;

import js.html.webgl.GL;
import js.html.webgl.Shader;

class WebGLShader {

    public static function create(gl:GL, type:Int, string:String):Shader {
        var shader:Shader = gl.createShader(type);

        gl.shaderSource(shader, string);
        gl.compileShader(shader);

        return shader;
    }

}
```

### 解释
1. **包声明**: `package three.renderers.webgl;` 对应文件路径 `three.js/src/renderers/webgl/WebGLShader.hx`。
2. **导入 WebGL externs**: `import js.html.webgl.GL;` 和 `import js.html.webgl.Shader;` 导入 WebGL 相关的 externs。
3. **WebGLShader 类**:
   - 使用静态方法 `create` 代替构造函数，符合 Haxe 的习惯。
   - 方法签名 `public static function create(gl:GL, type:Int, string:String):Shader` 中指定了参数和返回类型。
4. **方法内部**:
   - 创建 `shader` 并进行必要的操作：`gl.createShader(type);`、`gl.shaderSource(shader, string);` 和 `gl.compileShader(shader);`。
   - 最后返回 `shader`。

### 导出
在 Haxe 中不需要类似于 JavaScript 的 `export` 语法，因为 Haxe 的模块系统会自动处理导出类和方法。在需要使用的地方直接导入并使用该类即可。

### 总结
转换后的 Haxe 代码保持了原有 JavaScript 代码的逻辑和功能，但采用了 Haxe 的语法和特性。确保在使用之前已经正确配置了 Haxe 的 WebGL externs，以便正确引用 WebGL API。