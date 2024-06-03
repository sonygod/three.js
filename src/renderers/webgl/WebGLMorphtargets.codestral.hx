import js.Browser.document;
import js.lib.WebGLRendering.WebGLRendering;
import js.lib.WebGLRendering.WebGLRendering.Float32Array;
import js.lib.WebGLRendering.WebGLRendering.GLenum;
import js.lib.WebGLRendering.WebGLRendering.Texture;
import js.lib.WebGLRendering.WebGLRendering.WebGLUniformLocation;
import js.lib.WebGLRendering.WebGLRendering.WebGLBufferAttribute;
import js.lib.WebGLRendering.WebGLRendering.WebGLProgram;
import js.lib.WebGLRendering.WebGLRendering.WebGLCapabilities;
import js.lib.WebGLRendering.WebGLRendering.WebGLTexture;
import js.lib.WebGLRendering.WebGLRendering.WebGLObject;
import js.lib.WebGLRendering.WebGLRendering.WebGLRenderer;
import js.lib.WebGLRendering.WebGLRendering.WebGLRenderTarget;
import js.lib.WebGLRendering.WebGLRendering.WebGLFramebuffer;
import js.lib.WebGLRendering.WebGLRendering.WebGLRenderTargetOptions;
import js.lib.WebGLRendering.WebGLRendering.WebGLRenderingContextBase;
import js.lib.WebGLRendering.WebGLRendering.WebGLRenderingContext;
import js.lib.WebGLRendering.WebGLRendering.WebGLTexture as GLTexture;
import Three.core.Object3D;
import Three.core.EventDispatcher;
import Three.math.Vector4;
import Three.math.Vector2;
import Three.constants.Constants;
import Three.renderers.shaders.Uniform;
import Three.textures.Texture as ThreeTexture;
import Three.textures.DataArrayTexture;
import Three.objects.InstancedMesh;
import Three.core.Geometry;

class WebGLMorphtargets {

    private var morphTextures:Map<Geometry, {count:Int, texture:DataArrayTexture, size:Vector2}>;
    private var morph:Vector4;
    private var gl:WebGLRenderingContext;
    private var capabilities:WebGLCapabilities;
    private var textures:Map<ThreeTexture, {texture:WebGLTexture, image:Image}>;

    public function new(gl:WebGLRenderingContext, capabilities:WebGLCapabilities, textures:Map<ThreeTexture, {texture:WebGLTexture, image:Image}>) {
        this.morphTextures = new haxe.ds.WeakMap();
        this.morph = new Vector4();
        this.gl = gl;
        this.capabilities = capabilities;
        this.textures = textures;
    }

    public function update(object:Object3D, geometry:Geometry, program:WebGLProgram) {
        var objectInfluences = object.morphTargetInfluences;

        var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
        var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

        var entry = this.morphTextures.get(geometry);

        if (entry == null || entry.count != morphTargetsCount) {
            if (entry != null) entry.texture.dispose();

            var hasMorphPosition = geometry.morphAttributes.position != null;
            var hasMorphNormals = geometry.morphAttributes.normal != null;
            var hasMorphColors = geometry.morphAttributes.color != null;

            var morphTargets = geometry.morphAttributes.position || [];
            var morphNormals = geometry.morphAttributes.normal || [];
            var morphColors = geometry.morphAttributes.color || [];

            var vertexDataCount = 0;

            if (hasMorphPosition) vertexDataCount = 1;
            if (hasMorphNormals) vertexDataCount = 2;
            if (hasMorphColors) vertexDataCount = 3;

            var width = geometry.attributes.position.count * vertexDataCount;
            var height = 1;

            if (width > this.capabilities.maxTextureSize) {
                height = Math.ceil(width / this.capabilities.maxTextureSize);
                width = this.capabilities.maxTextureSize;
            }

            var buffer = new Float32Array(width * height * 4 * morphTargetsCount);

            var texture = new DataArrayTexture(buffer, width, height, morphTargetsCount);
            texture.type = Constants.FloatType;
            texture.needsUpdate = true;

            var vertexDataStride = vertexDataCount * 4;

            for (var i = 0; i < morphTargetsCount; i++) {
                var morphTarget = morphTargets[i];
                var morphNormal = morphNormals[i];
                var morphColor = morphColors[i];

                var offset = width * height * 4 * i;

                for (var j = 0; j < morphTarget.count; j++) {
                    var stride = j * vertexDataStride;

                    if (hasMorphPosition) {
                        this.morph.fromBufferAttribute(morphTarget, j);

                        buffer[offset + stride + 0] = this.morph.x;
                        buffer[offset + stride + 1] = this.morph.y;
                        buffer[offset + stride + 2] = this.morph.z;
                        buffer[offset + stride + 3] = 0;
                    }

                    if (hasMorphNormals) {
                        this.morph.fromBufferAttribute(morphNormal, j);

                        buffer[offset + stride + 4] = this.morph.x;
                        buffer[offset + stride + 5] = this.morph.y;
                        buffer[offset + stride + 6] = this.morph.z;
                        buffer[offset + stride + 7] = 0;
                    }

                    if (hasMorphColors) {
                        this.morph.fromBufferAttribute(morphColor, j);

                        buffer[offset + stride + 8] = this.morph.x;
                        buffer[offset + stride + 9] = this.morph.y;
                        buffer[offset + stride + 10] = this.morph.z;
                        buffer[offset + stride + 11] = (morphColor.itemSize == 4) ? this.morph.w : 1;
                    }
                }
            }

            entry = {
                count: morphTargetsCount,
                texture: texture,
                size: new Vector2(width, height)
            };

            this.morphTextures.set(geometry, entry);

            geometry.addEventListener('dispose', function(event:Event) {
                texture.dispose();
                this.morphTextures.delete(geometry);
            });
        }

        if (Std.is(object, InstancedMesh) && object.morphTexture != null) {
            program.getUniforms().setValue(this.gl, 'morphTexture', object.morphTexture, this.textures);
        } else {
            var morphInfluencesSum = 0;

            for (var i = 0; i < objectInfluences.length; i++) {
                morphInfluencesSum += objectInfluences[i];
            }

            var morphBaseInfluence = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;

            program.getUniforms().setValue(this.gl, 'morphTargetBaseInfluence', morphBaseInfluence);
            program.getUniforms().setValue(this.gl, 'morphTargetInfluences', objectInfluences);
        }

        program.getUniforms().setValue(this.gl, 'morphTargetsTexture', entry.texture, this.textures);
        program.getUniforms().setValue(this.gl, 'morphTargetsTextureSize', entry.size);
    }
}