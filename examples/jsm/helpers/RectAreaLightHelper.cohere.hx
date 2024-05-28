import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.LineBasicMaterial;
import js.three.Mesh;
import js.three.MeshBasicMaterial;

class RectAreaLightHelper extends js.three.Line {
    var light:Dynamic;
    var color:Dynamic;

    public function new(light:Dynamic, color:Dynamic) {
        super();

        var positions = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];
        var geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.computeBoundingSphere();

        var material = new LineBasicMaterial({ fog: false });

        this.light = light;
        this.color = color;
        this.type = 'RectAreaLightHelper';

        this.setGeometry(geometry);
        this.setMaterial(material);

        var positions2 = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var geometry2 = new BufferGeometry();
        geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));
        geometry2.computeBoundingSphere();

        var mesh = new Mesh(geometry2, new MeshBasicMaterial({ side: js.three.BackSide, fog: false }));
        this.add(mesh);
    }

    public function updateMatrixWorld() {
        this.scale.set(0.5 * this.light.width, 0.5 * this.light.height, 1);

        if (this.color != null) {
            this.material.color.set(this.color);
            this.children[0].material.color.set(this.color);
        } else {
            this.material.color.copy(this.light.color).multiplyScalar(this.light.intensity);

            // prevent hue shift
            var c = this.material.color;
            var max = Math.max(c.r, c.g, c.b);
            if (max > 1) c.multiplyScalar(1 / max);

            this.children[0].material.color.copy(this.material.color);
        }

        // ignore world scale on light
        this.matrixWorld.extractRotation(this.light.matrixWorld).scale(this.scale).copyPosition(this.light.matrixWorld);

        this.children[0].matrixWorld.copy(this.matrixWorld);
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
        this.children[0].geometry.dispose();
        this.children[0].material.dispose();
    }
}

class Exports {
    static function RectAreaLightHelper() return RectAreaLightHelper;
}