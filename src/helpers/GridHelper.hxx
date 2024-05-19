import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class GridHelper extends LineSegments {

    public function new(size:Float = 10, divisions:Int = 10, color1:Int = 0x444444, color2:Int = 0x888888) {

        var color1 = new Color(color1);
        var color2 = new Color(color2);

        var center = divisions / 2;
        var step = size / divisions;
        var halfSize = size / 2;

        var vertices = [];
        var colors = [];

        for (i in 0...divisions+1) {

            var k = - halfSize + i * step;

            vertices.push( - halfSize, 0, k, halfSize, 0, k );
            vertices.push( k, 0, - halfSize, k, 0, halfSize );

            var color = if (i == center) color1 else color2;

            colors.pushArray(color.toArray());
            colors.pushArray(color.toArray());
            colors.pushArray(color.toArray());
            colors.pushArray(color.toArray());

        }

        var geometry = new BufferGeometry();
        geometry.setAttribute( 'position', new BufferAttribute(vertices, 3) );
        geometry.setAttribute( 'color', new BufferAttribute(colors, 3) );

        var material = new LineBasicMaterial( { vertexColors: true, toneMapped: false } );

        super(geometry, material);

        this.type = 'GridHelper';

    }

    public function dispose() {

        this.geometry.dispose();
        this.material.dispose();

    }

}