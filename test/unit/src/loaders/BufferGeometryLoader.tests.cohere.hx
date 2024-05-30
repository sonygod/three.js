import js.npm.three.loaders.BufferGeometryLoader;
import js.npm.three.core.BufferAttribute;
import js.npm.three.core.BufferGeometry;
import js.npm.three.constants.Usage;
import js.npm.three.loaders.Loader;

class BufferGeometryLoaderTest {
    static function extending() {
        var object = new BufferGeometryLoader();
        trace(Std.is(object, Loader)); // 应该输出 true
    }

    static function instancing() {
        var object = new BufferGeometryLoader();
        trace(object != null); // 应该输出 true
    }

    static function parserAttributesCirclable() {
        var loader = new BufferGeometryLoader();
        var geometry = new BufferGeometry();
        var attr = new BufferAttribute(new Float32Array([7, 8, 9, 10, 11, 12]), 2, true);
        attr.name = 'attribute';
        attr.setUsage(Usage.DynamicDrawUsage);

        geometry.setAttribute('attr', attr);

        var geometry2 = loader.parse(geometry.toJSON());

        trace(geometry2.getAttribute('attr') != null); // 应该输出 true
        trace(geometry.getAttribute('attr') == geometry2.getAttribute('attr')); // 应该输出 true
    }
}