import three.js.src.materials.Material;
import three.js.src.math.Color;

class PointsMaterial extends Material {

	public function new(parameters:Dynamic) {

		super();

		this.isPointsMaterial = true;

		this.type = 'PointsMaterial';

		this.color = new Color(0xffffff);

		this.map = null;

		this.alphaMap = null;

		this.size = 1;
		this.sizeAttenuation = true;

		this.fog = true;

		this.setValues(parameters);

	}

	public function copy(source:PointsMaterial):PointsMaterial {

		super.copy(source);

		this.color.copy(source.color);

		this.map = source.map;

		this.alphaMap = source.alphaMap;

		this.size = source.size;
		this.sizeAttenuation = source.sizeAttenuation;

		this.fog = source.fog;

		return this;

	}

}