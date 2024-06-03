import js.Browser.document;
import js.html.QUnit;
import three.src.core.InstancedBufferGeometry;
import three.src.core.BufferGeometry;
import three.src.core.BufferAttribute;

class InstancedBufferGeometryTests {

    public static function main() {
        QUnit.module("Core", () -> {
            QUnit.module("InstancedBufferGeometry", () -> {

                function createClonableMock():Dynamic {
                    return {
                        callCount: 0,
                        clone: function():Dynamic {
                            this.callCount++;
                            return this;
                        }
                    };
                }

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new InstancedBufferGeometry();
                    assert.strictEqual(Std.is(object, BufferGeometry), true, "InstancedBufferGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new InstancedBufferGeometry();
                    assert.ok(object, "Can instantiate an InstancedBufferGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new InstancedBufferGeometry();
                    assert.ok(object.type == "InstancedBufferGeometry", "InstancedBufferGeometry.type should be InstancedBufferGeometry");
                });

                // PUBLIC
                QUnit.test("isInstancedBufferGeometry", (assert) -> {
                    var object = new InstancedBufferGeometry();
                    assert.ok(object.isInstancedBufferGeometry, "InstancedBufferGeometry.isInstancedBufferGeometry should be true");
                });

                QUnit.test("copy", (assert) -> {
                    var instanceMock1:Dynamic = {};
                    var instanceMock2:Dynamic = {};
                    var indexMock = createClonableMock();
                    var defaultAttribute1 = new BufferAttribute(new Float32Array([1]));
                    var defaultAttribute2 = new BufferAttribute(new Float32Array([2]));

                    var instance = new InstancedBufferGeometry();

                    instance.addGroup(0, 10, instanceMock1);
                    instance.addGroup(10, 5, instanceMock2);
                    instance.setIndex(indexMock);
                    instance.setAttribute("defaultAttribute1", defaultAttribute1);
                    instance.setAttribute("defaultAttribute2", defaultAttribute2);

                    var copiedInstance = new InstancedBufferGeometry().copy(instance);

                    assert.ok(Std.is(copiedInstance, InstancedBufferGeometry), "the clone has the correct type");
                    assert.equal(copiedInstance.index, indexMock, "index was copied");
                    assert.equal(copiedInstance.index.callCount, 1, "index.clone was called once");
                    assert.ok(Std.is(copiedInstance.attributes["defaultAttribute1"], BufferAttribute), "attribute was created");
                    assert.deepEqual(copiedInstance.attributes["defaultAttribute1"].array, defaultAttribute1.array, "attribute was copied");
                    assert.deepEqual(copiedInstance.attributes["defaultAttribute2"].array, defaultAttribute2.array, "attribute was copied");
                    assert.equal(copiedInstance.groups[0].start, 0, "group was copied");
                    assert.equal(copiedInstance.groups[0].count, 10, "group was copied");
                    assert.equal(copiedInstance.groups[0].materialIndex, instanceMock1, "group was copied");
                    assert.equal(copiedInstance.groups[1].start, 10, "group was copied");
                    assert.equal(copiedInstance.groups[1].count, 5, "group was copied");
                    assert.equal(copiedInstance.groups[1].materialIndex, instanceMock2, "group was copied");
                });
            });
        });
    }
}