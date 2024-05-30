package three.loaders;

import haxe.unit.TestCase;
import three.loaders.BufferGeometryLoader;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.constants.DynamicDrawUsage;

class TestBufferGeometryLoader extends TestCase {

    public function new() {
        super();
    }

    public function testExtending() {
        var object = new BufferGeometryLoader();
        assertTrue(object instanceof Loader, 'BufferGeometryLoader extends from Loader');
    }

    public function testInstancing() {
        var object = new BufferGeometryLoader();
        assertNotNull(object, 'Can instantiate a BufferGeometryLoader.');
    }

    public function todoLoad() {
        todo('load', 'everything\'s gonna be alright');
    }

    public function todoParse() {
        todo('parse', 'everything\'s gonna be alright');
    }

    public function testParserAttributesCirclable() {
        var loader = new BufferGeometryLoader();
        var geometry = new BufferGeometry();
        var attr = new BufferAttribute(new haxe.io.Float32Array([7, 8, 9, 10, 11, 12]), 2, true);
        attr.name = 'attribute';
        attr.setUsage(DynamicDrawUsage);

        geometry.setAttribute('attr', attr);

        var geometry2 = loader.parse(geometry.toJSON());

        assertTrue(geometry2.getAttribute('attr') != null, 'Serialized attribute can be deserialized under the same attribute key.');

        assertEquals(geometry.getAttribute('attr'), geometry2.getAttribute('attr'), 'Serialized attribute can be deserialized correctly.');
    }
}