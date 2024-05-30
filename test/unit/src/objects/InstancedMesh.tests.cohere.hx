import js.QUnit;

import js.three.objects.InstancedMesh;
import js.three.objects.Mesh;

class _InstancedMeshTest {
    static function extending() {
        var object = new InstancedMesh();
        var assert = QUnit.test(object, 'Extending');
        assert.strictEqual(object instanceof Mesh, true, 'InstancedMesh extends from Mesh');
    }

    static function instancing() {
        var object = new InstancedMesh();
        var assert = QUnit.test(object, 'Instancing');
        assert.ok(object, 'Can instantiate a InstancedMesh.');
    }

    static function isInstancedMesh() {
        var object = new InstancedMesh();
        var assert = QUnit.test(object, 'isInstancedMesh');
        assert.ok(object.isInstancedMesh, 'InstancedMesh.isInstancedMesh should be true');
    }

    static function dispose() {
        var assert = QUnit.test('dispose', null);
        assert.expect(0);
        var object = new InstancedMesh();
        object.dispose();
    }
}

QUnit.module('Objects', {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.module('InstancedMesh', {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.test('Extending', _InstancedMeshTest.extending);
QUnit.test('Instancing', _InstancedMeshTest.instancing);
QUnit.test('isInstancedMesh', _InstancedMeshTest.isInstancedMesh);
QUnit.test('dispose', _InstancedMeshTest.dispose);