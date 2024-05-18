package three.js.examples.jm.geometries;

import three.js.ExtrudeGeometry;

class TextGeometry extends ExtrudeGeometry {
    public function new(text:String, parameters:TextGeometryParameters = null) {
        var font:Font = parameters.font;

        if (font == null) {
            super(); // generate default extrude geometry
        } else {
            var shapes:Array<Shape> = font.generateShapes(text, parameters.size);

            // translate parameters to ExtrudeGeometry API

            if (parameters.depth == null && parameters.height != null) {
                trace("THREE.TextGeometry: .height is now depreciated. Please use .depth instead"); // @deprecated, r163
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

typedef TextGeometryParameters = {
    var font:Font;
    var size:Float;
    var depth:Float;
    var curveSegments:Int;
    var bevelEnabled:Bool;
    var bevelThickness:Float;
    var bevelSize:Float;
    var bevelOffset:Float;
}

// export the class
extern class TextGeometry {}