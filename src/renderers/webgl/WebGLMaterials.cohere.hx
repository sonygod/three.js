import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.LoaderInfo;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.errors.Error;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.events.ProgressEvent;
import openfl.events.RenderEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TextEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.events.VideoEvent;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.media.Camera;
import openfl.media.Microphone;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.system.ApplicationDomain;
import openfl.system.LoaderContext;
import openfl.system.Security;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetLibraryItem;
import openfl.utils.ByteArray;
import openfl.utils.Dictionary;
import openfl.utils.getTimer;
import openfl.utils.getQualifiedClassName;

class WebGLMaterials {
    public function new(renderer:Renderer, properties:Map<Material,MaterialProperties>) {
        function refreshTransformUniform(map:Texture, uniform:Uniform) {
            if (map.matrixAutoUpdate) {
                map.updateMatrix();
            }
            uniform.value.copy(map.matrix);
        }

        function refreshFogUniforms(uniforms:Uniforms_t, fog:Fog) {
            fog.color.getRGB(uniforms.fogColor.value, getUnlitUniformColorSpace(renderer));
            if (fog.isFog) {
                uniforms.fogNear.value = fog.near;
                uniforms.fogFar.value = fog.far;
            } else if (fog.isFogExp2) {
                uniforms.fogDensity.value = fog.density;
            }
        }

        function refreshMaterialUniforms(uniforms:Uniforms_t, material:Material, pixelRatio:Float, height:Int, transmissionRenderTarget:WebGLRenderTarget) {
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

        function refreshUniformsCommon(uniforms:Uniforms_t, material:Material) {
            uniforms.opacity.value = material.opacity;
            if (material.color != null) {
                uniforms.diffuse.value.copy(material.color);
            }
            if (material.emissive != null) {
                uniforms.emissive.value.copy(material.emissive).multiplyScalar(material.emissiveIntensity);
            }
            if (material.map != null) {
                uniforms.map.value = material.map;
                refreshTransformUniform(material.map, uniforms.mapTransform);
            }
            if (material.alphaMap != null) {
                uniforms.alphaMap.value = material.alphaMap;
                refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
            }
            if (material.bumpMap != null) {
                uniforms.bumpMap.value = material.bumpMap;
                refreshTransformUniform(material.bumpMap, uniforms.bumpMapTransform);
                uniforms.bumpScale.value = material.bumpScale;
                if (material.side == BackSide) {
                    uniforms.bumpScale.value *= -1;
                }
            }
            if (material.normalMap != null) {
                uniforms.normalMap.value = material.normalMap;
                refreshTransformUniform(material.normalMap, uniforms.normalMapTransform);
                uniforms.normalScale.value.copy(material.normalScale);
                if (material.side == BackSide) {
                    uniforms.normalScale.value.negate();
                }
            }
            if (material.displacementMap != null) {
                uniforms.displacementMap.value = material.displacementMap;
                refreshTransformUniform(material.displacementMap, uniforms.displacementMapTransform);
                uniforms.displacementScale.value = material.displacementScale;
                uniforms.displacementBias.value = material.displacementBias;
            }
            if (material.emissiveMap != null) {
                uniforms.emissiveMap.value = material.emissiveMap;
                refreshTransformUniform(material.emissiveMap, uniforms.emissiveMapTransform);
            }
            if (material.specularMap != null) {
                uniforms.specularMap.value = material.specularMap;
                refreshTransformUniform(material.specularMap, uniforms.specularMapTransform);
            }
            if (material.alphaTest > 0) {
                uniforms.alphaTest.value = material.alphaTest;
            }
            var materialProperties:MaterialProperties = properties.get(material);
            var envMap:Texture = materialProperties.envMap;
            var envMapRotation:Euler = materialProperties.envMapRotation;
            if (envMap != null) {
                uniforms.envMap.value = envMap;
                _e1.copy(envMapRotation);
                // accommodate left-handed frame
                _e1.x *= -1;
                _e1.y *= -1;
                _e1.z *= -1;
                if (envMap.isCubeTexture && !envMap.isRenderTargetTexture) {
                    // environment maps which are not cube render targets or PMREMs follow a different convention
                    _e1.y *= -1;
                    _e1.z *= -1;
                }
                uniforms.envMapRotation.value.setFromMatrix4(_m1.makeRotationFromEuler(_e1));
                uniforms.flipEnvMap.value = (envMap.isCubeTexture && !envMap.isRenderTargetTexture) ? -1 : 1;
                uniforms.reflectivity.value = material.reflectivity;
                uniforms.ior.value = material.ior;
                uniforms.refractionRatio.value = material.refractionRatio;
            }
            if (material.lightMap != null) {
                uniforms.lightMap.value = material.lightMap;
                // artist-friendly light intensity scaling factor
                var scaleFactor:Float = (renderer._useLegacyLights) ? Math.PI : 1;
                uniforms.lightMapIntensity.value = material.lightMapIntensity * scaleFactor;
                refreshTransformUniform(material.lightMap, uniforms.lightMapTransform);
            }
            if (material.aoMap != null) {
                uniforms.aoMap.value = material.aoMap;
                uniforms.aoMapIntensity.value = material.aoMapIntensity;
                refreshTransformUniform(material.aoMap, uniforms.aoMapTransform);
            }
        }

        function refreshUniformsLine(uniforms:Uniforms_t, material:LineBasicMaterial) {
            uniforms.diffuse.value.copy(material.color);
            uniforms.opacity.value = material.opacity;
            if (material.map != null) {
                uniforms.map.value = material.map;
                refreshTransformUniform(material.map, uniforms.mapTransform);
            }
        }

        function refreshUniformsDash(uniforms:Uniforms_t, material:LineDashedMaterial) {
            uniforms.dashSize.value = material.dashSize;
            uniforms.totalSize.value = material.dashSize + material.gapSize;
            uniforms.scale.value = material.scale;
        }

        function refreshUniformsPoints(uniforms:Uniforms_t, material:PointsMaterial, pixelRatio:Float, height:Int) {
            uniforms.diffuse.value.copy(material.color);
            uniforms.opacity.value = material.opacity;
            uniforms.size.value = material.size * pixelRatio;
            uniforms.scale.value = height / 2;
            if (material.map != null) {
                uniforms.map.value = material.map;
                refreshTransformUniform(material.map, uniforms.uvTransform);
            }
            if (material.alphaMap != null) {
                uniforms.alphaMap.value = material.alphaMap;
                refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
            }
            if (material.alphaTest > 0) {
                uniforms.alphaTest.value = material.alphaTest;
            }
        }

        function refreshUniformsSprites(uniforms:Uniforms_t, material:SpriteMaterial) {
            uniforms.diffuse.value.copy(material.color);
            uniforms.opacity.value = material.opacity;
            uniforms.rotation.value = material.rotation;
            if (material.map != null) {
                uniforms.map.value = material.map;
                refreshTransformUniform(material.map, uniforms.mapTransform);
            }
            if (material.alphaMap != null) {
                uniforms.alphaMap.value = material.alphaMap;
                refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
            }
            if (material.alphaTest > 0) {
                uniforms.alphaTest.value = material.alphaTest;
            }
        }

        function refreshUniformsPhong(uniforms:Uniforms_t, material:MeshPhongMaterial) {
            uniforms.specular.value.copy(material.specular);
            uniforms.shininess.value = Math.max(material.shininess, 1e-4); // to prevent pow(0.0, 0.0)
        }

        function refreshUniformsToon(uniforms:Uniforms_t, material:MeshToonMaterial) {
            if (material.gradientMap != null) {
                uniforms.gradientMap.value = material.gradientMap;
            }
        }

        function refreshUniformsStandard(uniforms:Uniforms_t, material:MeshStandardMaterial) {
            uniforms.metalness.value = material.metalness;
            if (material.metalnessMap != null) {
                uniforms.metalnessMap.value = material.metalnessMap;
                refreshTransformUniform(material.metalnessMap, uniforms.metalnessMapTransform);
            }
            uniforms.roughness.value = material.roughness;
            if (material.roughnessMap != null) {
                uniforms.roughnessMap.value = material.roughnessMap;
                refreshTransformUniform(material.roughnessMap, uniforms.roughnessMapTransform);
            }
            if (material.envMap != null) {
                //uniforms.envMap.value = material.envMap; // part of uniforms common
                uniforms.envMapIntensity.value = material.envMapIntensity;
            }
        }

        function refreshUniformsPhysical(uniforms:Uniforms_t, material:MeshPhysicalMaterial, transmissionRenderTarget:WebGLRenderTarget) {
            uniforms.ior.value = material.ior; // also part of uniforms common
            if (material.sheen > 0) {
                uniforms.sheenColor.value.copy(material.sheenColor).multiplyScalar(material.sheen);
                uniforms.sheenRoughness.value = material.sheenRoughness;
                if (material.sheenColorMap != null) {
                    uniforms.sheenColorMap.value = material.sheenColorMap;
                    refreshTransformUniform(material.sheenColorMap, uniforms.sheenColorMapTransform);
                }
                if (material.sheenRoughnessMap != null) {
                    uniforms.sheenRoughnessMap.value = material.sheenRoughnessMap;
                    refreshTransformUniform(material.sheenRoughnessMap, uniforms.sheenRoughnessMapTransform);
                }
            }
            if (material.clearcoat > 0) {
                uniforms.clearcoat.value = material.clearcoat;
                uniforms.clearcoatRoughness.value = material.clearcoatRoughness;
                if (material.clearcoatMap != null) {
                    uniforms.clearcoatMap.value = material.clearcoatMap;
                    refreshTransformUniform(material.clearcoatMap, uniforms.clearcoatMapTransform);
                }
                if (material.clearcoatRoughnessMap != null) {
                    uniforms.clearcoatRoughnessMap.value = material.clearcoatRoughnessMap;
                    refreshTransformUniform(material.clearcoatRoughnessMap, uniforms.clearcoatRoughnessMapTransform);
                }
                if (material.clearcoatNormalMap != null) {
                    uniforms.clearcoatNormalMap.value = material.clearcoatNormalMap;
                    refreshTransformUniform(material.clearcoatNormalMap, uniforms.clearcoatNormalMapTransform);
                    uniforms.clearcoatNormalScale.value.copy(material.clearcoatNormalScale);
                    if (material.side == BackSide) {
                        uniforms.clearcoatNormalScale.value.negate();
                    }
                }
            }
            if (material.dispersion > 0) {
                uniforms.dispersion.value = material.dispersion;
            }
            if (material.iridescence > 0) {
                uniforms.iridescence.value = material.iridescence;
                uniforms.iridescenceIOR.value = material.iridescenceIOR;
                uniforms.iridescenceThicknessMinimum.value = material.iridescenceThicknessRange[0];
                uniforms.iridescenceThicknessMaximum.value = material.iridescenceThicknessRange[1];
                if (material.iridescenceMap != null) {
                    uniforms.iridescenceMap.value = material.iridescenceMap;
                    refreshTransformUniform(material.iridescenceMap, uniforms.iridescenceMapTransform);
                }
                if (material.iridescenceThicknessMap != null) {
                    uniforms.iridescenceThicknessMap.value = material.iridescenceThicknessMap;
                    refreshTransformUniform(material.iridescenceThicknessMap, uniforms.iridescenceThicknessMapTransform);
                }
            }
            if (material.transmission > 0) {
                uniforms.transmission.value = material.transmission;
                uniforms.transmissionSamplerMap.value = transmissionRenderTarget.texture;
                uniforms.transmissionSamplerSize.value.set(transmissionRenderTarget.width, transmissionRenderTarget.height);
                if (material.transmissionMap != null) {
                    uniforms.transmissionMap.value = material.transmissionMap;
                    refreshTransformUniform(material.transmissionMap, uniforms.transmissionMapTransform);
                }
                uniforms.thickness.value = material.thickness;
                if (material.thicknessMap != null) {
                    uniforms.thicknessMap.value = material.thicknessMap;
                    refreshTransformUniform(material.thicknessMap, uniforms.thicknessMapTransform);
                }
                uniforms.attenuationDistance.value = material.attenuationDistance;
                uniforms.attenuationColor.value.copy(material.attenuationColor);
            }
            if (material.anisotropy > 0) {
                uniforms.anisotropyVector.value.set(material.anisotropy * Math.cos(material.anisotropyRotation), material.anisotropy * Math.sin(material.anisotropyRotation));
                if (material.anisotropyMap != null) {
                    uniforms.anisotropyMap.value = material.anisotropyMap;
                    refreshTransformUniform(material.anisotropyMap, uniforms.anisotropyMapTransform);
                }
            }
            uniforms.specularIntensity.value = material.specularIntensity;
            uniforms.specularColor.value.copy(material.specularColor);
            if (material.specularColorMap != null) {
                uniforms.specularColorMap.value = material.specularColorMap;
                refreshTransformUniform(material.specularColorMap, uniforms.specularColorMapTransform);
            }
            if (material.specularIntensityMap != null) {
                uniforms.specularIntensityMap.value = material.specularIntensityMap;
                refreshTransform
.value = material.specularIntensityMap;
                refreshTransformUniform(material.specularIntensityMap, uniforms.specularIntensityMapTransform);
            }
        }

        function refreshUniformsMatcap(uniforms:Uniforms_t, material:MeshMatcapMaterial) {
            if (material.matcap != null) {
                uniforms.matcap.value = material.matcap;
            }
        }

        function refreshUniformsDistance(uniforms:Uniforms_t, material:MeshDistanceMaterial) {
            var light:Light = properties.get(material).light;
            uniforms.referencePosition.value.setFromMatrixPosition(light.matrixWorld);
            uniforms.nearDistance.value = light.shadow.camera.near;
            uniforms.farDistance.value = light.shadow.camera.far;
        }

        return {
            refreshFogUniforms: refreshFogUniforms,
            refreshMaterialUniforms: refreshMaterialUniforms
        };
    }
}

typedef Uniforms_t = {
    fogColor: { value: Color },
    fogNear: { value: Float },
    fogFar: { value: Float },
    fogDensity: { value: Float },
    opacity: { value: Float },
    diffuse: { value: Color },
    emissive: { value: Color },
    map: { value: Texture },
    mapTransform: { value: Matrix4 },
    alphaMap: { value: Texture },
    alphaMapTransform: { value: Matrix4 },
    bumpMap: { value: Texture },
    bumpMapTransform: { value: Matrix4 },
    bumpScale: { value: Float },
    normalMap: { value: Texture },
    normalMapTransform: { value: Matrix4 },
    normalScale: { value: Vector2 },
    displacementMap: { value: Texture },
    displacementMapTransform: { value: Matrix4 },
    displacementScale: { value: Float },
    displacementBias: { value: Float },
    emissiveMap: { value: Texture },
    emissiveMapTransform: { value: Matrix4 },
    specularMap: { value: Texture },
    specularMapTransform: { value: Matrix4 },
    alphaTest: { value: Float },
    envMap: { value: Texture },
    envMapRotation: { value: Matrix3 },
    flipEnvMap: { value: Int },
    reflectivity: { value: Float },
    ior: { value: Float },
    refractionRatio: { value: Float },
    lightMap: { value: Texture },
    lightMapIntensity: { value: Float },
    lightMapTransform: { value: Matrix4 },
    aoMap: { value: Texture },
    aoMapIntensity: { value: Float },
    aoMapTransform: { value: Matrix4 },
    gradientMap: { value: Texture },
    specular: { value: Color },
    shininess: { value: Float },
    metalness: { value: Float },
    metalnessMap: { value: Texture },
    metalnessMapTransform: { value: Matrix4 },
    roughness: { value: Float },
    roughnessMap: { value: Texture },
    roughnessMapTransform: { value: Matrix4 },
    envMapIntensity: { value: Float },
    sheenColor: { value: Color },
    sheenColorMap: { value: Texture },
    sheenColorMapTransform: { value: Matrix4 },
    sheenRoughness: { value: Float },
    sheenRoughnessMap: { value: Texture },
    sheenRoughnessMapTransform: { value: Matrix4 },
    clearcoat: { value: Float },
    clearcoatRoughness: { value: Float },
    clearcoatMap: { value: Texture },
    clearcoatMapTransform: { value: Matrix4 },
    clearcoatRoughnessMap: { value: Texture },
    clearcoatRoughnessMapTransform: { value: Matrix4 },
    clearcoatNormalMap: { value: Texture },
    clearcoatNormalMapTransform: { value: Matrix4 },
    clearcoatNormalScale: { value: Vector2 },
    dispersion: { value: Float },
    iridescence: { value: Float },
    iridescenceIOR: { value: Float },
    iridescenceThicknessMinimum: { value: Float },
    iridescenceThicknessMaximum: { value: Float },
    iridescenceMap: { value: Texture },
    iridescenceMapTransform: { value: Matrix4 },
    iridescenceThicknessMap: { value: Texture },
    iridescenceThicknessMapTransform: { value: Matrix4 },
    transmission: { value: Float },
    transmissionSamplerMap: { value: Texture },
    transmissionSamplerSize: { value: Vector2 },
    transmissionMap: { value: Texture },
    transmissionMapTransform: { value: Matrix4 },
    thickness: { value: Float },
    thicknessMap: { value: Texture },
    thicknessMapTransform: { value: Matrix4 },
    attenuationDistance: { value: Float },
    attenuationColor: { value: Color },
    anisotropy: { value: Float },
    anisotropyVector: { value: Vector2 },
    anisotropyMap: { value: Texture },
    anisotropyMapTransform: { value: Matrix4 },
    specularIntensity: { value: Float },
    specularColor: { value: Color },
    specularColorMap: { value: Texture },
    specularColorMapTransform: { value: Matrix4 },
    specularIntensityMap: { value: Texture },
    specularIntensityMapTransform: { value: Matrix4 },
    matcap: { value: Texture },
    referencePosition: { value: Vector3 },
    nearDistance: { value: Float },
    farDistance: { value: Float },
    dashSize: { value: Float },
    totalSize: { value: Float },
    scale: { value: Float },
    size: { value: Float },
    rotation: { value: Float },
    uvTransform: { value: Matrix3 }
}

enum BackSide { }

function getUnlitUniformColorSpace():Int {
    // ...
}

class Color {
    public function copy(other:Color):Color {
        // ...
    }
}

class Texture {
    public var matrixAutoUpdate:Bool;
    public function updateMatrix():Void {
        // ...
    }
}

class Matrix4 {
    public function copy(other:Matrix4):Matrix4 {
        // ...
    }
}

class Material {
    public var opacity:Float;
    public var color:Color;
    public var emissive:Color;
    public var emissiveIntensity:Float;
    public var map:Texture;
    public var alphaMap:Texture;
    public var bumpMap:Texture;
    public var bumpScale:Float;
    public var normalMap:Texture;
    public var normalScale:Vector2;
    public var displacementMap:Texture;
    public var displacementScale:Float;
    public var displacementBias:Float;
    public var emissiveMap:Texture;
    public var specularMap:Texture;
    public var alphaTest:Float;
    public var side:Int;
}

class MaterialProperties {
    public var envMap:Texture;
    public var envMapRotation:Euler;
}

class Light {
    public var shadow:Shadow;
}

class Shadow {
    public var camera:Camera;
}

class LineBasicMaterial extends Material {
    public var color:Color;
    public var opacity:Float;
    public var map:Texture;
}

class LineDashedMaterial extends LineBasicMaterial {
    public var dashSize:Float;
    public var gapSize:Float;
    public var scale:Float;
}

class PointsMaterial extends Material {
    public var color:Color;
    public var opacity:Float;
    public var size:Float;
    public var map:Texture;
    public var alphaMap:Texture;
    public var alphaTest:Float;
}

class SpriteMaterial extends Material {
    public var color:Color;
    public var opacity:Float;
    public var rotation:Float;
    public var map:Texture;
    public var alphaMap:Texture;
    public var alphaTest:Float;
}

class MeshPhongMaterial extends Material {
    public var specular:Color;
    public var shininess:Float;
}

class MeshToonMaterial extends Material {
    public var gradientMap:Texture;
}

class MeshStandardMaterial extends Material {
    public var metalness:Float;
    public var metalnessMap:Texture;
    public var roughness:Float;
    public var roughnessMap:Texture;
    public var envMap:Texture;
    public var envMapIntensity:Float;
}

class MeshPhysicalMaterial extends MeshStandardMaterial {
    public var ior:Float;
    public var sheen:Float;
    public var sheenColor:Color;
    public var sheenColorMap:Texture;
    public var sheenRoughness:Float;
    public var sheenRoughnessMap:Texture;
    public var clearcoat:Float;
    public var clearcoatRoughness:Float;
    public var clearcoatMap:Texture;
    public var clearcoatRoughnessMap:Texture;
    public var clearcoatNormalMap:Texture;
    public var clearcoatNormalScale:Vector2;
    public var dispersion:Float;
    public var iridescence:Float;
    public var iridescenceIOR:Float;
    public var iridescenceThicknessRange:Vector2;
    public var iridescenceMap:Texture;
    public var iridescenceThicknessMap:Texture;
    public var transmission:Float;
    public var transmissionMap:Texture;
    public var thickness:Float;
    public var thicknessMap:Texture;
    public var attenuationDistance:Float;
    public var attenuationColor:Color;
    public var anisotropy:Float;
    public var anisotropyRotation:Float;
    public var anisotropyMap:Texture;
    public var specularIntensity:Float;
    public var specularColor:Color;
    public var specularColorMap:Texture;
    public var specularIntensityMap:Texture;
}

class MeshMatcapMaterial extends Material {
    public var matcap:Texture;
}

class MeshDistanceMaterial extends Material {
    public var alphaMap:Texture;
}

class Euler {
    public function copy(other:Euler):Euler {
        // ...
    }
}

class Matrix3 {
    public function setFromMatrix4(m:Matrix4):Matrix3 {
        // ...
    }
}

class Vector2 {
    public function negate():Vector2 {
        // ...
    }
}

class Vector3 {
    public function setFromMatrixPosition(m:Matrix4):Vector3 {
        // ...
    }
}

class WebGLRenderTarget {
    public var texture:Texture;
    public var width:Int;
    public var height:Int;
}

class Camera extends InteractiveObject {
    public var near:Float;
    public var far:Float;
}

class MeshBasicMaterial extends Material { }

class MeshLambertMaterial extends MeshPhongMaterial { }

class ShaderMaterial extends Material {
    public var uniformsNeedUpdate:Bool;
}

class ShadowMaterial extends Material {
    public var color:Color;
    public var opacity:Float;
}

class Renderer {
    public var _useLegacyLights:Bool;
}