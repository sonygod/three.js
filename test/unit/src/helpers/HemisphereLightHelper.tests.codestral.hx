// Include the necessary files
@:include('../../../../src/helpers/HemisphereLightHelper.hx')
@:include('../../../../src/core/Object3D.hx')
@:include('../../../../src/lights/HemisphereLight.hx')

class HemisphereLightHelperTests {
    static function main() {
        var parameters = {
            size: 1,
            color: 0xabc012,
            skyColor: 0x123456,
            groundColor: 0xabc012,
            intensity: 0.6
        };

        // INHERITANCE
        // Extending
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        // Haxe does not have an equivalent to JavaScript's strictEqual, so we use == instead
        trace(Std.is(object, Object3D), 'HemisphereLightHelper extends from Object3D');

        // INSTANCING
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        trace(object != null, 'Can instantiate a HemisphereLightHelper.');

        // PROPERTIES
        // type
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        trace(object.type == 'HemisphereLightHelper', 'HemisphereLightHelper.type should be HemisphereLightHelper');

        // PUBLIC
        // dispose
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        object.dispose();
    }
}