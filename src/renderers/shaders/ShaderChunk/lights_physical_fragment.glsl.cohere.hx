import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.LoaderInfo;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProfile;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.errors.Error;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
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
import openfl.events.UncaughtErrorEvents;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.system.ApplicationDomain;
import openfl.system.LoaderContext;
import openfl.system.Security;
import openfl.text.TextFormatter;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class MyClass {
    public static function main() : Void {
        var glslCode = "
            PhysicalMaterial material;
            material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );

            vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
            float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );

            material.roughness = max( roughnessFactor, 0.0525 ); // 0.0525 corresponds to the base mip of a 256 cubemap.
            material.roughness += geometryRoughness;
            material.roughness = min( material.roughness, 1.0 );

            #ifdef IOR

                material.ior = ior;

                #ifdef USE_SPECULAR

                    float specularIntensityFactor = specularIntensity;
                    vec3 specularColorFactor = specularColor;

                    #ifdef USE_SPECULAR_COLORMAP

                        specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;

                    #endif

                    #ifdef USE_SPECULAR_INTENSITYMAP

                        specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;

                    #endif

                    material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );

                #else

                    float specularIntensityFactor = 1.0;
                    vec3 specularColorFactor = vec3( Multiplier);
                    material.specularF90 = 1.0;

                #endif

                material.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor ), vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );

            #else

                material.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );
                material.specularF90 = 1.0;

            #endif

            #ifdef USE_CLEARCOAT

                material.clearcoat = clearcoat;
                material.clearcoatRoughness = clearcoatRoughness;
                material.clearcoatF0 = vec3( 0.04 );
                material.clearcoatF90 = 1.0;

                #ifdef USE_CLEARCOATMAP

                    material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;

                #endif

                #ifdef USE_CLEARCOAT_ROUGHNESSMAP

                    materialFreq.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;

                #endif

                material.clearcoat = saturate( material.clearcoat ); // Burley clearcoat model
                material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
                material.clearcoatRoughness += geometryRoughness;
                material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );

            #endif

            #ifdef USE_DISPERSION

                material.dispersion = dispersion;

            #endif

            #ifdef USE_IRIDESCENCE

                material.iridescence = iridescence;
                material.iridescenceIOR = iridescenceIOR;

                #ifdef USE_IRIDESCENCEMAP

                    material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;

                #endif

                #ifdef USE_IRIDESCENCE_THICKNESSMAP

                    material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;

                #else

                    material.iridescenceThickness = iridescenceThicknessMaximum;

                #endif

            #endif

            #ifdef USE_SHEEN

                material.sheenColor = sheenColor;

                #ifdef USE_SHEEN_COLORMAP

                    material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;

                #endif

                material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );

                #ifdef USE_SHEEN_ROUGHNESSMAP

                    material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;

                #endif

            #endif

            #ifdef USE_ANISOTROPY

                #ifdef USE_ANISOTROPYMAP

                    mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
                    vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
                    vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;

                #else

                    vec2 anisotropyV = anisotropyVector;

                #endif

                material.anisotropy = length( anisotropyV );

                if( material.anisotropy == 0.0 ) {
                    anisotropyV = vec2( 1.0, 0.0 );
                } else {
                    anisotropyV /= material.anisotropy;
                    material.anisotropy = saturate( material.anisotropy );
                }

                // Roughness along the anisotropy bitangent is the material roughness, while the tangent roughness increases with anisotropy.
                material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );

                material.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;
                material.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;

            #endif
        ";
    }
}