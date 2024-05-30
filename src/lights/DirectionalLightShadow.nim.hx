import LightShadow.LightShadow;
import OrthographicCamera.OrthographicCamera;

class DirectionalLightShadow extends LightShadow {

    public function new() {

        super(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));

        this.isDirectionalLightShadow = true;

    }

}

export class Main {
    public static function main() {
        trace("DirectionalLightShadow class is defined");
    }
}