import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.VertexBuffer3DDataFormat;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;

class SubsurfaceScatteringShader extends Shader {
    public var thicknessMap:ShaderInput;
    public var thicknessPower:Float;
    public var thicknessScale:Float;
    public var thicknessDistortion:Float;
    public var thicknessAmbient:Float;
    public var thicknessAttenuation:Float;
    public var thicknessColor:Float;

    public function new() {
        super();

        // GLSL code for the vertex shader
        var vertexShader:String = "#define USE_UV\n" +
            "attribute vec4 vertex;\n" +
            "attribute vec2 uv;\n" +
            "attribute vec3 normal;\n" +
            "attribute vec3 tangent;\n" +
            "attribute vec3 color;\n" +
            "uniform mat4 projectionMatrix;\n" +
            "uniform mat4 viewMatrix;\n" +
            "uniform mat4 modelMatrix;\n" +
            "uniform mat3 normalMatrix;\n" +
            "varying vec2 vUv;\n" +
            "varying vec3 vViewPosition;\n" +
            "varying vec3 vNormal;\n" +
            "varyCoefficient mat4 viewProjectionMatrix;\n" +
            "void main() {\n" +
            "vec4 worldPosition = modelMatrix * vertex;\n" +
            "vViewPosition = vec3(viewMatrix * worldPosition);\n" +
            "vNormal = normalize(normalMatrix * normal);\n" +
            "vUv = uv;\n" +
            "gl_Position = projectionMatrix * viewMatrix * worldPosition;\n" +
            "}";

        // GLSL code for the fragment shader
        var fragmentShader:String = "#define USE_UV\n" +
            "#define SUBSURFACE\n" +
            "varying vec2 vUv;\n" +
            "varying vec3 vViewPosition;\n" +
            "varying vec3 vNormal;\n" +
            "uniform vec3 diffuse;\n" +
            "uniform vec3 emissive;\n" +
            "uniform float shininess;\n" +
            "uniform float opacity;\n" +
            "uniform vec3 ambientLightColor;\n" +
            "uniform vec3 directionalLightColor[ NUM_DIR_LIGHTS ];\n" +
            "uniform vec3 directionalLightDirection[ NUM_DIR_LIGHTS ];\n" +
            "uniform vec3 pointLightColor[ NUM_POINT_LIGHTS ];\n" +
            "uniform vec3 pointLightPosition[ NUM_POINT_LIGHTS ];\n" +
            "uniform float pointLightDistance[ NUM_POINT_LIGHTS ];\n" +
            "uniform vec3 spotLightColor[ NUM_SPOT_LIGHTS ];\n" +
            "uniform vec3 spotLightPosition[ NUM_SPOT_LIGHTS ];\n" +
            "uniform vec3 spotLightDirection[ NUM_SPOT_LIGHTS ];\n" +
            "uniform float spotLightAngleCos[ NUM_SPOT_LIGHTS ];\n" +
            "uniform float spotLightDistance[ NUM_SPOT_LIGHTS ];\n" +
            "uniform vec2 pointSize[\n" +
            "NUM_POINT_LIGHTS ];\n" +
            "uniform mat4 pointProjectionMatrix[ NUM_POINT_LIGHTS ];\n" +
            "uniform mat4 pointViewMatrix[ NUM_POINT_LIGHTS ];\n" +
            "uniform mat4 spotViewMatrix[ NUM_SPOT_LIGHTS ];\n" +
            "uniform mat4 spotProjectionMatrix[ NUM_SPOT_LIGHTS ];\n" +
            "uniform vec3 specular;\n" +
            "uniform float specularCoefficient;\n" +
            "uniform float ambientCoefficient;\n" +
            "uniform float directCoefficient;\n" +
            "uniform float emissiveCoefficient;\n" +
            "uniform float wrapAround;\n" +
            "uniform bool enableDiffuse;\n" +
            "uniform bool enableSpecular;\n" +
            "uniform bool enableSpotLights;\n" +
            "uniform sampler2D diffuseMap;\n" +
            "uniform sampler2D specularMap;\n" +
            "uniform sampler2D normalMap;\n" +
            "uniform sampler2D shadowMap[ NUM_DIR_LIGHTS ];\n" +
            "uniform sampler2D shadowMapPoint[ NUM_POINT_LIGHTS ];\n" +
            "uniform sampler2D shadowMapSpot[ NUM_SPOT_LIGHTS ];\n" +
            "uniform samplerCube spotShadowMap[ NUM_SPOT_LIGHTS ];\n" +
            "uniform vec2 shadowFocus;\n" +
            "uniform vec2 shadowSmoothing;\n" +
            "uniform float shadowEdge;\n" +
            "uniform float shadowDarkness;\n" +
            "uniform float shadowBlur;\n" +
            "uniform float shadowNormalBias;\n" +
            "uniform mat4 shadowMatrix[ NUM_DIR_LIGHTS ];\n" +
            "uniform mat4 shadowMatrixPoint[ NUM_POINT_LIGHTS ];\n" +
            "uniform mat4 shadowMatrixSpot[ NUM_SPOT_LIGHTS ];\n" +
            "uniform vec2 shadowMapSize[ NUM_DIR_LIGHTS ];\n" +
            "uniform vec2 shadowMapSizePoint[ NUM_POINT_LIGHTS ];\n" +
            "uniform vec2 shadowMapSizeSpot[ NUM_SPOT_LIGHTS ];\n" +
            "uniform int shadowMapEnabled[ NUM_DIR_LIGHTS ];\n" +
            "uniform int shadowMapEnabledPoint[ NUM_POINT_LIGHTS ];\n" +
            "uniform int shadowMapEnabledSpot[ NUM_SPOT_LIGHTS ];\n" +
            "uniform int shadowMappingType;\n" +
            "uniform float shadowMapPointSize[ NUM_POINT_LIGHTS ];\n" +
            "uniform float shadowMapBias[ NUM_DIR_LIGHTS ];\n" +
            "uniform float shadowMapBiasPoint[ NUM_POINT_LIGHTS ];\n" +
            "uniform float shadowMapBiasSpot[ NUM_SPOT_LIGHTS ];\n" +
            "uniform float shadowMapBlur[ NUM_DIR_LIGHTS ];\n" +
            "uniform float shadowMapBlurPoint[ NUM_POINT_LIGHTS ];\n" +
            "uniform float shadowMapBlurSpot[ NUM_SPOT_LIGHTS ];\n" +
            "uniform int shadowMapPointCascade;\n" +
            "uniform int shadowMapSpotCascade;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform float shadowCascadeBlendAmount;\n" +
            "uniform float shadowCascadeBlendAmountSpot;\n" +
            "uniform int shadowMapType;\n" +
            "uniform int shadowMapTypeSpot;\n" +
            "uniform int shadowMapTypePoint;\n" +
            "uniform int shadowMapFocus;\n" +
            "uniform int shadowMapFocusPoint;\n" +
            "uniform int shadowMapFocusSpot;\n" +
            "uniform int shadowMapPointCascadeCount;\n" +
            "uniform int shadowMapSpotCascadeCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +
            "uniform int shadowMapPointCount;\n" +
            "uniform int shadowMapSpotCount;\n" +