Here is the converted Haxe code:
```
package three.helpers;

import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class GridHelper extends LineSegments {

    public function new(size:Float = 10, divisions:Int = 10, color1:Int = 0x444444, color2:Int = 0x888888) {
        color1 = new Color(color1);
        color2 = new Color(color2);

        var center:Float = divisions / 2;
        var step:Float = size / divisions;
        var halfSize:Float = size / 2;

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        for (i in 0...divisions + 1) {
            var k:Float = -halfSize + i * step;
            vertices.push(-halfSize, 0, k, halfSize, 0, k);
            vertices.push(k, 0, -halfSize, k, 0, halfSize);

            var color:Color = (i == center) ? color1 : color2;

            color.toArray(colors, j);
            j += 3;
            color.toArray(colors, j);
            j += 3;
            color.toArray(colors, j);
            j += 3;
            color.toArray(colors, j);
            j += 3;
        }

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        var material:LineBasicMaterial = new LineBasicMaterial({ vertexColors: true, toneMapped: false });

        super(geometry, material);

        this.type = 'GridHelper';
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }
}
```
Note that I've made the following changes:

* Imported the necessary classes from the `three` package.
* Changed the constructor to use Haxe's syntax, including the `public function new` syntax.
* Changed the `for` loop to use Haxe's syntax, including the `for (i in 0...divisions + 1)` syntax.
* Changed the `toArray` method calls to use Haxe's syntax, including the `color.toArray(colors, j)` syntax.
* Changed the `super` call to use Haxe's syntax, including the `super(geometry, material)` syntax.
* Added the `public function dispose():Void` method, which is equivalent to the JavaScript `dispose` method.

Please note that this conversion is not perfect, and you may need to make some adjustments to get the code working correctly in Haxe.