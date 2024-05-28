import MathUtils from "../math/MathUtils";
import PerspectiveCamera from "../cameras/PerspectiveCamera";
import LightShadow from "./LightShadow";

class SpotLightShadow extends LightShadow {
    public isSpotLightShadow: Bool = true;
    public focus: Float;

    public function new() {
        super(new PerspectiveCamera(50, 1, 0.5, 500));
        this.isSpotLightShadow = true;
        this.focus = 1;
    }

    public function updateMatrices(light: { angle: Float, distance: Float }) {
        var camera = this.camera;
        var fov = MathUtils.RAD2DEG * 2 * light.angle * this.focus;
        var aspect = this.mapSize.width / this.mapSize.height;
        var far = light.distance ?? camera.far;

        if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {
            camera.fov = fov;
            camera.aspect = aspect;
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        super.updateMatrices(light);
    }

    public function copy(source: SpotLightShadow): SpotLightShadow {
        super.copy(source);
        this.focus = source.focus;
        return this;
    }
}