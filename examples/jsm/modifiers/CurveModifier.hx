package three.js.examples.jsm.modifiers;

import three.data.DataTexture;
import three.data.DataUtils;
import three.formats.RGBAFormat;
import three.formats.HalfFloatType;
import three.textures.RepeatWrapping;
import three.mesh.Mesh;
import three.mesh.InstancedMesh;
import three.filters.LinearFilter;
import three.core.Matrix4;

class CurveModifier {
    static inline var CHANNELS = 4;
    static inline var TEXTURE_WIDTH = 1024;
    static inline var TEXTURE_HEIGHT = 4;

    static function initSplineTexture(numberOfCurves:Int = 1):DataTexture {
        var dataArray = new Uint16Array(TEXTURE_WIDTH * TEXTURE_HEIGHT * numberOfCurves * CHANNELS);
        var dataTexture = new DataTexture(
            dataArray,
            TEXTURE_WIDTH,
            TEXTURE_HEIGHT * numberOfCurves,
            RGBAFormat,
            HalfFloatType
        );

        dataTexture.wrapS = RepeatWrapping;
        dataTexture.wrapY = RepeatWrapping;
        dataTexture.magFilter = LinearFilter;
        dataTexture.minFilter = LinearFilter;
        dataTexture.needsUpdate = true;

        return dataTexture;
    }

    static function updateSplineTexture(texture:DataTexture, splineCurve:Curve, offset:Int = 0) {
        var numberOfPoints = Math.floor(TEXTURE_WIDTH * (TEXTURE_HEIGHT / 4));
        splineCurve.arcLengthDivisions = numberOfPoints / 2;
        splineCurve.updateArcLengths();
        var points = splineCurve.getSpacedPoints(numberOfPoints);
        var frenetFrames = splineCurve.computeFrenetFrames(numberOfPoints, true);

        for (i in 0...numberOfPoints) {
            var rowOffset = Math.floor(i / TEXTURE_WIDTH);
            var rowIndex = i % TEXTURE_WIDTH;

            var pt = points[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 0 + rowOffset + (TEXTURE_HEIGHT * offset));
            pt = frenetFrames.tangents[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 1 + rowOffset + (TEXTURE_HEIGHT * offset));
            pt = frenetFrames.normals[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 2 + rowOffset + (TEXTURE_HEIGHT * offset));
            pt = frenetFrames.binormals[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 3 + rowOffset + (TEXTURE_HEIGHT * offset));
        }

        texture.needsUpdate = true;
    }

    static function setTextureValue(texture:DataTexture, index:Int, x:Float, y:Float, z:Float, o:Int) {
        var image = texture.image;
        var data = image.data;
        var i = CHANNELS * TEXTURE_WIDTH * o; // Row Offset
        data[index * CHANNELS + i + 0] = DataUtils.toHalfFloat(x);
        data[index * CHANNELS + i + 1] = DataUtils.toHalfFloat(y);
        data[index * CHANNELS + i + 2] = DataUtils.toHalfFloat(z);
        data[index * CHANNELS + i + 3] = DataUtils.toHalfFloat(1);
    }

    static function getUniforms(splineTexture:DataTexture) {
        var uniforms = {
            spineTexture: { value: splineTexture },
            pathOffset: { type: 'f', value: 0 }, // time of path curve
            pathSegment: { type: 'f', value: 1 }, // fractional length of path
            spineOffset: { type: 'f', value: 161 },
            spineLength: { type: 'f', value: 400 },
            flow: { type: 'i', value: 1 },
        };
        return uniforms;
    }

    static function modifyShader(material, uniforms, numberOfCurves:Int = 1) {
        if (material.__ok) return;
        material.__ok = true;

        material.onBeforeCompile = function(shader) {
            if (shader.__modified) return;
            shader.__modified = true;

            Object.assign(shader.uniforms, uniforms);

            var vertexShader = `
            uniform sampler2D spineTexture;
            uniform float pathOffset;
            uniform float pathSegment;
            uniform float spineOffset;
            uniform float spineLength;
            uniform int flow;

            float textureLayers = ${TEXTURE_HEIGHT * numberOfCurves}.;
            float textureStacks = ${TEXTURE_HEIGHT / 4}.;

            ${shader.vertexShader}
            `
            .replace('#include <beginnormal_vertex>', '')
            .replace('#include <defaultnormal_vertex>', '')
            .replace('#include <begin_vertex>', '')
            .replace(/void\s*main\s*\(\)\s*\{/, `
            void main() {
                #include <beginnormal_vertex>

                vec4 worldPos = modelMatrix * vec4(position, 1.);

                bool bend = flow > 0;
                float xWeight = bend ? 0. : 1.;

                #ifdef USE_INSTANCING
                float pathOffsetFromInstanceMatrix = instanceMatrix[3][2];
                float spineLengthFromInstanceMatrix = instanceMatrix[3][0];
                float spinePortion = bend ? (worldPos.x + spineOffset) / spineLengthFromInstanceMatrix : 0.;
                float mt = (spinePortion * pathSegment + pathOffset + pathOffsetFromInstanceMatrix)*textureStacks;
                #else
                float spinePortion = bend ? (worldPos.x + spineOffset) / spineLength : 0.;
                float mt = (spinePortion * pathSegment + pathOffset)*textureStacks;
                #endif

                mt = mod(mt, textureStacks);
                float rowOffset = floor(mt);

                #ifdef USE_INSTANCING
                rowOffset += instanceMatrix[3][1] * ${TEXTURE_HEIGHT}.;
                #endif

                vec3 spinePos = texture2D(spineTexture, vec2(mt, (0. + rowOffset + 0.5) / textureLayers)).xyz;
                vec3 a =        texture2D(spineTexture, vec2(mt, (1. + rowOffset + 0.5) / textureLayers)).xyz;
                vec3 b =        texture2D(spineTexture, vec2(mt, (2. + rowOffset + 0.5) / textureLayers)).xyz;
                vec3 c =        texture2D(spineTexture, vec2(mt, (3. + rowOffset + 0.5) / textureLayers)).xyz;
                mat3 basis = mat3(a, b, c);

                vec3 transformed = basis
                    * vec3(worldPos.x * xWeight, worldPos.y * 1., worldPos.z * 1.)
                    + spinePos;

                vec3 transformedNormal = normalMatrix * (basis * objectNormal);
            `).replace('#include <project_vertex>', `
            vec4 mvPosition = modelViewMatrix * vec4( transformed, 1.0 );
            gl_Position = projectionMatrix * mvPosition;
            `);

            shader.vertexShader = vertexShader;
        };
    }

    static class Flow {
        var curveArray:Array<Curve>;
        var curveLengthArray:Array<Float>;
        var object3D:Object3D;
        var splineTexure:DataTexture;
        var uniforms:Dynamic;

        public function new(mesh:Mesh, numberOfCurves:Int = 1) {
            var obj3D:Object3D = mesh.clone();
            var splineTexure:DataTexture = initSplineTexture(numberOfCurves);
            var uniforms:Dynamic = getUniforms(splineTexure);
            obj3D.traverse(function(child) {
                if (child instanceof Mesh || child instanceof InstancedMesh) {
                    if (Std.is(child.material, Array)) {
                        var materials:Array<Material> = [];
                        for (material in child.material) {
                            var newMaterial:Material = material.clone();
                            modifyShader(newMaterial, uniforms, numberOfCurves);
                            materials.push(newMaterial);
                        }
                        child.material = materials;
                    } else {
                        child.material = child.material.clone();
                        modifyShader(child.material, uniforms, numberOfCurves);
                    }
                }
            });

            this.curveArray = new Array<Curve>(numberOfCurves);
            this.curveLengthArray = new Array<Float>(numberOfCurves);

            this.object3D = obj3D;
            this.splineTexure = splineTexure;
            this.uniforms = uniforms;
        }

        public function updateCurve(index:Int, curve:Curve) {
            if (index >= this.curveArray.length) throw 'Index out of range for Flow';
            var curveLength:Float = curve.getLength();
            this.uniforms.spineLength.value = curveLength;
            this.curveLengthArray[index] = curveLength;
            this.curveArray[index] = curve;
            updateSplineTexture(this.splineTexure, curve, index);
        }

        public function moveAlongCurve(amount:Float) {
            this.uniforms.pathOffset.value += amount;
        }
    }

    static class InstancedFlow extends Flow {
        var offsets:Array<Float>;
        var whichCurve:Array<Int>;

        public function new(count:Int, curveCount:Int, geometry:Geometry, material:Material) {
            var mesh:InstancedMesh = new InstancedMesh(geometry, material, count);
            mesh.instanceMatrix.setUsage(DynamicDrawUsage);
            mesh.frustumCulled = false;
            super(mesh, curveCount);

            this.offsets = new Array<Float>(count).fill(0);
            this.whichCurve = new Array<Int>(count).fill(0);
        }

        public function writeChanges(index:Int) {
            var matrix:Matrix4 = new Matrix4();
            matrix.makeTranslation(this.curveLengthArray[this.whichCurve[index]], this.whichCurve[index], this.offsets[index]);
            this.object3D.setMatrixAt(index, matrix);
            this.object3D.instanceMatrix.needsUpdate = true;
        }

        public function moveIndividualAlongCurve(index:Int, offset:Float) {
            this.offsets[index] += offset;
            this.writeChanges(index);
        }

        public function setCurve(index:Int, curveNo:Int) {
            if (Math.isNaN(curveNo)) throw 'curve index being set is Not a Number (NaN)';
            this.whichCurve[index] = curveNo;
            this.writeChanges(index);
        }
    }
}