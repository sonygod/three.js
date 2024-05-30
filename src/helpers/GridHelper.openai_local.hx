import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.Float32BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class GridHelper extends LineSegments {

    public function new(size:Float = 10, divisions:Int = 10, color1:Dynamic = 0x444444, color2:Dynamic = 0x888888) {
        color1 = new Color(color1);
        color2 = new Color(color2);

        var center:Int = divisions / 2;
        var step:Float = size / divisions;
        var halfSize:Float = size / 2;

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        for (i in 0...divisions + 1) {
            var k:Float = -halfSize + i * step;

            vertices.push(-halfSize, 0, k, halfSize, 0, k);
            vertices.push(k, 0, -halfSize, k, 0, halfSize);

            var color:Color = (i == center) ? color1 : color2;

            color.toArray(colors);
            color.toArray(colors);
            color.toArray(colors);
            color.toArray(colors);
        }

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute("color", new Float32BufferAttribute(colors, 3));

        var material:LineBasicMaterial = new LineBasicMaterial({vertexColors: true, toneMapped: false});

        super(geometry, material);

        this.type = "GridHelper";
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }

}