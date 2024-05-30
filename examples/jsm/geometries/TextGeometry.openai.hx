package three.js.geomtries;

import three.js.geometries.ExtrudeGeometry;

/**
 * Text = 3D Text
 *
 * parameters = {
 *  font: Font, // font
 *
 *  size: Float, // size of the text
 *  depth: Float, // thickness to extrude text
 *  curveSegments: Int, // number of points on the curves
 *
 *  bevelEnabled: Bool, // turn on bevel
 *  bevelThickness: Float, // how deep into text bevel goes
 *  bevelSize: Float, // how far from text outline (including bevelOffset) is bevel
 *  bevelOffset: Float // how far from text outline does bevel start
 * }
 */

class TextGeometry extends ExtrudeGeometry {

    public function new(text:String, ?parameters:Dynamic = null) {
        var font:Font = parameters.font;

        if (font == null) {
            super(); // generate default extrude geometry
        } else {
            var shapes:Array<Dynamic> = font.generateShapes(text, parameters.size);

            // translate parameters to ExtrudeGeometry API

            if (parameters.depth == null && parameters.height != null) {
                // @deprecated, r163
                trace("THREE.TextGeometry: .height is now depreciated. Please use .depth instead");
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

#else
// We need to export the class for other modules to use
@:expose
class TextGeometry extends ExtrudeGeometry {
    // ...
}
#end