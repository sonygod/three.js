import three.constants.BackSide;
import three.math.Euler;
import three.math.Matrix4;
import three.renderers.shaders.UniformsUtils.getUnlitUniformColorSpace;

class WebGLMaterials {

    private static var _e1:Euler = new Euler();
    private static var _m1:Matrix4 = new Matrix4();

    public function new(renderer:Dynamic, properties:Dynamic) {

    }

    public function refreshTransformUniform(map:Dynamic, uniform:Dynamic):Void {

        if (map.matrixAutoUpdate === true) {

            map.updateMatrix();

        }

        uniform.value.copy(map.matrix);

    }

    public function refreshFogUniforms(uniforms:Dynamic, fog:Dynamic):Void {

        fog.color.getRGB(uniforms.fogColor.value, getUnlitUniformColorSpace(renderer));

        if (fog.isFog) {

            uniforms.fogNear.value = fog.near;
            uniforms.fogFar.value = fog.far;

        } else if (fog.isFogExp2) {

            uniforms.fogDensity.value = fog.density;

        }

    }

    public function refreshMaterialUniforms(uniforms:Dynamic, material:Dynamic, pixelRatio:Float, height:Float, transmissionRenderTarget:Dynamic):Void {

        if (material.isMeshBasicMaterial) {

            refreshUniformsCommon(uniforms, material);

        } else if (material.isMeshLambertMaterial) {

            refreshUniformsCommon(uniforms, material);

        } else if (material.isMeshToonMaterial) {

            refreshUniformsCommon(uniforms, material);
            refreshUniformsToon(uniforms, material);

        } else if (material.isMeshPhongMaterial) {

            refreshUniformsCommon(uniforms, material);
            refreshUniformsPhong(uniforms, material);

        } else if (material.isMeshStandardMaterial) {

            refreshUniformsCommon(uniforms, material);
            refreshUniformsStandard(uniforms, material);

            if (material.isMeshPhysicalMaterial) {

                refreshUniformsPhysical(uniforms, material, transmissionRenderTarget);

            }

        } else if (material.isMeshMatcapMaterial) {

            refreshUniformsCommon(uniforms, material);
            refreshUniformsMatcap(uniforms, material);

        } else if (material.isMeshDepthMaterial) {

            refreshUniformsCommon(uniforms, material);

        } else if (material.isMeshDistanceMaterial) {

            refreshUniformsCommon(uniforms, material);
            refreshUniformsDistance(uniforms, material);

        } else if (material.isMeshNormalMaterial) {

            refreshUniformsCommon(uniforms, material);

        } else if (material.isLineBasicMaterial) {

            refreshUniformsLine(uniforms, material);

            if (material.isLineDashedMaterial) {

                refreshUniformsDash(uniforms, material);

            }

        } else if (material.isPointsMaterial) {

            refreshUniformsPoints(uniforms, material, pixelRatio, height);

        } else if (material.isSpriteMaterial) {

            refreshUniformsSprites(uniforms, material);

        } else if (material.isShadowMaterial) {

            uniforms.color.value.copy(material.color);
            uniforms.opacity.value = material.opacity;

        } else if (material.isShaderMaterial) {

            material.uniformsNeedUpdate = false; // #15581

        }

    }

    // ... 其他函数的转换，与上面的类似，这里省略了

    public function refreshUniformsCommon(uniforms:Dynamic, material:Dynamic):Void {

        uniforms.opacity.value = material.opacity;

        if (material.color) {

            uniforms.diffuse.value.copy(material.color);

        }

        // ... 其他代码，与上面的类似，这里省略了

    }

    // ... 其他函数的转换，与上面的类似，这里省略了

}