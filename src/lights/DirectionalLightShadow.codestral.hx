import three.lights.LightShadow;
import three.cameras.OrthographicCamera;

class DirectionalLightShadow extends LightShadow {

    public function new() {
        super(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
        this.isDirectionalLightShadow = true;
    }
}