import three.lights.LightShadow;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class SpotLightShadow extends LightShadow {

    public var focus:Float;

    public function new() {
        super(new PerspectiveCamera(50, 1, 0.5, 500));
        this.isSpotLightShadow = true;
        this.focus = 1;
    }

    public function updateMatrices(light:Dynamic) {
        var camera:PerspectiveCamera = this.camera;

        var fov:Float = MathUtils.RAD2DEG * 2 * light.angle * this.focus;
        var aspect:Float = this.mapSize.width / this.mapSize.height;
        var far:Float = light.distance != null ? light.distance : camera.far;

        if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {
            camera.fov = fov;
            camera.aspect = aspect;
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        super.updateMatrices(light);
    }

    public function copy(source:SpotLightShadow):SpotLightShadow {
        super.copy(source);
        this.focus = source.focus;
        return this;
    }
}