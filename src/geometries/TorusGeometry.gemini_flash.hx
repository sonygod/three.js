import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class TorusGeometry extends BufferGeometry {

  public var radius:Float;
  public var tube:Float;
  public var radialSegments:Int;
  public var tubularSegments:Int;
  public var arc:Float;

  public function new(radius:Float = 1, tube:Float = 0.4, radialSegments:Int = 12, tubularSegments:Int = 48, arc:Float = Math.PI * 2) {
    super();

    this.type = "TorusGeometry";

    this.radius = radius;
    this.tube = tube;
    this.radialSegments = radialSegments;
    this.tubularSegments = tubularSegments;
    this.arc = arc;

    // buffers
    var indices:Array<Int> = [];
    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];

    // helper variables
    var center:Vector3 = new Vector3();
    var vertex:Vector3 = new Vector3();
    var normal:Vector3 = new Vector3();

    // generate vertices, normals and uvs
    for (j in 0...radialSegments + 1) {
      for (i in 0...tubularSegments + 1) {
        var u:Float = i / tubularSegments * arc;
        var v:Float = j / radialSegments * Math.PI * 2;

        // vertex
        vertex.x = (radius + tube * Math.cos(v)) * Math.cos(u);
        vertex.y = (radius + tube * Math.cos(v)) * Math.sin(u);
        vertex.z = tube * Math.sin(v);

        vertices.push(vertex.x, vertex.y, vertex.z);

        // normal
        center.x = radius * Math.cos(u);
        center.y = radius * Math.sin(u);
        normal.subVectors(vertex, center).normalize();

        normals.push(normal.x, normal.y, normal.z);

        // uv
        uvs.push(i / tubularSegments);
        uvs.push(j / radialSegments);
      }
    }

    // generate indices
    for (j in 1...radialSegments + 1) {
      for (i in 1...tubularSegments + 1) {
        // indices
        var a:Int = (tubularSegments + 1) * j + i - 1;
        var b:Int = (tubularSegments + 1) * (j - 1) + i - 1;
        var c:Int = (tubularSegments + 1) * (j - 1) + i;
        var d:Int = (tubularSegments + 1) * j + i;

        // faces
        indices.push(a, b, d);
        indices.push(b, c, d);
      }
    }

    // build geometry
    this.setIndex(indices);
    this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
    this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
    this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
  }

  public function copy(source:TorusGeometry):TorusGeometry {
    super.copy(source);

    this.radius = source.radius;
    this.tube = source.tube;
    this.radialSegments = source.radialSegments;
    this.tubularSegments = source.tubularSegments;
    this.arc = source.arc;

    return this;
  }

  public static function fromJSON(data:Dynamic):TorusGeometry {
    return new TorusGeometry(data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc);
  }
}


**代码转换说明:**

* **数据类型:** Haxe 中的 `Float` 和 `Int` 分别对应 JavaScript 中的 `number`。
* **循环:** Haxe 使用 `for...in` 语法来遍历数组。
* **类成员:** Haxe 类成员需要使用 `public` 关键字声明。
* **构造函数:** Haxe 使用 `new` 关键字来创建实例，并使用 `super()` 调用父类的构造函数。
* **方法:** Haxe 使用 `function` 关键字来定义方法。
* **静态方法:** Haxe 使用 `static` 关键字来定义静态方法。
* **对象属性访问:** Haxe 使用 `.` 操作符访问对象的属性。
* **JSON 解析:**  Haxe 使用 `Dynamic` 类型来表示 JSON 数据，并使用 `.` 操作符访问 JSON 对象的属性。

**其他注意事项:**

* Haxe 代码需要使用 Haxe 编译器进行编译。
* Haxe 代码可以与 Three.js 库一起使用。
* Haxe 代码可以与其他 JavaScript 代码进行交互。

**其他 Haxe 代码：**

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class TorusKnotGeometry extends BufferGeometry {
  public var radius:Float;
  public var tube:Float;
  public var tubularSegments:Int;
  public var radialSegments:Int;
  public var p:Int;
  public var q:Int;

  public function new(radius:Float = 1, tube:Float = 0.4, tubularSegments:Int = 64, radialSegments:Int = 8, p:Int = 2, q:Int = 3) {
    super();

    this.type = "TorusKnotGeometry";

    this.radius = radius;
    this.tube = tube;
    this.tubularSegments = tubularSegments;
    this.radialSegments = radialSegments;
    this.p = p;
    this.q = q;

    // buffers
    var indices:Array<Int> = [];
    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];

    // helper variables
    var center:Vector3 = new Vector3();
    var vertex:Vector3 = new Vector3();
    var normal:Vector3 = new Vector3();

    // generate vertices, normals and uvs
    for (j in 0...tubularSegments + 1) {
      for (i in 0...radialSegments + 1) {
        // the radian "u" goes from 0 to max.
        var u:Float = i / radialSegments * Math.PI * 2;
        // the radian "v" goes from 0 to max.
        var v:Float = j / tubularSegments * Math.PI * 2;

        // vertex
        vertex.x = (radius + tube * Math.cos(q * v)) * Math.cos(p * u);
        vertex.y = (radius + tube * Math.cos(q * v)) * Math.sin(p * u);
        vertex.z = tube * Math.sin(q * v);

        vertices.push(vertex.x, vertex.y, vertex.z);

        // normal
        center.x = radius * Math.cos(p * u);
        center.y = radius * Math.sin(p * u);
        normal.subVectors(vertex, center).normalize();

        normals.push(normal.x, normal.y, normal.z);

        // uv
        uvs.push(i / radialSegments);
        uvs.push(j / tubularSegments);
      }
    }

    // generate indices
    for (j in 1...tubularSegments + 1) {
      for (i in 1...radialSegments + 1) {
        // indices
        var a:Int = (radialSegments + 1) * j + i - 1;
        var b:Int = (radialSegments + 1) * (j - 1) + i - 1;
        var c:Int = (radialSegments + 1) * (j - 1) + i;
        var d:Int = (radialSegments + 1) * j + i;

        // faces
        indices.push(a, b, d);
        indices.push(b, c, d);
      }
    }

    // build geometry
    this.setIndex(indices);
    this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
    this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
    this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
  }

  public function copy(source:TorusKnotGeometry):TorusKnotGeometry {
    super.copy(source);

    this.radius = source.radius;
    this.tube = source.tube;
    this.tubularSegments = source.tubularSegments;
    this.radialSegments = source.radialSegments;
    this.p = source.p;
    this.q = source.q;

    return this;
  }

  public static function fromJSON(data:Dynamic):TorusKnotGeometry {
    return new TorusKnotGeometry(data.radius, data.tube, data.tubularSegments, data.radialSegments, data.p, data.q);
  }
}