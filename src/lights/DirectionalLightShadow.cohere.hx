import LightShadow from './LightShadow.hx';
import OrthographicCamera from '../cameras/OrthographicCamera.hx';

class DirectionalLightShadow extends LightShadow {
	public var isDirectionalLightShadow:Bool = true;

	public function new() {
		super(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
	}
}