import js.Browser.document;
import js.html.CanvasElement;
import js.html.WebGLRenderingContext;
import three.math.Vector3;
import three.core.Object3D;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;

class SpotLightHelper extends Object3D {

    public var light:Light;
    public var cone:LineSegments;
    public var color:Int;

    public function new(light:Light, color:Int) {
        super();

        this.light = light;
        this.matrixAutoUpdate = false;
        this.color = color;
        this.type = 'SpotLightHelper';

        var geometry:BufferGeometry = new BufferGeometry();
        var positions:Array<Float> = [
            0.0, 0.0, 0.0, 0.0, 0.0, 1.0,
            0.0, 0.0, 0.0, 1.0, 0.0, 1.0,
            0.0, 0.0, 0.0, -1.0, 0.0, 1.0,
            0.0, 0.0, 0.0, 0.0, 1.0, 1.0,
            0.0, 0.0, 0.0, 0.0, -1.0, 1.0
        ];

        for (var i:Int = 0, j:Int = 1, l:Int = 32; i < l; i++, j++) {
            var p1:Float = (i / l) * Math.PI * 2.0;
            var p2:Float = (j / l) * Math.PI * 2.0;

            positions.push(
                Math.cos(p1), Math.sin(p1), 1.0,
                Math.cos(p2), Math.sin(p2), 1.0
            );
        }

        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        var material:LineBasicMaterial = new LineBasicMaterial({fog: false, toneMapped: false});

        this.cone = new LineSegments(geometry, material);
        this.add(this.cone);

        this.update();
    }

    public function dispose():Void {
        this.cone.geometry.dispose();
        this.cone.material.dispose();
    }

    public function update():Void {
        this.light.updateWorldMatrix(true, false);
        this.light.target.updateWorldMatrix(true, false);

        if (this.parent != null) {
            this.parent.updateWorldMatrix(true);
            this.matrix.copy(this.parent.matrixWorld).invert().multiply(this.light.matrixWorld);
        } else {
            this.matrix.copy(this.light.matrixWorld);
        }

        this.matrixWorld.copy(this.light.matrixWorld);

        var coneLength:Float = this.light.distance != null ? this.light.distance : 1000.0;
        var coneWidth:Float = coneLength * Math.tan(this.light.angle);

        this.cone.scale.set(coneWidth, coneWidth, coneLength);

        var _vector:Vector3 = new Vector3();
        _vector.setFromMatrixPosition(this.light.target.matrixWorld);

        this.cone.lookAt(_vector);

        if (this.color != null) {
            this.cone.material.color.set(this.color);
        } else {
            this.cone.material.color.copy(this.light.color);
        }
    }
}