将以下 JavaScript 代码转换为 Haxe，同时考虑到上下文信息 (文件路径: three.js/src/geometries/TetrahedronGeometry.js):

```javascript
import { PolyhedronGeometry } from './PolyhedronGeometry.js';

class TetrahedronGeometry extends PolyhedronGeometry {

	constructor( radius = 1, detail = 0 ) {

		const vertices = [
			1, 1, 1, 	- 1, - 1, 1, 	- 1, 1, - 1, 	1, - 1, - 1
		];

		const indices = [
			2, 1, 0, 	0, 3, 2,	1, 3, 0,	2, 3, 1
		];

		super( vertices, indices, radius, detail );

		this.type = 'TetrahedronGeometry';

		this.parameters = {
			radius: radius,
			detail: detail
		};

	}

	static fromJSON( data ) {

		return new TetrahedronGeometry( data.radius, data.detail );

	}

}

export { TetrahedronGeometry };

```

下面是转换后的 Haxe 代码：

```haxe
package three.src.geometries;

import three.src.geometries.PolyhedronGeometry;

class TetrahedronGeometry extends PolyhedronGeometry {

	public var type:String;
	public var parameters:{radius:Float, detail:Int};

	public function new(?radius:Float = 1, ?detail:Int = 0) {
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

解释：

1. 导入模块：在 Haxe 中，使用 `import` 语句导入模块路径。
2. 定义类和构造函数：使用 `class` 关键字定义类，`function new` 定义构造函数。
3. 类型声明：Haxe 强类型，因此需要声明变量类型，如 `Float` 和 `Int`。
4. 数组定义：Haxe 的数组定义与 JavaScript 相似。
5. super 调用：在 Haxe 中通过 `super` 调用父类构造函数。
6. 静态方法：使用 `public static function` 定义静态方法。

这种转换保持了 JavaScript 代码的结构和逻辑，同时遵循了 Haxe 的语法和类型系统。