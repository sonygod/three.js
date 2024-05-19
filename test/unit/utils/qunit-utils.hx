package three.test.unit.utils;

import haxe.unit.Assert;
import three.loaders.ObjectLoader;
import three.utils.SmartComparer;

class QUnitUtils {
  public static function assertSuccess(message:String) {
    Assert.isTrue(true, message);
  }

  public static function assertFail(message:String) {
    Assert.fail(message);
  }

  public static function assertNumEqual(actual:Float, expected:Float, message:String) {
    var diff = Math.abs(actual - expected);
    Assert.isTrue(diff < 0.1, (message != null ? message : '${actual} should be equal to ${expected}'));
  }

  public static function assertEqualKey(obj:Dynamic, ref:Dynamic, key:String) {
    var actual = obj[key];
    var expected = ref[key];
    Assert.areEqual(actual, expected, '${actual} should be equal to ${expected} for key "${key}"');
  }

  public static function assertSmartEqual(actual:Dynamic, expected:Dynamic, message:String) {
    var cmp = new SmartComparer();
    var same = cmp.areEqual(actual, expected);
    var msg = cmp.getDiagnostic() || message;
    Assert.isTrue(same, msg);
  }

  // GEOMETRY TEST HELPERS

  public static function checkGeometryClone(geom:Dynamic) {
    // Clone
    var copy = geom.clone();
    Assert.notEqual(copy.uuid, geom.uuid, 'clone uuid should differ from original');
    Assert.notEqual(copy.id, geom.id, 'clone id should differ from original');

    var differingProp = getDifferingProp(geom, copy);
    Assert.isNull(differingProp, 'properties are equal');

    differingProp = getDifferingProp(copy, geom);
    Assert.isNull(differingProp, 'properties are equal');

    // json round trip with clone
    checkGeometryJsonRoundtrip(copy);
  }

  private static function getDifferingProp(geometryA:Dynamic, geometryB:Dynamic) {
    var geometryKeys = Reflect.fields(geometryA);
    var cloneKeys = Reflect.fields(geometryB);
    var differingProp:Null<String> = null;

    for (key in geometryKeys) {
      if (cloneKeys.indexOf(key) < 0) {
        differingProp = key;
        break;
      }
    }

    return differingProp;
  }

  // Compare json file with its source geometry.
  public static function checkGeometryJsonWriting(geom:Dynamic, json:Dynamic) {
    Assert.areEqual(json.metadata.version, '4.6', 'check metadata version');
    assertEqualKey(geom, json, 'type');
    assertEqualKey(geom, json, 'uuid');
    Assert.isNull(json.id, 'should not persist id');

    var params = geom.parameters;
    if (params != null) {
      // All parameters from geometry should be persisted.
      var keys = Reflect.fields(params);
      for (key in keys) {
        assertEqualKey(params, json, key);
      }

      // All parameters from json should be transfered to the geometry.
      // json is flat. Ignore first level json properties that are not parameters.
      var notParameters = ['metadata', 'uuid', 'type'];
      keys = Reflect.fields(json);
      for (key in keys) {
        if (notParameters.indexOf(key) == -1) assertEqualKey(params, json, key);
      }
    }
  }

  // Check parsing and reconstruction of json geometry
  public static function checkGeometryJsonReading(json:Dynamic, geom:Dynamic) {
    var loader = new ObjectLoader();
    var output = loader.parseGeometries([json]);

    Assert.isTrue(Reflect.hasField(output, geom.uuid), 'geometry matching source uuid not in output');
    // Assert.smartEqual(output[geom.uuid], geom, 'Reconstruct geometry from ObjectLoader');

    var differingProp = getDifferingProp(output[geom.uuid], geom);
    Assert.isNull(differingProp, 'properties are equal');

    differingProp = getDifferingProp(geom, output[geom.uuid]);
    Assert.isNull(differingProp, 'properties are equal');
  }

  // Verify geom -> json -> geom
  public static function checkGeometryJsonRoundtrip(geom:Dynamic) {
    var json = geom.toJSON();
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

  // Run common light tests.
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
    var newLight = new light.constructor(0xc0ffee);
    newLight.copy(light);

    Assert.notEqual(newLight.uuid, light.uuid, 'Copied light\'s UUID differs from original');
    Assert.notEqual(newLight.id, light.id, 'Copied light\'s id differs from original');
    assertSmartEqual(newLight, light, 'Copied light is equal to original');

    // real copy?
    newLight.color.setHex(0xc0ffee);
    Assert.notStrictEqual(newLight.color.getHex(), light.color.getHex(), 'Copied light is independent from original');

    // Clone
    var clone = light.clone(); // better get a new clone
    Assert.notEqual(clone.uuid, light.uuid, 'Cloned light\'s UUID differs from original');
    Assert.notEqual(clone.id, light.id, 'Clone light\'s id differs from original');
    assertSmartEqual(clone, light, 'Clone light is equal to original');

    // real clone?
    clone.color.setHex(0xc0ffee);
    Assert.notStrictEqual(clone.color.getHex(), light.color.getHex(), 'Clone light is independent from original');

    if (light.type != 'Light') {
      // json round trip with clone
      checkLightJsonRoundtrip(assert, clone);
    }
  }

  // Compare json file with its source Light.
  public static function checkLightJsonWriting(assert:Assert, light:Dynamic, json:Dynamic) {
    Assert.areEqual(json.metadata.version, '4.6', 'check metadata version');

    var object = json.object;
    assertEqualKey(light, object, 'type');
    assertEqualKey(light, object, 'uuid');
    Assert.isNull(object.id, 'should not persist id');
  }

  // Check parsing and reconstruction of json Light
  public static function checkLightJsonReading(assert:Assert, json:Dynamic, light:Dynamic) {
    var loader = new ObjectLoader();
    var outputLight = loader.parse(json);

    assertSmartEqual(outputLight, light, 'Reconstruct Light from ObjectLoader');
  }

  // Verify light -> json -> light
  public static function checkLightJsonRoundtrip(assert:Assert, light:Dynamic) {
    var json = light.toJSON();
    checkLightJsonWriting(assert, light, json);
    checkLightJsonReading(assert, json, light);
  }
}