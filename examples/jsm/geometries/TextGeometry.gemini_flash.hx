import three.extras.geometries.ExtrudeGeometry;
import three.core.Object3D;
import three.core.Geometry;
import three.fonts.Font;

class TextGeometry extends ExtrudeGeometry {

	public function new(text:String, parameters:Dynamic = {}) {
		var font = parameters.font;

		if (font == null) {
			super(); // generate default extrude geometry
		} else {
			var shapes = cast font.generateShapes(text, parameters.size);

			// translate parameters to ExtrudeGeometry API
			if (parameters.depth == null && parameters.height != null) {
				Sys.warning("THREE.TextGeometry: .height is now depreciated. Please use .depth instead"); // @deprecated, r163
			}

			parameters.depth = parameters.depth != null ?
				parameters.depth : parameters.height != null ?
					parameters.height : 50;

			// defaults
			if (parameters.bevelThickness == null) parameters.bevelThickness = 10;
			if (parameters.bevelSize == null) parameters.bevelSize = 8;
			if (parameters.bevelEnabled == null) parameters.bevelEnabled = false;

			super(shapes, parameters);
		}

		this.type = "TextGeometry";
	}
}