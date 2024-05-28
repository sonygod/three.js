import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
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
import openfl.events.GameInputEvent;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openflMultiplier.events.ProgressEvent;
import openfl.events.RenderEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TextEvent;
import openfl.events.UncaughtErrorEvents;
import openfl.events.VideoEvent;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openMultiplier.geom.Rectangle;
import openfl.geom.Vector3D;
import openfl.media.SoundTransform;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.system.ApplicationDomain;
import openfl.system.LoaderContext;
import openfl.system.Security;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.ByteArray;
import openfl.utils.Dictionary;

class MyClass {
    public static function main() {
        // GLSL code as a string
        var glslCode = "
            float faceDirection = gl_FrontFacing ? 1.0 : -1.0;

            #ifdef FLAT_SHADED

                vec3 fdx = dFdx( vViewPosition );
                vec3 fdy = dFdy( vViewPosition );
                vec3 normal = normalize( cross( fdx, fdy ) );

            #else

                vec3 normal = normalize( vNormal );

                #ifdef DOUBLE_SIDED

                    normal *= faceDirection;

                #endif

            #endif

            #if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )

                #ifdef USE_TANGENT

                    mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );

                #else

                    mat3 tbn = getTangentFrame( - vViewPosition, normal,
                    #if defined( USE_NORMALMAP )
                        vNormalMapUv
                    #elif defined( USE_CLEARCOAT_NORMALMAP )
                        vClearcoatNormalMapUv
                    #else
                        vUv
                    #endif
                    );

                #endif

                #if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )

                    tbn[0] *= faceDirection;
                    tbn[1] *= faceDirection;

                #endif

            #endif

            #ifdef USE_CLEARCOAT_NORMALMAP

                #ifdef USE_TANGENT

                    mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );

                #else

                    mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );

                #endif

                #if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )

                    tbn2[0] *= faceDirection;
                    tbn2[1] *= faceDirection;

                #endif

            #endif

            // non perturbed normal for clearcoat among others

            vec3 nonPerturbedNormal = normal;
        ";

        // Do something with the GLSL code...
    }
}