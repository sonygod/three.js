将给定的 JavaScript 代码转换为 Haxe 代码，同时保持其功能和结构。下面是 Haxe 版本的代码：

```haxe
package three.audio;

class AudioContext {

    static var _context:Dynamic;

    public static function getContext():Dynamic {
        if (_context == null) {
            _context = new (js.Browser.window.AudioContext != null ? js.Browser.window.AudioContext : js.Browser.window.webkitAudioContext)();
        }
        return _context;
    }

    public static function setContext(value:Dynamic):Void {
        _context = value;
    }

}
```

### 说明
1. **包声明**：假设文件路径为 `three.js/src/audio/AudioContext.js`，将其转换为 Haxe 包 `three.audio`。
2. **静态变量**：使用 `static var` 声明静态变量 `_context`，类型为 `Dynamic` 以匹配 JavaScript 中的灵活性。
3. **静态方法**：定义 `getContext` 和 `setContext` 方法。`getContext` 检查 `_context` 是否为 `null`，然后初始化。如果 `js.Browser.window.AudioContext` 不为 `null`，则使用它，否则使用 `js.Browser.window.webkitAudioContext`。
4. **类型兼容**：Haxe 需要显式类型，因此返回值和参数都标记为 `Dynamic`。