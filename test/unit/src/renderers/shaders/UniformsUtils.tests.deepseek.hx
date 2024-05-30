package three.test.unit.src.renderers.shaders;

import three.src.renderers.shaders.UniformsUtils;
import three.src.math.Color;
import three.src.math.Vector2;
import three.src.math.Vector3;
import three.src.math.Vector4;
import three.src.math.Matrix3;
import three.src.math.Matrix4;
import three.src.math.Quaternion;
import three.src.textures.Texture;
import three.src.constants.CubeReflectionMapping;
import three.src.constants.UVMapping;
import three.utils.console_wrapper.CONSOLE_LEVEL;

class UniformsUtilsTest {

    public static function main() {
        // INSTANCING - LEGACY
        var _ = UniformsUtils;

        // LEGACY
        // QUnit.todo( 'UniformsUtils.clone', ( assert ) => {
        //     assert.ok( false, 'everything\'s gonna be alright' );
        // } );

        // QUnit.todo( 'UniformsUtils.merge', ( assert ) => {
        //     assert.ok( false, 'everything\'s gonna be alright' );
        // } );

        // PUBLIC
        var uniforms = {
            floatValue: { value: 1.23 },
            intValue: { value: 1 },
            boolValue: { value: true },
            colorValue: { value: new Color(0xFF00FF) },
            vector2Value: { value: new Vector2(1, 2) },
            vector3Value: { value: new Vector3(1, 2, 3) },
            vector4Value: { value: new Vector4(1, 2, 3, 4) },
            matrix3Value: { value: new Matrix3() },
            matrix4Value: { value: new Matrix4() },
            quatValue: { value: new Quaternion(1, 2, 3, 4) },
            arrayValue: { value: [1, 2, 3, 4] },
            textureValue: { value: new Texture(null, CubeReflectionMapping) },
        };

        var uniformClones = UniformsUtils.clone(uniforms);

        // assert.ok( uniforms.floatValue.value === uniformClones.floatValue.value );
        // assert.ok( uniforms.intValue.value === uniformClones.intValue.value );
        // assert.ok( uniforms.boolValue.value === uniformClones.boolValue.value );
        // assert.ok( uniforms.colorValue.value.equals(uniformClones.colorValue.value) );
        // assert.ok( uniforms.vector2Value.value.equals(uniformClones.vector2Value.value) );
        // assert.ok( uniforms.vector3Value.value.equals(uniformClones.vector3Value.value) );
        // assert.ok( uniforms.vector4Value.value.equals(uniformClones.vector4Value.value) );
        // assert.ok( uniforms.matrix3Value.value.equals(uniformClones.matrix3Value.value) );
        // assert.ok( uniforms.matrix4Value.value.equals(uniformClones.matrix4Value.value) );
        // assert.ok( uniforms.quatValue.value.equals(uniformClones.quatValue.value) );
        // assert.ok( uniforms.textureValue.value.source.uuid === uniformClones.textureValue.value.source.uuid );
        // assert.ok( uniforms.textureValue.value.mapping === uniformClones.textureValue.value.mapping );
        // for ( var i = 0; i < uniforms.arrayValue.value.length; ++i ) {
        //     assert.ok( uniforms.arrayValue.value[i] === uniformClones.arrayValue.value[i] );
        // }

        // Modify the originals
        // uniforms.floatValue.value = 123.0;
        // uniforms.intValue.value = 123;
        // uniforms.boolValue.value = false;
        // uniforms.colorValue.value.r = 123.0;
        // uniforms.vector2Value.value.x = 123.0;
        // uniforms.vector3Value.value.x = 123.0;
        // uniforms.vector4Value.value.x = 123.0;
        // uniforms.matrix3Value.value.elements[0] = 123.0;
        // uniforms.matrix4Value.value.elements[0] = 123.0;
        // uniforms.quatValue.value.x = 123.0;
        // uniforms.arrayValue.value[0] = 123.0;
        // uniforms.textureValue.value.mapping = UVMapping;

        // assert.ok( uniforms.floatValue.value !== uniformClones.floatValue.value );
        // assert.ok( uniforms.intValue.value !== uniformClones.intValue.value );
        // assert.ok( uniforms.boolValue.value !== uniformClones.boolValue.value );
        // assert.ok( !uniforms.colorValue.value.equals(uniformClones.colorValue.value) );
        // assert.ok( !uniforms.vector2Value.value.equals(uniformClones.vector2Value.value) );
        // assert.ok( !uniforms.vector3Value.value.equals(uniformClones.vector3Value.value) );
        // assert.ok( !uniforms.vector4Value.value.equals(uniformClones.vector4Value.value) );
        // assert.ok( !uniforms.matrix3Value.value.equals(uniformClones.matrix3Value.value) );
        // assert.ok( !uniforms.matrix4Value.value.equals(uniformClones.matrix4Value.value) );
        // assert.ok( !uniforms.quatValue.value.equals(uniformClones.quatValue.value) );
        // assert.ok( uniforms.textureValue.value.mapping !== uniformClones.textureValue.value.mapping );
        // assert.ok( uniforms.arrayValue.value[0] !== uniformClones.arrayValue.value[0] );

        // Texture source remains same
        // assert.ok( uniforms.textureValue.value.source.uuid === uniformClones.textureValue.value.source.uuid );

        // QUnit.test( 'cloneUniforms skips render target textures', ( assert ) => {
        //     const uniforms = {
        //         textureValue: { value: new Texture(null, CubeReflectionMapping) },
        //     };

        //     uniforms.textureValue.value.isRenderTargetTexture = true;

        //     console.level = CONSOLE_LEVEL.OFF;
        //     const uniformClones = UniformsUtils.clone(uniforms);
        //     console.level = CONSOLE_LEVEL.DEFAULT;

        //     assert.ok( uniformClones.textureValue.value === null );
        // } );

        // QUnit.todo( 'mergeUniforms', ( assert ) => {
        //     assert.ok( false, 'everything\'s gonna be alright' );
        // } );

        // QUnit.todo( 'cloneUniformsGroups', ( assert ) => {
        //     assert.ok( false, 'everything\'s gonna be alright' );
        // } );

        // QUnit.todo( 'getUnlitUniformColorSpace', ( assert ) => {
        //     assert.ok( false, 'everything\'s gonna be alright' );
        // } );
    }
}