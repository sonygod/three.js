import js.QUnit.*;
import js.Three.*;

class LODTest {
    static function main() {
        module('Objects', () -> {
            module('LOD', () -> {
                // INHERITANCE
                test('Extending', function() {
                    var lod = new LOD();
                    assert.strictEqual(Type.getInstanceFields(lod).hasOwnProperty('__super__'), true, 'LOD extends from Object3D');
                });

                // PROPERTIES
                test('type', function() {
                    var object = new LOD();
                    assert.strictEqual(object.type, 'LOD', 'LOD.type should be LOD');
                });

                test('levels', function() {
                    var lod = new LOD();
                    var levels = lod.levels;
                    assert.strictEqual(Type.getClass(levels), Array, 'LOD.levels is of type array.');
                    assert.strictEqual(levels.length, 0, 'LOD.levels is empty by default.');
                });

                test('autoUpdate', function() {
                    var lod = new LOD();
                    assert.strictEqual(lod.autoUpdate, true, 'LOD.autoUpdate is of type boolean and true by default.');
                });

                // PUBLIC
                test('isLOD', function() {
                    var lod = new LOD();
                    assert.strictEqual(lod.isLOD, true, '.isLOD property is defined.');
                });

                test('copy', function() {
                    var lod1 = new LOD();
                    var lod2 = new LOD();
                    var high = new Object3D();
                    var mid = new Object3D();
                    var low = new Object3D();
                    lod1.addLevel(high, 5);
                    lod1.addLevel(mid, 25);
                    lod1.addLevel(low, 50);
                    lod1.autoUpdate = false;
                    lod2.copy(lod1);
                    assert.strictEqual(lod2.autoUpdate, false, 'LOD.autoUpdate is correctly copied.');
                    assert.strictEqual(lod2.levels.length, 3, 'LOD.levels has the correct length after the copy.');
                });

                test('addLevel', function() {
                    var lod = new LOD();
                    var high = new Object3D();
                    var mid = new Object3D();
                    var low = new Object3D();
                    lod.addLevel(high, 5, 0.0);
                    lod.addLevel(mid, 25, 0.05);
                    lod.addLevel(low, 50, 0.1);
                    assert.strictEqual(lod.levels.length, 3, 'LOD.levels has the correct length.');
                    assert.deepEqual(lod.levels[0], { distance: 5, object: high, hysteresis: 0.0 }, 'First entry correct.');
                    assert.deepEqual(lod.levels[1], { distance: 25, object: mid, hysteresis: 0.05 }, 'Second entry correct.');
                    assert.deepEqual(lod.levels[2], { distance: 50, object: low, hysteresis: 0.1 }, 'Third entry correct.');
                });

                test('getObjectForDistance', function() {
                    var lod = new LOD();
                    var high = new Object3D();
                    var mid = new Object3D();
                    var low = new Object3D();
                    assert.strictEqual(lod.getObjectForDistance(5), null, 'Returns null if no LOD levels are defined.');
                    lod.addLevel(high, 5);
                    assert.strictEqual(lod.getObjectForDistance(0), high, 'Returns always the same object if only one LOD level is defined.');
                    assert.strictEqual(lod.getObjectForDistance(10), high, 'Returns always the same object if only one LOD level is defined.');
                    lod.addLevel(mid, 25);
                    lod.addLevel(low, 50);
                    assert.strictEqual(lod.getObjectForDistance(0), high, 'Returns the high resolution object.');
                    assert.strictEqual(lod.getObjectForDistance(10), high, 'Returns the high resolution object.');
                    assert.strictEqual(lod.getObjectForDistance(25), mid, 'Returns the mid resolution object.');
                    assert.strictEqual(lod.getObjectForDistance(50), low, 'Returns the low resolution object.');
                    assert.strictEqual(lod.getObjectForDistance(60), low, 'Returns the low resolution object.');
                });

                test('raycast', function() {
                    var lod = new LOD();
                    var raycaster = new Raycaster();
                    var intersections = [];
                    lod.raycast(raycaster, intersections);
                    assert.strictEqual(intersections.length, 0, 'Does not fail if raycasting is used with a LOD object without levels.');
                });
            });
        });
    }
}

// Run the test
LODTest.main();