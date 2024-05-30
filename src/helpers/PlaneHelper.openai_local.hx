import three.objects.Line;
import three.objects.Mesh;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.core.Float32BufferAttribute;
import three.core.BufferGeometry;

class PlaneHelper extends Line {
    public var plane:Dynamic;
    public var size:Float;

    public function new(plane:Dynamic, ?size:Float = 1, ?hex:Int = 0xffff00) {
        var color:Int = hex;

        var positions:Array<Float> = [1, -1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.computeBoundingSphere();

        super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

        this.type = 'PlaneHelper';
        this.plane = plane;
        this.size = size;

        var positions2:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];

        var geometry2:BufferGeometry = new BufferGeometry();
        geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));
        geometry2.computeBoundingSphere();

        this.add(new Mesh(geometry2, new MeshBasicMaterial({color: color, opacity: 0.2, transparent: true, depthWrite: false, toneMapped: false})));
    }

    override public function updateMatrixWorld(force:Bool):Void {
        this.position.set(0, 0, 0);
        this.scale.set(0.5 * this.size, 0.5 * this.size, 1);
        this.lookAt(this.plane.normal);
        this.translateZ(-this.plane.constant);
        super.updateMatrixWorld(force);
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
        cast this.children[0].geometry.dispose();
        cast this.children[0].material.dispose();
    }
}