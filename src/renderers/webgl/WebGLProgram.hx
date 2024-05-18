import haxe.ds.StringMap;
import openfl.utils.ArrayBufferUtils;

class WebGLProgram {

    private static const COMPLETION_STATUS_KHR:Int = 0x91B1;

    private static var programIdCount:Int = 0;

    private static function handleSource(string:String, errorLine:Int):String {
        var lines:Array<String> = string.split('\n');
        var lines2:Array<String> = [];

        var from:Int = Math.max(errorLine - 6, 0);
        var to:Int = Math.min(errorLine + 6, lines.length);

        for (i in 0...to) {
            var line:Int = i + 1;
            lines2.push(`${line === errorLine ? '>' : ' '} ${line}: ${lines[i]}`);
        }

        return lines2.join('\n');
    }

    private static function getEncodingComponents(colorSpace:Int):Array<String> {
        var workingPrimaries:String = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
        var encodingPrimaries:String = ColorManagement.getPrimaries(colorSpace);

        var gamutMapping:String = '';

        if (workingPrimaries === encodingPrimaries) {
            gamutMapping = '';
        } else if (workingPrimaries === P3Primaries && encodingPrimaries === Rec709Primaries) {
            gamutMapping = 'LinearDisplayP3ToLinearSRGB';
        } else if (workingPrimaries === Rec709Primaries && encodingPrimaries === P3Primaries) {
            gamutMapping = 'LinearSRGBToLinearDisplayP3';
        }

        switch (colorSpace) {
            case LinearSRGBColorSpace:
            case LinearDisplayP3ColorSpace:
                return [gamutMapping, 'LinearTransferOETF'];

            case SRGBColorSpace:
            case DisplayP3ColorSpace:
                return [gamutMapping, 'sRGBTransferOETF'];

            default:
                console.warn('THREE.WebGLProgram: Unsupported color space:', colorSpace);
                return [gamutMapping, 'LinearTransferOETF'];
        }
    }

    private static function getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
        var status:Int = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
        var errors:String = gl.getShaderInfoLog(shader).trim();

        if (status && errors === '') return '';

        var errorMatches:Array<String> = /ERROR: 0:(\d+)/.exec(errors);
        if (errorMatches) {

            // --enable-privileged-webgl-extension
            // console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

            var errorLine:Int = parseInt(errorMatches[1]);
            return type.toUpperCase() + '\n\n' + errors + '\n\n' + handleSource(ArrayBufferUtils.toString(gl.getShaderSource(shader)), errorLine);

        } else {

            return errors;

        }
    }

    private static function getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
        var components:Array<String> = getEncodingComponents(colorSpace);
        return `vec4 ${functionName}( vec4 value ) { return ${components[0]}( ${components[1]}( value ) ); }`;
    }

    private static function getToneMappingFunction(functionName:String, toneMapping:Int):String {
        var toneMappingName:String;

        switch (toneMapping) {
            case LinearToneMapping:
                toneMappingName = 'Linear';
                break;

            case ReinhardToneMapping:
                toneMappingName = 'Reinhard';
                break;

            case CineonToneMapping:
                toneMappingName = 'OptimizedCineon';
                break;

            case ACESFilmicToneMapping:
                toneMappingName = 'ACESFilmic';
                break;

            case AgXToneMapping:
                toneMappingName = 'AgX';
                break;

            case NeutralToneMapping:
                toneMappingName = 'Neutral';
                break;

            case CustomToneMapping:
                toneMappingName = 'Custom';
                break;

            default:
                console.warn('THREE.WebGLProgram: Unsupported toneMapping:', toneMapping);
                toneMappingName = 'Linear';
        }

        return 'vec3 ' + functionName + '( vec3 color ) { return ' + toneMappingName + 'ToneMapping( color ); }';
    }

    private static function generateVertexExtensions(parameters:Dynamic):String {
        var chunks:Array<String> = [];

        chunks.push(parameters.extensionClipCullDistance ? '#extension GL_ANGLE_clip_cull_distance : require' : '');
        chunks.push(parameters.extensionMultiDraw ? '#extension GL_ANGLE_multi_draw : require' : '');

        return chunks.filter(filterEmptyLine).join('\n');
    }

    private static function generateDefines(defines:StringMap<String>):String {
        var chunks:Array<String> = [];

        for (name in defines) {
            var value:String = defines[name];

            if (value === false) continue;

            chunks.push('#define ' + name + ' ' + value);
        }

        return chunks.join('\n');
    }

    private static function fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):StringMap<Dynamic> {
        var attributes:StringMap<Dynamic> = {};

        var n:Int = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);

        for (i in 0...n) {
            var info:WebGLActiveAttrib = gl.getActiveAttrib(program, i);
            var name:String = info.name;

            var locationSize:Int = 1;
            if (info.type === gl.FLOAT_MAT2) locationSize = 2;
            if (info.type === gl.FLOAT_MAT3) locationSize = 3;
            if (info.type === gl.FLOAT_MAT4) locationSize = 4;

            // console.log('THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i);

            attributes[name] = {
                type: info.type,
                location: gl.getAttribLocation(program, name),
                locationSize: locationSize
            };
        }

        return attributes;
    }

    private static function filterEmptyLine(string:String):Bool {
        return string !== '';
    }

    private static function replaceLightNums(string:String, parameters:Dynamic):String {
        var numSpotLightCoords:Int = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

        return string
            .replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights)
            .replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights)
            .replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps)
            .replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords)
            .replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights)
            .replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights)
            .replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights)
            .replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows)
            .replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps)
            .replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows)
            .replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows);
    }

    private static function replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
        return string
            .replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes)
            .replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection));
    }

    // Resolve Includes

    private static var shaderChunkMap:Map<String, String> = new Map<String, String>();

    private static function resolveIncludes(string:String):String {
        return string.replace(includePattern, includeReplacer);
    }

    private static var includePattern:RegExp = /^[ \t]*#include <([\w\d./]+)>