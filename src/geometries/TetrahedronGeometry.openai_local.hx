要将这段 JavaScript 代码转换为 Haxe，我们需要注意 Haxe 和 JavaScript 之间的语法差异，并且需要确保导入和类结构的正确性。下面是转换后的 Haxe 代码：

```haxe
import threejs.geometries.PolyhedronGeometry;

class TetrahedronGeometry extends PolyhedronGeometry {

    public var parameters:Dynamic;
    
    public function new(radius:Float = 1, detail:Int = 0) {
        var vertices:Array<Float> = [
            1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1
        ];
        
        var indices:Array<Int> = [
            2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1
        ];
        
        super(vertices, indices, radius, detail);
        
        this.type = 'TetrahedronGeometry';
        
        this.parameters = {
            radius: radius,
            detail: detail
        };
    }
    
    public static function fromJSON(data:Dynamic):TetrahedronGeometry {
        return new TetrahedronGeometry(data.radius, data.detail);
    }
}
```

### 解释
1. **导入和继承**：
   - `import { PolyhedronGeometry } from './PolyhedronGeometry.js';` 被转换为 `import threejs.geometries.PolyhedronGeometry;`。假设 `PolyhedronGeometry` 在 Haxe 的 `threejs.geometries` 包中。

2. **构造函数**：
   - `constructor( radius = 1, detail = 0 )` 转换为 Haxe 的 `public function new(radius:Float = 1, detail:Int = 0)`。
   - JavaScript 的数组 `[ ... ]` 转换为 Haxe 的数组 `Array<Float>` 和 `Array<Int>`。

3. **静态方法**：
   - `static fromJSON( data )` 转换为 Haxe 的 `public static function fromJSON(data:Dynamic):TetrahedronGeometry`。

4. **其他变量和类型**：
   - JavaScript 中的 `this.type` 和 `this.parameters` 被直接转换为 Haxe 的 `this.type` 和 `this.parameters`。 `parameters` 被声明为 `Dynamic` 类型，以便能够存储不同类型的值（类似于 JavaScript 的对象）。

这段代码转换后应当在 Haxe 环境下正常工作，假设 `threejs` 库已经正确配置。