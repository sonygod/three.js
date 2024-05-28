/**
 * Text = 3D Text
 *
 * parameters = {
 *  font: <THREE.Font>, // font
 *
 *  size: <Float>, // size of the text
 *  depth: <Float>, // thickness to extrude text
 *  curveSegments: <Int>, // number of points on the curves
 *
 *  bevelEnabled: <Bool>, // turn on bevel
 *  bevelThickness: <Float>, // how deep into text bevel goes
 *  bevelSize: <Float>, // how far from text outline (including bevelOffset) is bevel
 *  bevelOffset: <Float> // how far from text outline does bevel start
 * }
 */

import js.three.ExtrudeGeometry;

class TextGeometry extends ExtrudeGeometry {
	public function new(text:String, parameters:Dynamic = null) {
		super();

		var font = parameters.font;

		if (font == null) {
			// generate default extrude geometry
		} else {
			var shapes = font.generateShapes(text, parameters.size);

			// translate parameters to ExtrudeGeometry API

			if (parameters.depth == null && parameters.height != null) {
				trace('TextGeometry: .height is now deprecated. Please use .depth instead'); // @deprecated, r163
			}

			parameters.depth = parameters.depth != null ? parameters.depth : parameters.height != null ? parameters.height : 50;

			// defaults

			if (parameters.bevelThickness == null) parameters.bevelThickness = 10;
			if (parameters.bevelSize == null) parameters.bevelSize = 8;
			if (parameters.bevelEnabled == null) parameters.bevelEnabled = false;

			super(shapes, parameters);
		}

		this.type = 'TextGeometry';
	}
}