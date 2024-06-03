import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.objects.Line;
import three.objects.Mesh;
import three.Three;

class RectAreaLightHelper extends Line {

    public var light:Three.Light;
    public var color:Three.Color;

    public function new(light:Three.Light, color:Three.Color = null) {
        var positions:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];
        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.computeBoundingSphere();
        var material:LineBasicMaterial = new LineBasicMaterial({fog: false});

        super(geometry, material);

        this.light = light;
        this.color = color;
        this.type = 'RectAreaLightHelper';

        var positions2:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var geometry2:BufferGeometry = new BufferGeometry();
        geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));
        geometry2.computeBoundingSphere();

        this.add(new Mesh(geometry2, new MeshBasicMaterial({side: Three.BackSide, fog: false})));
    }

    override public function updateMatrixWorld(force:Bool = false):Void {
        this.scale.set(0.5 * this.light.width, 0.5 * this.light.height, 1);

        if (this.color != null) {
            this.material.color.set(this.color);
            this.children[0].material.color.set(this.color);
        } else {
            this.material.color.copy(this.light.color).multiplyScalar(this.light.intensity);

            var c = this.material.color;
            var max = Math.max(c.r, c.g, c.b);
            if (max > 1) c.multiplyScalar(1 / max);

            this.children[0].material.color.copy(this.material.color);
        }

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