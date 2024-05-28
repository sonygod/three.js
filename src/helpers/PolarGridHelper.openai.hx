package three.helpers;

import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class PolarGridHelper extends LineSegments {

    public function new(?radius:Float = 10, ?sectors:Int = 16, ?rings:Int = 8, ?divisions:Int = 64, ?color1:Int = 0x444444, ?color2:Int = 0x888888) {
        color1 = new Color(color1);
        color2 = new Color(color2);

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        // create the sectors

        if (sectors > 1) {
            for (i in 0...sectors) {
                var v:Float = (i / sectors) * (Math.PI * 2);
                var x:Float = Math.sin(v) * radius;
                var z:Float = Math.cos(v) * radius;

                vertices.push(0, 0, 0);
                vertices.push(x, 0, z);

                var color:Color = (i & 1) == 0 ? color1 : color2;

                colors.push(color.r, color.g, color.b);
                colors.push(color.r, color.g, color.b);
            }
        }

        // create the rings

        for (i in 0...rings) {
            var color:Color = (i & 1) == 0 ? color1 : color2;

            var r:Float = radius - (radius / rings * i);

            for (j in 0...divisions) {
                // first vertex

                var v:Float = (j / divisions) * (Math.PI * 2);

                var x:Float = Math.sin(v) * r;
                var z:Float = Math.cos(v) * r;

                vertices.push(x, 0, z);
                colors.push(color.r, color.g, color.b);

                // second vertex

                v = ((j + 1) / divisions) * (Math.PI * 2);

                x = Math.sin(v) * r;
                z = Math.cos(v) * r;

                vertices.push(x, 0, z);
                colors.push(color.r, color.g, color.b);
            }
        }

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new BufferAttribute(colors, 3));

        var material:LineBasicMaterial = new LineBasicMaterial({ vertexColors: true, toneMapped: false });

        super(geometry, material);

        this.type = 'PolarGridHelper';
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }
}