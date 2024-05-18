package three.js.examples.jml.helpers;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.Line;
import three.js.LineBasicMaterial;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.Side;

class RectAreaLightHelper extends Line {
    public var light:Dynamic;
    public var color:Null<Int>;
    public var type:String;

    public function new(light:Dynamic, ?color:Int) {
        super(new BufferGeometry(), new LineBasicMaterial({ fog: false }));

        this.light = light;
        this.color = color;
        this.type = 'RectAreaLightHelper';

        var positions:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];
        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.computeBoundingSphere();

        var material:LineBasicMaterial = cast this.material;

        var positions2:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var geometry2:BufferGeometry = new BufferGeometry();
        geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));
        geometry2.computeBoundingSphere();

        var mesh:Mesh = new Mesh(geometry2, new MeshBasicMaterial({ side: Side.BackSide, fog: false }));
        this.add(mesh);
    }

    public override function updateMatrixWorld():Void {
        this.scale.set(0.5 * this.light.width, 0.5 * this.light.height, 1);

        if (this.color != null) {
            this.material.color.set(this.color);
            this.children[0].material.color.set(this.color);
        } else {
            this.material.color.copy(this.light.color).multiplyScalar(this.light.intensity);

            // prevent hue shift
            var c = this.material.color;
            var max:Float = Math.max(c.r, c.g, c.b);
            if (max > 1) c.multiplyScalar(1 / max);

            this.children[0].material.color.copy(this.material.color);
        }

        // ignore world scale on light
        this.matrixWorld.extractRotation(this.light.matrixWorld).scale(this.scale).copyPosition(this.light.matrixWorld);

        this.children[0].matrixWorld.copy(this.matrixWorld);
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
        this.children[0].geometry.dispose();
        this.children[0].material.dispose();
    }
}