package;

import three.js.test.unit.src.loaders.BufferGeometryLoader;
import three.js.test.unit.src.core.BufferAttribute;
import three.js.test.unit.src.core.BufferGeometry;
import three.js.test.unit.src.constants.DynamicDrawUsage;
import three.js.test.unit.src.loaders.Loader;

class Main {
    static function main() {
        // INHERITANCE
        var object = new BufferGeometryLoader();
        unittest.assert(object instanceof Loader);

        // INSTANCING
        var object = new BufferGeometryLoader();
        unittest.assert(object != null);

        // PUBLIC
        unittest.todo("load");
        unittest.todo("parse");

        // OTHERS
        var loader = new BufferGeometryLoader();
        var geometry = new BufferGeometry();
        var attr = new BufferAttribute(new Float32Array([7, 8, 9, 10, 11, 12]), 2, true);
        attr.name = 'attribute';
        attr.setUsage(DynamicDrawUsage);

        geometry.setAttribute('attr', attr);

        var geometry2 = loader.parse(geometry.toJSON());

        unittest.assert(geometry2.getAttribute('attr') != null);
        unittest.assert(geometry.getAttribute('attr') == geometry2.getAttribute('attr'));
    }
}