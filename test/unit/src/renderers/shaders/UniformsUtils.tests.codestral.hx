import qunit.QUnit;
import renderers.shaders.UniformsUtils;
import math.Color;
import math.Vector2;
import math.Vector3;
import math.Vector4;
import math.Matrix3;
import math.Matrix4;
import math.Quaternion;
import textures.Texture;
import constants.CubeReflectionMapping;
import constants.UVMapping;
import utils.ConsoleWrapper;

class UniformsUtilsTests {
    public function new() {
        QUnit.module("Renderers", () -> {
            QUnit.module("Shaders", () -> {
                QUnit.module("UniformsUtils", () -> {
                    QUnit.test("Instancing", (assert) -> {
                        assert.isNotNull(UniformsUtils, "UniformsUtils is defined.");
                    });

                    QUnit.test("cloneUniforms copies values", (assert) -> {
                        var uniforms : Dynamic = {
                            floatValue: {value: 1.23},
                            intValue: {value: 1},
                            boolValue: {value: true},
                            colorValue: {value: new Color(0xFF00FF)},
                            vector2Value: {value: new Vector2(1, 2)},
                            vector3Value: {value: new Vector3(1, 2, 3)},
                            vector4Value: {value: new Vector4(1, 2, 3, 4)},
                            matrix3Value: {value: new Matrix3()},
                            matrix4Value: {value: new Matrix4()},
                            quatValue: {value: new Quaternion(1, 2, 3, 4)},
                            arrayValue: {value: [1, 2, 3, 4]},
                            textureValue: {value: new Texture(null, CubeReflectionMapping)},
                        };

                        var uniformClones = UniformsUtils.clone(uniforms);

                        assert.isTrue(uniforms.floatValue.value == uniformClones.floatValue.value);
                        assert.isTrue(uniforms.intValue.value == uniformClones.intValue.value);
                        assert.isTrue(uniforms.boolValue.value == uniformClones.boolValue.value);
                        assert.isTrue(uniforms.colorValue.value.equals(uniformClones.colorValue.value));
                        assert.isTrue(uniforms.vector2Value.value.equals(uniformClones.vector2Value.value));
                        assert.isTrue(uniforms.vector3Value.value.equals(uniformClones.vector3Value.value));
                        assert.isTrue(uniforms.vector4Value.value.equals(uniformClones.vector4Value.value));
                        assert.isTrue(uniforms.matrix3Value.value.equals(uniformClones.matrix3Value.value));
                        assert.isTrue(uniforms.matrix4Value.value.equals(uniformClones.matrix4Value.value));
                        assert.isTrue(uniforms.quatValue.value.equals(uniformClones.quatValue.value));
                        assert.isTrue(uniforms.textureValue.value.source.uuid == uniformClones.textureValue.value.source.uuid);
                        assert.isTrue(uniforms.textureValue.value.mapping == uniformClones.textureValue.value.mapping);
                        for (i in 0...uniforms.arrayValue.value.length) {
                            assert.isTrue(uniforms.arrayValue.value[i] == uniformClones.arrayValue.value[i]);
                        }
                    });

                    QUnit.test("cloneUniforms clones properties", (assert) -> {
                        var uniforms : Dynamic = {
                            floatValue: {value: 1.23},
                            intValue: {value: 1},
                            boolValue: {value: true},
                            colorValue: {value: new Color(0xFF00FF)},
                            vector2Value: {value: new Vector2(1, 2)},
                            vector3Value: {value: new Vector3(1, 2, 3)},
                            vector4Value: {value: new Vector4(1, 2, 3, 4)},
                            matrix3Value: {value: new Matrix3()},
                            matrix4Value: {value: new Matrix4()},
                            quatValue: {value: new Quaternion(1, 2, 3, 4)},
                            arrayValue: {value: [1, 2, 3, 4]},
                            textureValue: {value: new Texture(null, CubeReflectionMapping)},
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
                        uniforms.textureValue.value.mapping = UVMapping;

                        assert.isTrue(uniforms.floatValue.value != uniformClones.floatValue.value);
                        assert.isTrue(uniforms.intValue.value != uniformClones.intValue.value);
                        assert.isTrue(uniforms.boolValue.value != uniformClones.boolValue.value);
                        assert.isTrue(!uniforms.colorValue.value.equals(uniformClones.colorValue.value));
                        assert.isTrue(!uniforms.vector2Value.value.equals(uniformClones.vector2Value.value));
                        assert.isTrue(!uniforms.vector3Value.value.equals(uniformClones.vector3Value.value));
                        assert.isTrue(!uniforms.vector4Value.value.equals(uniformClones.vector4Value.value));
                        assert.isTrue(!uniforms.matrix3Value.value.equals(uniformClones.matrix3Value.value));
                        assert.isTrue(!uniforms.matrix4Value.value.equals(uniformClones.matrix4Value.value));
                        assert.isTrue(!uniforms.quatValue.value.equals(uniformClones.quatValue.value));
                        assert.isTrue(uniforms.textureValue.value.mapping != uniformClones.textureValue.value.mapping);
                        assert.isTrue(uniforms.arrayValue.value[0] != uniformClones.arrayValue.value[0]);

                        // Texture source remains the same
                        assert.isTrue(uniforms.textureValue.value.source.uuid == uniformClones.textureValue.value.source.uuid);
                    });

                    QUnit.test("cloneUniforms skips render target textures", (assert) -> {
                        var uniforms : Dynamic = {
                            textureValue: {value: new Texture(null, CubeReflectionMapping)},
                        };

                        uniforms.textureValue.value.isRenderTargetTexture = true;

                        ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
                        var uniformClones = UniformsUtils.clone(uniforms);
                        ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;

                        assert.isNull(uniformClones.textureValue.value);
                    });
                });
            });
        });
    }
}