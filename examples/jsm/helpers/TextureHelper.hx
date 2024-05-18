Here is the converted Haxe code:
```
package three.js.examples.jsm.helpers;

import three.js.BufferAttribute;
import three.js.DoubleSide;
import three.js.Mesh;
import three.js.PlaneGeometry;
import three.js.ShaderMaterial;
import three.js.Vector3;
import three.js.BoxGeometry;

class TextureHelper extends Mesh {

    public var texture:Dynamic;
    public var type:String;

    public function new(texture:Dynamic, width:Float = 1, height:Float = 1, depth:Float = 1) {
        super(createGeometry(texture, width, height, depth), createMaterial(texture));
        this.texture = texture;
        this.type = 'TextureHelper';
    }

    public function dispose():Void {
        geometry.dispose();
        material.dispose();
    }

    static function getSamplerType(texture:Dynamic):String {
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

    static function getImageCount(texture:Dynamic):Int {
        if (texture.isCubeTexture) {
            return 6;
        } else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
            return texture.image.depth;
        } else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
            return texture.image.depth;
        } else {
            return 1;
        }
    }

    static function getAlpha(texture:Dynamic):Float {
        if (texture.isCubeTexture) {
            return 1;
        } else if (texture.isDataArrayTexture || texture.isCompressedArrayTexture) {
            return Math.max(1 / texture.image.depth, 0.25);
        } else if (texture.isData3DTexture || texture.isCompressed3DTexture) {
            return Math.max(1 / texture.image.depth, 0.25);
        } else {
            return 1;
        }
    }

    static function createCubeGeometry(width:Float, height:Float, depth:Float):Geometry {
        var geometry:Geometry = new BoxGeometry(width, height, depth);
        var position:BufferAttribute = geometry.getAttribute('position');
        var uv:BufferAttribute = geometry.getAttribute('uv');
        var uvw:BufferAttribute = new BufferAttribute(new Float32Array(uv.count * 3), 3);
        var direction:Vector3 = new Vector3();

        for (j in 0...uv.count) {
            direction.fromBufferAttribute(position, j).normalize();
            var u:Float = direction.x;
            var v:Float = direction.y;
            var w:Float = direction.z;
            uvw.setXYZ(j, u, v, w);
        }

        geometry.deleteAttribute('uv');
        geometry.setAttribute('uvw', uvw);

        return geometry;
    }

    static function createSliceGeometry(texture:Dynamic, width:Float, height:Float, depth:Float):Geometry {
        var sliceCount:Int = getImageCount(texture);
        var geometries:Array<Geometry> = [];

        for (i in 0...sliceCount) {
            var geometry:Geometry = new PlaneGeometry(width, height);

            if (sliceCount > 1) {
                geometry.translate(0, 0, depth * (i / (sliceCount - 1) - 0.5));
            }

            var uv:BufferAttribute = geometry.getAttribute('uv');
            var uvw:BufferAttribute = new BufferAttribute(new Float32Array(uv.count * 3), 3);

            for (j in 0...uv.count) {
                var u:Float = uv.getX(j);
                var v:Float = texture.flipY ? uv.getY(j) : 1 - uv.getY(j);
                var w:Float = sliceCount == 1 ? 1 : texture.isDataArrayTexture || texture.isCompressedArrayTexture ? i : i / (sliceCount - 1);
                uvw.setXYZ(j, u, v, w);
            }

            geometry.deleteAttribute('uv');
            geometry.setAttribute('uvw', uvw);

            geometries.push(geometry);
        }

        return mergeGeometries(geometries);
    }

    static function createMaterial(texture:Dynamic):ShaderMaterial {
        var material:ShaderMaterial = new ShaderMaterial({
            type: 'TextureHelperMaterial',
            side: DoubleSide,
            transparent: true,
            uniforms: {
                map: { value: texture },
                alpha: { value: getAlpha(texture) }
            },
            vertexShader: [
                'attribute vec3 uvw;',
                'varying vec3 vUvw;',
                'void main() {',
                '   vUvw = uvw;',
                '   gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
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
                '   gl_FragColor = linearToOutputTexel( vec4( textureHelper( map ).xyz, alpha ) );',
                '}'
            ].join('\n').replace('{samplerType}', getSamplerType(texture))
        });

        return material;
    }

    static function createGeometry(texture:Dynamic, width:Float, height:Float, depth:Float):Geometry {
        return texture.isCubeTexture ? createCubeGeometry(width, height, depth) : createSliceGeometry(texture, width, height, depth);
    }
}
```
Note that I've used the Haxe `Dynamic` type to represent the `texture` object, as its type is not explicitly defined in the JavaScript code. Additionally, I've assumed that the `linearToOutputTexel` function is defined elsewhere in the codebase, as it is not defined in this file.