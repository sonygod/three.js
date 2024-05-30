//
// Custom QUnit assertions.
///* global QUnit */

import smartComparer.SmartComparer;
import objectLoader.ObjectLoader;

@:enum(assert)
class Assert {
	public function success(message:String):Void {
		// Equivalent to assert( true, message );
		pushResult({
			result: true,
			actual: null,
			expected: null,
			message: message
		});
	}

	public function fail(message:String):Void {
		// Equivalent to assert( false, message );
		pushResult({
			result: false,
			actual: null,
			expected: null,
			message: message
		});
	}

	public function numEqual(actual:Float, expected:Float, message:String):Void {
		var diff = Math.abs(actual - expected);
		message = message != null ? message : (actual + ' should be equal to ' + expected);
		pushResult({
			result: diff < 0.1,
			actual: actual,
			expected: expected,
			message: message
		});
	}

	public function equalKey(obj:Dynamic, ref:Dynamic, key:String):Void {
		var actual = obj[key];
		var expected = ref[key];
		var message = actual + ' should be equal to ' + expected + ' for key "' + key + '"';
		pushResult({
			result: actual == expected,
			actual: actual,
			expected: expected,
			message: message
		});
	}

	public function smartEqual(actual:Dynamic, expected:Dynamic, message:String):Void {
		var cmp = new SmartComparer();
		var same = cmp.areEqual(actual, expected);
		var msg = cmp.getDiagnostic() != null ? cmp.getDiagnostic() : message;
		pushResult({
			result: same,
			actual: actual,
			expected: expected,
			message: msg
		});
	}
}

//
//	GEOMETRY TEST HELPERS
//

function checkGeometryClone(geom:Dynamic):Void {
	// Clone
	var copy = geom.clone();
	QUnit.assert.notEqual(copy.uuid, geom.uuid, 'clone uuid should differ from original');
	QUnit.assert.notEqual(copy.id, geom.id, 'clone id should differ from original');

	var differingProp = getDifferingProp(geom, copy);
	QUnit.assert.ok(differingProp == null, 'properties are equal');

	differingProp = getDifferingProp(copy, geom);
	QUnit.assert.ok(differingProp == null, 'properties are equal');

	// json round trip with clone
	checkGeometryJsonRoundtrip(copy);
}

function getDifferingProp(geometryA:Dynamic, geometryB:Dynamic):Dynamic {
	var geometryKeys = Reflect.fields(geometryA);
	var cloneKeys = Reflect.fields(geometryB);

	var differingProp:Dynamic = null;

	for (key in geometryKeys) {
		if (cloneKeys.indexOf(key) < 0) {
			differingProp = key;
			break;
		}
	}

	return differingProp;
}

// Compare json file with its source geometry.
function checkGeometryJsonWriting(geom:Dynamic, json:Dynamic):Void {
	QUnit.assert.equal(json.metadata.version, '4.6', 'check metadata version');
	QUnit.assert.equalKey(geom, json, 'type');
	QUnit.assert.equalKey(geom, json, 'uuid');
	QUnit.assert.equal(json.id, null, 'should not persist id');

	var params = geom.parameters;
	if (params == null) {
		return;
	}

	// All parameters from geometry should be persisted.
	var keys:Array<String> = Reflect.fields(params);
	for (key in keys) {
		QUnit.assert.equalKey(params, json, keys[key]);
	}

	// All parameters from json should be transferred to the geometry.
	// json is flat. Ignore first level json properties that are not parameters.
	var notParameters:Array<String> = ['metadata', 'uuid', 'type'];
	keys = Reflect.fields(json);
	for (key in keys) {
		if (notParameters.indexOf(key) == -1) {
			QUnit.assert.equalKey(params, json, key);
		}
	}
}

// Check parsing and reconstruction of json geometry
function checkGeometryJsonReading(json:Dynamic, geom:Dynamic):Void {
	var wrap:Array<Dynamic> = [json];

	var loader = new ObjectLoader();
	var output = loader.parseGeometries(wrap);

	QUnit.assert.ok(output[geom.uuid] != null, 'geometry matching source uuid not in output');
	// QUnit.assert.smartEqual( output[ geom.uuid ], geom, 'Reconstruct geometry from ObjectLoader' );

	var differing = getDifferingProp(output[geom.uuid], geom);
	if (differing != null) {
		trace(differing);
	}

	var differingProp = getDifferingProp(output[geom.uuid], geom);
	QUnit.assert.ok(differingProp == null, 'properties are equal');

	differingProp = getDifferingProp(geom, output[geom.uuid]);
	QUnit.assert.ok(differingProp == null, 'properties are equal');
}

// Verify geom -> json -> geom
function checkGeometryJsonRoundtrip(geom:Dynamic):Void {
	var json = geom.toJSON();
	checkGeometryJsonWriting(geom, json);
	checkGeometryJsonReading(json, geom);
}


// Run common geometry tests.
function runStdGeometryTests(assert:Assert, geometries:Array<Dynamic>):Void {
	for (geom in geometries) {
		// Clone
		checkGeometryClone(geom);

		// json round trip
		checkGeometryJsonRoundtrip(geom);
	}
}

//
//	LIGHT TEST HELPERS
//

// Run common light tests.
function runStdLightTests(assert:Assert, lights:Array<Dynamic>):Void {
	for (light in lights) {
		// copy and clone
		checkLightCopyClone(assert, light);

		// THREE.Light doesn't get parsed by ObjectLoader as it's only
		// used as an abstract base class - so we skip the JSON tests
		if (light.type != 'Light') {
			// json round trip
			checkLightJsonRoundtrip(assert, light);
		}
	}
}

function checkLightCopyClone(assert:Assert, light:Dynamic):Void {
	// copy
	var newLight = new light.constructor(0xc0ffee);
	newLight.copy(light);

	QUnit.assert.notEqual(newLight.uuid, light.uuid, 'Copied light\'s UUID differs from original');
	QUnit.assert.notEqual(newLight.id, light.id, 'Copied light\'s id differs from original');
	QUnit.assert.smartEqual(newLight, light, 'Copied light is equal to original');

	// real copy?
	newLight.color.setHex(0xc0ffee);
	QUnit.assert.notStrictEqual(
		newLight.color.getHex(), light.color.getHex(), 'Copied light is independent from original'
	);

	// Clone
	var clone = light.clone(); // better get a new clone
	QUnit.assert.notEqual(clone.uuid, light.uuid, 'Cloned light\'s UUID differs from original');
	QUnit.assert.notEqual(clone.id, light.id, 'Clone light\'s id differs from original');
	QUnit.assert.smartEqual(clone, light, 'Clone light is equal to original');

	// real clone?
	clone.color.setHex(0xc0ffee);
	QUnit.assert.notStrictEqual(
		clone.color.getHex(), light.color.getHex(), 'Clone light is independent from original'
	);

	if (light.type != 'Light') {
		// json round trip with clone
		checkLightJsonRoundtrip(assert, clone);
	}
}

// Compare json file with its source Light.
function checkLightJsonWriting(assert:Assert, light:Dynamic, json:Dynamic):Void {
	assert.equal(json.metadata.version, '4.6', 'check metadata version');

	var object = json.object;
	assert.equalKey(light, object, 'type');
	assert.equalKey(light, object, 'uuid');
	assert.equal(object.id, null, 'should not persist id');
}

// Check parsing and reconstruction of json Light
function checkLightJsonReading(assert:Assert, json:Dynamic, light:Dynamic):Void {
	var loader = new ObjectLoader();
	var outputLight = loader.parse(json);

	assert.smartEqual(outputLight, light, 'Reconstruct Light from ObjectLoader');
}

// Verify light -> json -> light
function checkLightJsonRoundtrip(assert:Assert, light:Dynamic):Void {
	var json = light.toJSON();
	checkLightJsonWriting(assert, light, json);
	checkLightJsonReading(assert, json, light);
}

@:export
class TestHelpers {
	public static function runStdLightTests(assert:Assert, lights:Array<Dynamic>):Void {
		runStdLightTests(assert, lights);
	}

	public static function runStdGeometryTests(assert:Assert, geometries:Array<Dynamic>):Void {
		runStdGeometryTests(assert, geometries);
	}
}