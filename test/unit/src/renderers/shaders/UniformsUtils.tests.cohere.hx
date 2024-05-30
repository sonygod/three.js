import js.QUnit;
import js.renderers.shaders.UniformsUtils;
import js.math.Color;
import js.math.Vector2;
import js.math.Vector3;
import js.math.Vector4;
import js.math.Matrix3;
import js.math.Matrix4;
import js.math.Quaternion;
import js.textures.Texture;
import js.renderers.constants.CubeReflectionMapping;
import js.renderers.constants.UVMapping;
import js.utils.console.ConsoleLevel;

class _Main {
    static function main() {
        QUnit.module('Renderers', function() {
            QUnit.module('Shaders', function() {
                QUnit.module('UniformsUtils', function() {
                    // INSTANCING - LEGACY
                    QUnit.test('Instancing', function(assert) {
                        assert.ok(Std.is(UniformsUtils, UniformsUtils), 'UniformsUtils is defined.');
                    });

                    // LEGACY
                    QUnit.todo('UniformsUtils.clone', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('UniformsUtils.merge', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC
                    QUnit.test('cloneUniforms copies values', function(assert) {
                        var uniforms = {
                            'floatValue': {'value': 1.23},
                            'intValue': {'value': 1},
                            'boolValue': {'value': true},
                            'colorValue': {'value': new Color(0xFF00FF)},
                            'vector2Value': {'value': new Vector2(1, 2)},
                            'vector3Value': {'value': new Vector3(1, 2, 3)},
                            'vector4Value': {'value': new Vector4(1, 2, 3, 4)},
                            'matrix3Value': {'value': new Matrix3()},
                            'matrix4Value': {'value': new Matrix4()},
                            'quatValue': {'value': new Quaternion(1, 2, 3, 4)},
                            'arrayValue': {'value': [1, 2, 3, 4]},
                            'textureValue': {'value': new Texture(null, CubeReflectionMapping.CubeReflectionMapping)}
                        };

                        var uniformClones = UniformsUtils.clone(uniforms);

                        assert.ok(uniforms.floatValue.value == uniformClones.floatValue.value);
                        assert.ok(uniforms.intValue.value == uniformClones.intValue.value);
                        assert.ok(uniforms.boolValue.value == uniformClones.boolValue.value);
                        assert.ok(uniforms.colorValue.value.equals(uniformClones.colorValue.value));
                        assert.ok(uniforms.vector2Value.value.equals(uniformClones.vector2Value.value));
                        assert.ok(uniforms.vector3Value.value.equals(uniformClones.vector3Value.value));
                        assert.ok(uniforms.vector4Value.value.equals(uniformClones.vector4Value.value));
                        assert.ok(uniforms.matrix3Value.value.equals(uniformClones.matrix3Value.value));
                        assert.ok(uniforms.matrix4Value.value.equals(uniformClones.matrix4Value.value));
                        assert.ok(uniforms.quatValue.value.equals(uniformClones.quatValue.value));
                        assert.ok(uniforms.textureValue.value.source.uuid == uniformClones.textureValue.value.source.uuid);
                        assert.ok(uniforms.textureValue.value.mapping == uniformClones.textureValue.value.mapping);
                        for (i in 0...uniforms.arrayValue.value.length) {
                            assert.ok(uniforms.arrayValue.value[i] == uniformClones.arrayValue.value[i]);
                        }
                    });

                    QUnit.test('cloneUniforms clones properties', function(assert) {
                        var uniforms = {
                            'floatValue': {'value': 1.23},
                            'intValue': {'value': 1},
                            'boolValue': {'value': true},
                            'colorValue': {'value': new Color(0xFF00FF)},
                            'vector2Value': {'value': new Vector2(1, 2)},
                            'vector3Value': {'value': new Vector3(1, 2, 3)},
                            'vector4Value': {'value': new Vector4(1, 2, 3, 4)},
                            'matrix3Value': {'value': new Matrix3()},
                            'matrix4Value': {'value': new Matrix4()},
                            'quatValue': {'value': new Quaternion(1, 2, 3, 4)},
                            'arrayValue': {'value': [1, 2, 3, 4]},
                            'textureValue': {'value': new Texture(null, CubeReflectionMapping.CubeReflectionMapping)}
                        };

                        var uniformClones = UniformsUtils.clone(uniforms);

                        // Modify the originals
                        uniforms.floatValue.value = 123.0;
                        uniforms.intValue.value = 123;
                        uniforms.boolValue.value = false;
                        uniforms.colorValue.value.r = 123.0;
                        uniforms.vector2Value.value.x = 123.0;
                        uniforms.vector3Value.value.x = 123.0;
                        uniforms.vector4Value.value.x = 123.0;
                        uniforms.matrix3Value.value.elements[0] = 123.0;
                        uniforms.matrix4Value.value.elements[0] = 123.0;
                        uniforms.quatValue.value.x = 123.0;
                        uniforms.arrayValue.value[0] = 123.0;
                        uniforms.textureValue.value.mapping = UVMapping.UVMapping;

                        assert.ok(uniforms.floatValue.value != uniformClones.floatValue.value);
                        assert.ok(uniforms.intValue.value != uniformClones.intValue.value);
                        assert.ok(uniforms.boolValue.value != uniformClones.boolValue.value);
                        assert.ok(!uniforms.colorValue.value.equals(uniformClones.colorValue.value));
                        assert.ok(!uniforms.vector2Value.value.equals(uniformClones.vector2Value.value));
                        assert.ok(!uniforms.vector3Value.value.equals(uniformClones.vector3Value.value));
                        assert.ok(!uniforms.vector4Value.value.equals(uniformClones.vector4Value.value));
                        assert.ok(!uniforms.matrix3Value.value.equals(uniformClones.matrix3Value.value));
                        assert.ok(!uniforms.matrix4Value.value.equals(uniformClones.matrix4Value.value));
                        assert.ok(!uniforms.quatValue.value.equals(uniformClones.quatValue.value));
                        assert.ok(uniforms.textureValue.value.mapping != uniformClones.textureValue.value.mapping);
                        assert.ok(uniforms.arrayValue.value[0] != uniformClones.arrayValue.value[0]);

                        // Texture source remains same
                        assert.ok(uniforms.textureValue.value.source.uuid == uniformClones.textureValue.value.source.uuid);
                    });

                    QUnit.test('cloneUniforms skips render target textures', function(assert) {
                        var uniforms = {
                            'textureValue': {'value': new Texture(null, CubeReflectionMapping.CubeReflectionMapping)}
                        };

                        uniforms.textureValue.value.isRenderTargetTexture = true;

                        console.level = ConsoleLevel.OFF;
                        var uniformClones = UniformsUtils.clone(uniforms);
                        console.level = ConsoleLevel.DEFAULT;

                        assert.ok(uniformClones.textureValue.value == null);
                    });

                    QUnit.todo('mergeUniforms', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('cloneUniformsGroups', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getUnlitUniformColorSpace', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}