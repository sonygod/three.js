// File path: three.js/examples/jsm/modifiers/CurveModifier.hx

import three.DataTexture;
import three.DataUtils;
import three.RGBAFormat;
import three.HalfFloatType;
import three.RepeatWrapping;
import three.Mesh;
import three.InstancedMesh;
import three.LinearFilter;
import three.DynamicDrawUsage;
import three.Matrix4;

class CurveModifier {

    static const CHANNELS:Int = 4;
    static const TEXTURE_WIDTH:Int = 1024;
    static const TEXTURE_HEIGHT:Int = 4;

    public static function initSplineTexture(numberOfCurves:Int = 1):DataTexture {

        var dataArray = new Uint16Array(TEXTURE_WIDTH * TEXTURE_HEIGHT * numberOfCurves * CHANNELS);
        var dataTexture = new DataTexture(dataArray, TEXTURE_WIDTH, TEXTURE_HEIGHT * numberOfCurves, RGBAFormat, HalfFloatType);

        dataTexture.wrapS = RepeatWrapping;
        dataTexture.wrapY = RepeatWrapping;
        dataTexture.magFilter = LinearFilter;
        dataTexture.minFilter = LinearFilter;
        dataTexture.needsUpdate = true;

        return dataTexture;
    }

    public static function updateSplineTexture(texture:DataTexture, splineCurve:Curve, offset:Int = 0):Void {

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

    private static function setTextureValue(texture:DataTexture, index:Int, x:Float, y:Float, z:Float, o:Int):Void {

        var image = texture.image;
        var data = image.data;
        var i = CHANNELS * TEXTURE_WIDTH * o; // Row Offset
        data[index * CHANNELS + i + 0] = DataUtils.toHalfFloat(x);
        data[index * CHANNELS + i + 1] = DataUtils.toHalfFloat(y);
        data[index * CHANNELS + i + 2] = DataUtils.toHalfFloat(z);
        data[index * CHANNELS + i + 3] = DataUtils.toHalfFloat(1);
    }

    public static function getUniforms(splineTexture:DataTexture):Dynamic {

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

    public static function modifyShader(material:Dynamic, uniforms:Dynamic, numberOfCurves:Int = 1):Void {

        if (material.__ok) return;
        material.__ok = true;

        material.onBeforeCompile = function(shader) {

            if (shader.__modified) return;
            shader.__modified = true;

            for (key in uniforms) {
                shader.uniforms[key] = uniforms[key];
            }

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
            // chunk import moved in front of modified shader below
                .replace('#include <beginnormal_vertex>', '')

                // vec3 transformedNormal declaration overriden below
                .replace('#include <defaultnormal_vertex>', '')

                // vec3 transformed declaration overriden below
                .replace('#include <begin_vertex>', '')

                // shader override
                .replace(
                    /void\s*main\s*\(\)\s*\{/,
                    `
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
                    `
                ).replace(
                    '#include <project_vertex>',
                    `vec4 mvPosition = modelViewMatrix * vec4( transformed, 1.0 );
                    gl_Position = projectionMatrix * mvPosition;`
                );

            shader.vertexShader = vertexShader;
        };
    }

    public class Flow {

        public var curveArray:Array<Curve>;
        public var curveLengthArray:Array<Float>;
        public var object3D:Dynamic;
        public var splineTexure:DataTexture;
        public var uniforms:Dynamic;

        public function new(mesh:Dynamic, numberOfCurves:Int = 1) {

            var obj3D = mesh.clone();
            this.splineTexure = initSplineTexture(numberOfCurves);
            this.uniforms = getUniforms(this.splineTexure);
            obj3D.traverse(function(child) {

                if (
                    child instanceof Mesh ||
                    child instanceof InstancedMesh
                ) {

                    if (child.material is Array<Dynamic>) {

                        var materials = [];

                        for (material in child.material) {

                            var newMaterial = material.clone();
                            modifyShader(newMaterial, this.uniforms, numberOfCurves);
                            materials.push(newMaterial);
                        }

                        child.material = materials;

                    } else {

                        child.material = child.material.clone();
                        modifyShader(child.material, this.uniforms, numberOfCurves);
                    }
                }
            });

            this.curveArray = new Array<Curve>(numberOfCurves);
            this.curveLengthArray = new Array<Float>(numberOfCurves);

            this.object3D = obj3D;
        }

        public function updateCurve(index:Int, curve:Curve):Void {

            if (index >= this.curveArray.length) throw Error('Index out of range for Flow');
            var curveLength = curve.getLength();
            this.uniforms.spineLength.value = curveLength;
            this.curveLengthArray[index] = curveLength;
            this.curveArray[index] = curve;
            updateSplineTexture(this.splineTexure, curve, index);
        }

        public function moveAlongCurve(amount:Float):Void {

            this.uniforms.pathOffset.value += amount;
        }
    }

    public class InstancedFlow extends Flow {

        public var offsets:Array<Float>;
        public var whichCurve:Array<Int>;

        public function new(count:Int, curveCount:Int, geometry:Dynamic, material:Dynamic) {

            var mesh = new InstancedMesh(geometry, material, count);
            mesh.instanceMatrix.setUsage(DynamicDrawUsage);
            mesh.frustumCulled = false;
            super(mesh, curveCount);

            this.offsets = new Array<Float>(count).fill(0);
            this.whichCurve = new Array<Int>(count).fill(0);
        }

        public function writeChanges(index:Int):Void {

            var matrix = new Matrix4();
            matrix.makeTranslation(
                this.curveLengthArray[this.whichCurve[index]],
                this.whichCurve[index],
                this.offsets[index]
            );
            this.object3D.setMatrixAt(index, matrix);
            this.object3D.instanceMatrix.needsUpdate = true;
        }

        public function moveIndividualAlongCurve(index:Int, offset:Float):Void {

            this.offsets[index] += offset;
            this.writeChanges(index);
        }

        public function setCurve(index:Int, curveNo:Int):Void {

            if (isNaN(curveNo)) throw Error('curve index being set is Not a Number (NaN)');
            this.whichCurve[index] = curveNo;
            this.writeChanges(index);
        }
    }
}