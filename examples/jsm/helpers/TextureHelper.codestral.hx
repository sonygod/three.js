import three.BufferAttribute;
import three.BoxGeometry;
import three.DoubleSide;
import three.Mesh;
import three.PlaneGeometry;
import three.ShaderMaterial;
import three.Texture;
import three.Vector3;

class TextureHelper extends Mesh {
    public var texture: Texture;

    public function new(texture: Texture, width: Float = 1.0, height: Float = 1.0, depth: Float = 1.0) {
        super(null, null);

        var material = new ShaderMaterial({
            type: 'TextureHelperMaterial',
            side: DoubleSide,
            transparent: true,
            uniforms: {
                'map': { value: texture },
                'alpha': { value: getAlpha(texture) }
            },
            vertexShader: [
                'attribute vec3 uvw;',
                'varying vec3 vUvw;',
                'void main() {',
                '    vUvw = uvw;',
                '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
                '}'
            ].join('\n'),
            fragmentShader: [
                'precision highp float;',
                'precision highp sampler2DArray;',
                'precision highp sampler3D;',
                'uniform {samplerType} map;',
                'uniform float alpha;',
                'varying vec3 vUvw;',
                'vec4 textureHelper( in sampler2D map ) { return texture( map, vUvw.xy ); }',
                'vec4 textureHelper( in sampler2DArray map ) { return texture( map, vUvw ); }',
                'vec4 textureHelper( in sampler3D map ) { return texture( map, vUvw ); }',
                'vec4 textureHelper( in samplerCube map ) { return texture( map, vUvw ); }',
                'void main() {',
                '    gl_FragColor = linearToOutputTexel( vec4( textureHelper( map ).xyz, alpha ) );',
                '}'
            ].join('\n').replace('{samplerType}', getSamplerType(texture))
        });

        var geometry = texture.isCubeTexture
            ? createCubeGeometry(width, height, depth)
            : createSliceGeometry(texture, width, height, depth);

        this.geometry = geometry;
        this.material = material;

        this.texture = texture;
        this.type = 'TextureHelper';
    }

    public function dispose(): Void {
        this.geometry.dispose();
        this.material.dispose();
    }

    private function getSamplerType(texture: Texture): String {
        if (texture.isCubeTexture) {
            return 'samplerCube';
        } else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
            return 'sampler2DArray';
        } else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
            return 'sampler3D';
        } else {
            return 'sampler2D';
        }
    }

    private function getAlpha(texture: Texture): Float {
        if (texture.isCubeTexture) {
            return 1.0;
        } else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
            return Math.max(1.0 / texture.image.depth, 0.25);
        } else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
            return Math.max(1.0 / texture.image.depth, 0.25);
        } else {
            return 1.0;
        }
    }

    private function createCubeGeometry(width: Float, height: Float, depth: Float): BufferGeometry {
        var geometry = new BoxGeometry(width, height, depth);
        var position = geometry.attributes.position;
        var uv = geometry.attributes.uv;
        var uvw = new BufferAttribute(new Float(uv.count * 3), 3);

        var _direction = new Vector3();

        for (var j: Int = 0; j < uv.count; ++j) {
            _direction.fromBufferAttribute(position, j).normalize();
            var u = _direction.x;
            var v = _direction.y;
            var w = _direction.z;
            uvw.setXYZ(j, u, v, w);
        }

        geometry.deleteAttribute('uv');
        geometry.setAttribute('uvw', uvw);

        return geometry;
    }

    // Note: The createSliceGeometry function is not included here due to the lack of a direct equivalent to three.js's mergeGeometries function in Haxe.
}