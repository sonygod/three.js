import three.geometries.ExtrudeGeometry;

class TextGeometry extends ExtrudeGeometry {

    public function new(text: String, parameters: Dynamic = null) {
        if (parameters == null) {
            parameters = new Dynamic();
        }

        var font = parameters.font;

        if (font == null) {
            super(); // generate default extrude geometry
        } else {
            var shapes = font.generateShapes(text, parameters.size);

            // translate parameters to ExtrudeGeometry API

            if (parameters.depth == null && parameters.height != null) {
                // console.warn('THREE.TextGeometry: .height is now depreciated. Please use .depth instead'); // @deprecated, r163
            }

            if (parameters.depth == null) {
                parameters.depth = parameters.height != null ? parameters.height : 50;
            }

            // defaults

            if (parameters.bevelThickness == null) {
                parameters.bevelThickness = 10;
            }

            if (parameters.bevelSize == null) {
                parameters.bevelSize = 8;
            }

            if (parameters.bevelEnabled == null) {
                parameters.bevelEnabled = false;
            }

            super(shapes, parameters);
        }

        this.type = 'TextGeometry';
    }
}