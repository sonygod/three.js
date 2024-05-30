import three.js.examples.jsm.helpers.RectAreaLightHelper;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperOptions;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperUpdate;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperDispose;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperConstructor;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperUpdateMatrixWorld;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperDisposeGeometry;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperDisposeMaterial;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperDisposeChildrenGeometry;
import three.js.examples.jsm.helpers.RectAreaLightHelper.RectAreaLightHelperDisposeChildrenMaterial;

@:build(RectAreaLightHelper.build())
class RectAreaLightHelper extends Line {

    public var light:Light;
    public var color:Color;
    public var type:String = 'RectAreaLightHelper';

    public function new(light:Light, color:Color, options:RectAreaLightHelperOptions) {
        super();

        var positions:Array<Float> = [ 1, 1, 0, - 1, 1, 0, - 1, - 1, 0, 1, - 1, 0, 1, 1, 0 ];

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.computeBoundingSphere();

        var material:LineBasicMaterial = new LineBasicMaterial({ fog: false });

        super(geometry, material);

        this.light = light;
        this.color = color;

        var positions2:Array<Float> = [ 1, 1, 0, - 1, 1, 0, - 1, - 1, 0, 1, 1, 0, - 1, - 1, 0, 1, - 1, 0 ];

        var geometry2:BufferGeometry = new BufferGeometry();
        geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));
        geometry2.computeBoundingSphere();

        this.add(new Mesh(geometry2, new MeshBasicMaterial({ side: BackSide, fog: false })));
    }

    public function updateMatrixWorld(update:RectAreaLightHelperUpdate) {
        this.scale.set(0.5 * this.light.width, 0.5 * this.light.height, 1);

        if (this.color !== null) {
            this.material.color.set(this.color);
            this.children[0].material.color.set(this.color);
        } else {
            this.material.color.copy(this.light.color).multiplyScalar(this.light.intensity);

            var c:Color = this.material.color;
            var max:Float = Math.max(c.r, c.g, c.b);
            if (max > 1) c.multiplyScalar(1 / max);

            this.children[0].material.color.copy(this.material.color);
        }

        this.matrixWorld.extractRotation(this.light.matrixWorld).scale(this.scale).copyPosition(this.light.matrixWorld);

        this.children[0].matrixWorld.copy(this.matrixWorld);
    }

    public function dispose(dispose:RectAreaLightHelperDispose) {
        this.geometry.dispose();
        this.material.dispose();
        this.children[0].geometry.dispose();
        this.children[0].material.dispose();
    }
}