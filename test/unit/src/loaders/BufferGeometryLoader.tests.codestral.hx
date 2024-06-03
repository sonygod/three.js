import js.Browser.document;
import js.Boot;

import three.src.loaders.BufferGeometryLoader;
import three.src.core.BufferAttribute;
import three.src.core.BufferGeometry;
import three.src.constants.DynamicDrawUsage;
import three.src.loaders.Loader;

class BufferGeometryLoaderTests {

    public function new() {
        // QUnit.module('Loaders', () => {
        // QUnit.module('BufferGeometryLoader', () => {

        this.testExtending();
        this.testInstancing();
        this.testOthers();

        // });
        // });
    }

    private function testExtending() {
        var object = new BufferGeometryLoader();
        // assert.strictEqual(object.instanceof(Loader), true, 'BufferGeometryLoader extends from Loader');
        js.Boot.trace(Std.is(object, Loader), 'BufferGeometryLoader extends from Loader');
    }

    private function testInstancing() {
        var object = new BufferGeometryLoader();
        // assert.ok(object, 'Can instantiate a BufferGeometryLoader.');
        js.Boot.trace(object != null, 'Can instantiate a BufferGeometryLoader.');
    }

    private function testOthers() {
        var loader = new BufferGeometryLoader();
        var geometry = new BufferGeometry();
        var attr = new BufferAttribute(new js.Float32Array([7, 8, 9, 10, 11, 12]), 2, true);
        attr.name = 'attribute';
        attr.setUsage(DynamicDrawUsage);

        geometry.setAttribute('attr', attr);

        var geometry2 = loader.parse(geometry.toJSON());

        // assert.ok(geometry2.getAttribute('attr'), 'Serialized attribute can be deserialized under the same attribute key.');
        js.Boot.trace(geometry2.getAttribute('attr') != null, 'Serialized attribute can be deserialized under the same attribute key.');

        // assert.deepEqual(geometry.getAttribute('attr'), geometry2.getAttribute('attr'), 'Serialized attribute can be deserialized correctly.');
        js.Boot.trace(geometry.getAttribute('attr') == geometry2.getAttribute('attr'), 'Serialized attribute can be deserialized correctly.');
    }
}


This Haxe code creates a class `BufferGeometryLoaderTests` that contains methods for each of the tests in the JavaScript code. The `testExtending` method tests the inheritance of `BufferGeometryLoader` from `Loader`, the `testInstancing` method tests the ability to instantiate a `BufferGeometryLoader`, and the `testOthers` method tests the functionality of the `parse` method.

Each test method uses the `js.Boot.trace` function to print the result of the test to the console, as Haxe does not have a direct equivalent to JavaScript's `console.log` function. In a real testing scenario, you would replace the `js.Boot.trace` calls with actual assertions.

To run the tests, you would create an instance of the `BufferGeometryLoaderTests` class and call its methods. For example:


var tests = new BufferGeometryLoaderTests();