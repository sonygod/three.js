import LightShadow.LightShadow;
import MathUtils.MathUtils;
import PerspectiveCamera.PerspectiveCamera;

class SpotLightShadow extends LightShadow {

    public var isSpotLightShadow:Bool = true;
    public var focus:Float = 1;

    public function new() {
        super(new PerspectiveCamera(50, 1, 0.5, 500));
    }

    public function updateMatrices(light) {
        var camera = this.camera;

        var fov = MathUtils.RAD2DEG * 2 * light.angle * this.focus;
        var aspect = this.mapSize.width / this.mapSize.height;
        var far = light.distance || camera.far;

        if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {
            camera.fov = fov;
            camera.aspect = aspect;
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        super.updateMatrices(light);
    }

    public function copy(source) {
        super.copy(source);

        this.focus = source.focus;

        return this;
    }

}

export class SpotLightShadow;