package three.js.src.lights;

import three.js.src.lights.LightShadow;
import three.js.src.cameras.OrthographicCamera;

class DirectionalLightShadow extends LightShadow {

    public function new() {
        super(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
        this.isDirectionalLightShadow = true;
    }

}