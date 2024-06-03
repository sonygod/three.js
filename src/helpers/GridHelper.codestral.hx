import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class GridHelper extends LineSegments {

    public function new(size:Float = 10, divisions:Int = 10, color1:Int = 0x444444, color2:Int = 0x888888) {
        super();

        var color1 = new Color(color1);
        var color2 = new Color(color2);

        var center = divisions / 2;
        var step = size / divisions;
        var halfSize = size / 2;

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        for (var i = 0; i <= divisions; i++) {
            var k = -halfSize + i * step;

            vertices.push(-halfSize, 0, k, halfSize, 0, k);
            vertices.push(k, 0, -halfSize, k, 0, halfSize);

            var color = (i == center) ? color1 : color2;

            colors = colors.concat(color.toArray());
            colors = colors.concat(color.toArray());
            colors = colors.concat(color.toArray());
            colors = colors.concat(color.toArray());
        }

        var geometry = new BufferGeometry();
        geometry.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
        geometry.setAttribute('color', new BufferAttribute(new Float32Array(colors), 3));

        var material = new LineBasicMaterial({vertexColors: true, toneMapped: false});

        super(geometry, material);

        this.type = 'GridHelper';
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }
}