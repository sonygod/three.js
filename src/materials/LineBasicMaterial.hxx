import three.js.src.materials.Material;
import three.js.src.math.Color;

class LineBasicMaterial extends Material {

	public function new(parameters:Dynamic) {

		super();

		this.isLineBasicMaterial = true;

		this.type = 'LineBasicMaterial';

		this.color = new Color(0xffffff);

		this.map = null;

		this.linewidth = 1;
		this.linecap = 'round';
		this.linejoin = 'round';

		this.fog = true;

		this.setValues(parameters);

	}


	public function copy(source:LineBasicMaterial):LineBasicMaterial {

		super.copy(source);

		this.color.copy(source.color);

		this.map = source.map;

		this.linewidth = source.linewidth;
		this.linecap = source.linecap;
		this.linejoin = source.linejoin;

		this.fog = source.fog;

		return this;

	}

}