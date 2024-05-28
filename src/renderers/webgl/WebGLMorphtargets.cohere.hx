import js.Browser.Window;
import js.WebGLContext.WebGLRenderingContext as GL;
import js.WebGLContext.WebGLTexture as Texture;
import js.WebGLContext.WebGLUniformLocation;
import js.html.DataView;
import js.html.Float32Array;
import js.html.WeakMap;
import js.html.Window;

import openfl.geom.Vector2;
import openfl.geom.Vector4;

class WebGLMorphtargets {
    public var morphTextures: WeakMap;
    public var morph: Vector4;

    public function new(gl: GL, capabilities: Capabilities, textures: Array<Texture>) {
        morphTextures = new WeakMap();
        morph = new Vector4();
    }

    public function update(object: Dynamic, geometry: Geometry, program: Program) {
        var objectInfluences = object.morphTargetInfluences;

        // the following encodes morph targets into an array of data textures. Each layer represents a single morph target.
        var morphAttribute = geometry.morphAttributes.position ?? geometry.morphAttributes.normal ?? geometry.morphAttributes.color;
        var morphTargetsCount = if (morphAttribute != null) morphAttribute.length else 0;

        var entry = morphTextures.get(geometry);

        if (entry == null || entry.count != morphTargetsCount) {
            if (entry != null) entry.texture.dispose();

            var hasMorphPosition = geometry.morphAttributes.position != null;
            var hasMorphNormals = geometry.morphAttributes.normal != null;
            var hasMorphColors = geometry.morphAttributes.color != null;

            var morphTargets = geometry.morphAttributes.position ?? [];
            var morphNormals = geometry.morphAttributes.normal ?? [];
            var morphColors = geometry.morphAttributes.color ?? [];

            var vertexDataCount = 0;

            if (hasMorphPosition) vertexDataCount = 1;
            if (hasMorphNormals) vertexDataCount = 2;
            if (hasMorphColors) vertexDataCount = 3;

            var width = geometry.attributes.position.count * vertexDataCount;
            var height = 1;

            if (width > capabilities.maxTextureSize) {
                height = Std.int(width / capabilities.maxTextureSize) + 1;
                width = capabilities.maxTextureSize;
            }

            var buffer = new Float32Array(width * height * 4 * morphTargetsCount);

            var texture = new DataArrayTexture(buffer, width, height, morphTargetsCount);
            texture.type = FloatType.Float;
            texture.needsUpdate = true;

            // fill buffer
            var vertexDataStride = vertexDataCount * 4;

            for (i in 0...morphTargetsCount) {
                var morphTarget = morphTargets[i];
                var morphNormal = morphNormals[i];
                var morphColor = morphColors[i];

                var offset = width * height * 4 * i;

                for (j in 0...morphTarget.count) {
                    var stride = j * vertexDataStride;

                    if (hasMorphPosition) {
                        morph.fromBufferAttribute(morphTarget, j);

                        buffer[offset + stride + 0] = morph.x;
                        buffer[offset + stride + 1] = morph.y;
                        buffer[offset + stride + 2] = morph.z;
                        buffer[offset + stride + 3] = 0;
                    }

                    if (hasMorphNormals) {
                        morph.fromBufferAttribute(morphNormal, j);

                        buffer[offset + stride + 4] = morph.x;
                        buffer[offset + stride + 5] = morph.y;
                        buffer[offset + stride + 6] = morph.z;
                        buffer[offset + stride + 7] = 0;
                    }

                    if (hasMorphColors) {
                        morph.fromBufferAttribute(morphColor, j);

                        buffer[offset + stride + 8] = morph.x;
                        buffer[offset + stride + 9] = morph.y;
                        buffer[offset + stride + 10] = morph.z;
                        buffer[offset + stride + 11] = if (morphColor.itemSize == 4) morph.w else 1;
                    }
                }
            }

            entry = {
                count: morphTargetsCount,
                texture: texture,
                size: new Vector2(width, height)
            };

            morphTextures.set(geometry, entry);

            function disposeTexture() {
                texture.dispose();
                morphTextures.delete(geometry);
                geometry.removeEventListener('dispose', disposeTexture);
            }

            geometry.addEventListener('dispose', disposeTexture);
        }

        //
        if (object.isInstancedMesh && object.morphTexture != null) {
            program.getUniforms().setValue(gl, 'morphTexture', object.morphTexture, textures);
        } else {
            var morphInfluencesSum = 0.0;
            for (i in 0...objectInfluences.length) {
                morphInfluencesSum += objectInfluences[i];
            }

            var morphBaseInfluence = if (geometry.morphTargetsRelative) 1.0 else (1.0 - morphInfluencesSum);

            program.getUniforms().setValue(gl, 'morphTargetBaseInfluence', morphBaseInfluence);
            program.getUniforms().setValue(gl, 'morphTargetInfluences', objectInfluences);
        }

        program.getUniforms().setValue(gl, 'morphTargetsTexture', entry.texture, textures);
        program.getUniforms().setValue(gl, 'morphTargetsTextureSize', entry.size);
    }
}

class DataArrayTexture {
    public var width: Int;
    public var height: Int;
    public var type: FloatType;
    public var needsUpdate: Bool;

    public function new(buffer: Float32Array, width: Int, height: Int, count: Int) {
        this.width = width;
        this.height = height;
        this.type = FloatType.Float;
        this.needsUpdate = true;
    }

    public function dispose() {
        // dispose texture
    }
}

enum FloatType {
    Float;
}

class Geometry {
    public var attributes: Dynamic;
    public var morphAttributes: Dynamic;
    public var morphTargetsRelative: Bool;

    public function addEventListener(type: String, listener: Dynamic) {
        // add event listener
    }

    public function removeEventListener(type: String, listener: Dynamic) {
        // remove event listener
    }
}

class Program {
    public function getUniforms() {
        // get uniforms
    }
}

class Capabilities {
    public var maxTextureSize: Int;
}

class Texture {
    public function dispose() {
        // dispose texture
    }
}

class Window {
    public static var window: Window;
}

class WebGLRenderingContext {
    public function getUniformLocation(program: Program, name: String): WebGLUniformLocation {
        // get uniform location
    }
}

class WebGLUniformLocation {
    public function setFloat(gl: GL, v: Float) {
        // set float value
    }

    public function setVector2(gl: GL, v: Vector2) {
        // set vector2 value
    }

    public function setVector4(gl: GL, v: Vector4) {
        // set vector4 value
    }

    public function setValue(gl: GL, v: Float, textures: Array<Texture>) {
        // set value with textures
    }
}