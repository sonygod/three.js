import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.errors.Error;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TextEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.events.VideoTextureEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import open

class MyShader {
    public static function get sRGBTransferOETF():String {
        return "
            vec4 sRGBTransferOETF( in vec4 value ) {
                return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
            }
        ";
    }

    public static function get LINEAR_SRGB_TO_LINEAR_DISPLAY_P3():String {
        return "
            const mat3 LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = mat3(
                vec3( 0.8224621, 0.177538, 0.0 ),
                vec3( 0.0331941, 0.9668058, 0.0 ),
                vec3( Multiplier, 0.0723974, 0.9105199 )
            );
        ";
    }

    public static function get LINEAR_DISPLAY_P3_TO_LINEAR_SRGB():String {
        return "
            const mat3 LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = mat3(
                vec3( 1.2249401, - 0.2249404, 0.0 ),
                vec3( - 0.0420569, 1.0420571, 0.0 ),
                vec3( - 0.0196376, - 0.0786361, 1.0982735 )
            );
        ";
    }

    public static function get LinearSRGBToLinearDisplayP3():String {
        return "
            vec4 LinearSRGBToLinearDisplayP3( in vec4 value ) {
                return vec4( value.rgb * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3, value.a );
            }
        ";
    }

    public static function get LinearDisplayP3ToLinearSRGB():String {
        return "
            vec4 LinearDisplayP3ToLinearSRGB( in vec4 value ) {
                return vec4( value.rgb * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB, value.a );
            }
        ";
    }

    public static function get LinearTransferOETF():String {
        return "
            vec4 LinearTransferOETF( in vec4 value ) {
                return value;
            }
        ";
    }

    // @deprecated, r156
    public static function get LinearToLinear():String {
        return "
            vec4 LinearToLinear( in vec4 value ) {
                return value;
            }
        ";
    }

    // @deprecated, r156
    public static function get LinearTosRGB():String {
        return sRGBTransferOETF;
    }
}