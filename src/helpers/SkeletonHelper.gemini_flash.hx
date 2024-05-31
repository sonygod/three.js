import three.objects.LineSegments;
import three.math.Matrix4;
import three.materials.LineBasicMaterial;
import three.math.Color;
import three.math.Vector3;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class SkeletonHelper extends LineSegments {

	public var root:Dynamic;
	public var bones:Array<Dynamic>;

	public function new(object:Dynamic) {
		var bones = getBoneList(object);
		var geometry = new BufferGeometry();

		var vertices = new Array<Float>();
		var colors = new Array<Float>();

		var color1 = new Color(0, 0, 1);
		var color2 = new Color(0, 1, 0);

		for (i in 0...bones.length) {
			var bone = bones[i];

			if (bone.parent != null && bone.parent.isBone) {
				vertices.push(0, 0, 0);
				vertices.push(0, 0, 0);
				colors.push(color1.r, color1.g, color1.b);
				colors.push(color2.r, color2.g, color2.b);
			}
		}

		geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

		var material = new LineBasicMaterial({vertexColors: true, depthTest: false, depthWrite: false, toneMapped: false, transparent: true});

		super(geometry, material);

		this.isSkeletonHelper = true;
		this.type = 'SkeletonHelper';

		this.root = object;
		this.bones = bones;

		this.matrix = object.matrixWorld;
		this.matrixAutoUpdate = false;
	}

	public function updateMatrixWorld(force:Bool) {
		var bones = this.bones;
		var geometry = this.geometry;
		var position = geometry.getAttribute('position');

		var _matrixWorldInv = new Matrix4().copy(this.root.matrixWorld).invert();

		for (i in 0...bones.length) {
			var bone = bones[i];

			if (bone.parent != null && bone.parent.isBone) {
				var _boneMatrix = new Matrix4().multiplyMatrices(_matrixWorldInv, bone.matrixWorld);
				var _vector = new Vector3().setFromMatrixPosition(_boneMatrix);
				position.setXYZ(i * 2, _vector.x, _vector.y, _vector.z);

				_boneMatrix.multiplyMatrices(_matrixWorldInv, bone.parent.matrixWorld);
				_vector.setFromMatrixPosition(_boneMatrix);
				position.setXYZ((i * 2) + 1, _vector.x, _vector.y, _vector.z);
			}
		}

		geometry.getAttribute('position').needsUpdate = true;

		super.updateMatrixWorld(force);
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}
}

function getBoneList(object:Dynamic):Array<Dynamic> {
	var boneList = new Array<Dynamic>();

	if (object.isBone) {
		boneList.push(object);
	}

	for (i in 0...object.children.length) {
		boneList.push(object.children[i]);
	}

	return boneList;
}

class SkeletonHelper {

	public static function new(object:Dynamic):SkeletonHelper {
		return new SkeletonHelper(object);
	}
}


**解释:**

1. **类和方法:** 代码中定义了 `SkeletonHelper` 类，并保留了 `updateMatrixWorld` 和 `dispose` 方法。
2. **数据类型:** 将 JavaScript 中的 `Array` 替换为 Haxe 的 `Array<T>`，并使用 `Dynamic` 类型来表示 JavaScript 对象。
3. **变量初始化:** 将 JavaScript 中的 `const` 变量替换为 Haxe 中的 `var` 变量，并在声明时进行初始化。
4. **循环语句:** 使用 Haxe 中的 `for` 循环遍历数组。
5. **对象创建:** 使用 `new` 关键字创建对象。
6. **访问属性:** 使用 `.` 操作符访问对象属性。
7. **函数调用:** 使用 `()` 操作符调用函数。
8. **类型转换:** 使用 `cast` 函数进行类型转换。
9. **静态方法:** 使用 `static` 关键字定义静态方法，以便在不创建实例的情况下调用方法。

**注意:**

* Haxe 没有 `@__PURE__*/` 注释，所以需要手动移除这些注释。
* Haxe 中没有 `isBone` 属性，需要根据实际情况修改代码。
* Haxe 的语法和 JavaScript 有所不同，需要进行一些代码调整。

**代码示例:**


// 使用 SkeletonHelper 类
var skeletonHelper = new SkeletonHelper(object);

// 更新骨骼辅助线
skeletonHelper.updateMatrixWorld(true);

// 释放资源
skeletonHelper.dispose();