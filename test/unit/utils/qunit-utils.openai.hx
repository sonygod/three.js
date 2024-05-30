package three.js.test.unit.utils;

import haxe.unit.Assert;
import js.html.Console;
import three.js.loaders.ObjectLoader;
import three.js.utils.SmartComparer;

using Lambda;

class QUnitUtils {
    public static function success(message:String) {
        Assert.isTrue(true, message);
    }

    public static function fail(message:String) {
        Assert.isTrue(false, message);
    }

    public static function numEqual(actual:Float, expected:Float, message:String) {
        final diff = Math.abs(actual - expected);
        final message = message == null ? '$actual should be equal to $expected' : message;
        Assert.isTrue(diff < 0.1, message);
    }

    public static function equalKey(obj:Dynamic, ref:Dynamic, key:String) {
        final actual = obj[key];
        final expected = ref[key];
        final message = '$actual should be equal to $expected for key "$key"';
        Assert.isTrue(actual == expected, message);
    }

    public static function smartEqual(actual:Dynamic, expected:Dynamic, message:String) {
        final cmp = new SmartComparer();
        final same = cmp.areEqual(actual, expected);
        final msg = cmp.getDiagnostic() ?? message;
        Assert.isTrue(same, msg);
    }

    // GEOMETRY TEST HELPERS

    public static function checkGeometryClone(geom:Dynamic) {
        // Clone
        final copy = geom.clone();
        Assert.areNotEqual(copy.uuid, geom.uuid, 'clone uuid should differ from original');
        Assert.areNotEqual(copy.id, geom.id, 'clone id should differ from original');

        var differingProp:String = getDifferingProp(geom, copy);
        Assert.isNull(differingProp, 'properties are equal');

        differingProp = getDifferingProp(copy, geom);
        Assert.isNull(differingProp, 'properties are equal');

        // json round trip with clone
        checkGeometryJsonRoundtrip(copy);
    }

    static function getDifferingProp(geometryA:Dynamic, geometryB:Dynamic) {
        final geometryKeys = Reflect.fields(geometryA);
        final cloneKeys = Reflect.fields(geometryB);
        var differingProp:String = null;

        for (key in geometryKeys) {
            if (Lambda.has(cloneKeys, key)) {
                // Do nothing
            } else {
                differingProp = key;
                break;
            }
        }

        return differingProp;
    }

    public static function checkGeometryJsonWriting(geom:Dynamic, json:Dynamic) {
        Assert.areEqual(json.metadata.version, '4.6', 'check metadata version');
        equalKey(geom, json, 'type');
        equalKey(geom, json, 'uuid');
        Assert.isNull(json.id, 'should not persist id');

        final params = geom.parameters;
        if (params != null) {
            // All parameters from geometry should be persisted.
            for (key in Reflect.fields(params)) {
                equalKey(params, json, key);
            }

            // All parameters from json should be transfered to the geometry.
            // json is flat. Ignore first level json properties that are not parameters.
            final notParameters = ['metadata', 'uuid', 'type'];
            for (key in Reflect.fields(json)) {
                if (notParameters.indexOf(key) == -1) equalKey(params, json, key);
            }
        }
    }

    public static function checkGeometryJsonReading(json:Dynamic, geom:Dynamic) {
        final wrap = [json];
        final loader = new ObjectLoader();
        final output = loader.parseGeometries(wrap);
        Assert.isTrue(Reflect.hasField(output, geom.uuid), 'geometry matching source uuid not in output');

        var differingProp:String = getDifferingProp(output[geom.uuid], geom);
        Assert.isNull(differingProp, 'properties are equal');

        differingProp = getDifferingProp(geom, output[geom.uuid]);
        Assert.isNull(differingProp, 'properties are equal');
    }

    public static function checkGeometryJsonRoundtrip(geom:Dynamic) {
        final json = geom.toJSON();
        checkGeometryJsonWriting(geom, json);
        checkGeometryJsonReading(json, geom);
    }

    // Run common geometry tests.
    public static function runStdGeometryTests(assert:Assert, geometries:Array<Dynamic>) {
        for (geom in geometries) {
            // Clone
            checkGeometryClone(geom);

            // json round trip
            checkGeometryJsonRoundtrip(geom);
        }
    }

    // LIGHT TEST HELPERS

    public static function runStdLightTests(assert:Assert, lights:Array<Dynamic>) {
        for (light in lights) {
            // copy and clone
            checkLightCopyClone(assert, light);

            // json round trip
            if (light.type != 'Light') {
                checkLightJsonRoundtrip(assert, light);
            }
        }
    }

    public static function checkLightCopyClone(assert:Assert, light:Dynamic) {
        // copy
        final newLight = new light.constructor(0xc0ffee);
        newLight.copy(light);

        Assert.areNotEqual(newLight.uuid, light.uuid, 'Copied light\'s UUID differs from original');
        Assert.areNotEqual(newLight.id, light.id, 'Copied light\'s id differs from original');
        smartEqual(newLight, light, 'Copied light is equal to original');

        // real copy?
        newLight.color.setHex(0xc0ffee);
        Assert.notStrictEqual(newLight.color.getHex(), light.color.getHex(), 'Copied light is independent from original');

        // Clone
        final clone = light.clone(); // better get a new clone
        Assert.areNotEqual(clone.uuid, light.uuid, 'Cloned light\'s UUID differs from original');
        Assert.areNotEqual(clone.id, light.id, 'Clone light\'s id differs from original');
        smartEqual(clone, light, 'Clone light is equal to original');

        // real clone?
        clone.color.setHex(0xc0ffee);
        Assert.notStrictEqual(clone.color.getHex(), light.color.getHex(), 'Clone light is independent from original');

        if (light.type != 'Light') {
            // json round trip with clone
            checkLightJsonRoundtrip(assert, clone);
        }
    }

    public static function checkLightJsonWriting(assert:Assert, light:Dynamic, json:Dynamic) {
        assert.equal(json.metadata.version, '4.6', 'check metadata version');

        final object = json.object;
        equalKey(light, object, 'type');
        equalKey(light, object, 'uuid');
        assert.isNull(object.id, 'should not persist id');
    }

    public static function checkLightJsonReading(assert:Assert, json:Dynamic, light:Dynamic) {
        final loader = new ObjectLoader();
        final outputLight = loader.parse(json);
        smartEqual(outputLight, light, 'Reconstruct Light from ObjectLoader');
    }

    public static function checkLightJsonRoundtrip(assert:Assert, light:Dynamic) {
        final json = light.toJSON();
        checkLightJsonWriting(assert, light, json);
        checkLightJsonReading(assert, json, light);
    }
}