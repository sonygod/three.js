import three.extras.curves.Curve;
import three.math.Matrix4;
import three.math.Vector3;
import three.materials.Material;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.objects.InstancedMesh;
import three.textures.DataTexture;
import three.textures.Texture;
import three.textures.TextureEncoding;
import three.textures.TextureFilter;
import three.textures.TextureFormat;
import three.textures.TextureWrapping;
import three.utils.DataUtils;

class Flow {
  public var curveArray:Array<Curve>;
  public var curveLengthArray:Array<Float>;
  public var object3D:Mesh;
  public var splineTexure:DataTexture;
  public var uniforms:Dynamic<Dynamic>;
  public var numberOfCurves:Int;

  public function new(mesh:Mesh, numberOfCurves:Int = 1) {
    this.numberOfCurves = numberOfCurves;
    this.object3D = mesh.clone();
    this.splineTexure = initSplineTexture(numberOfCurves);
    this.uniforms = getUniforms(this.splineTexure);
    this.object3D.traverse((child:Dynamic) -> {
      if (Std.is(child, Mesh) || Std.is(child, InstancedMesh)) {
        if (Std.is(child.material, Array)) {
          var materials:Array<Material> = [];
          for (material in child.material) {
            var newMaterial = material.clone();
            modifyShader(newMaterial, this.uniforms, this.numberOfCurves);
            materials.push(newMaterial);
          }
          child.material = materials;
        } else {
          child.material = child.material.clone();
          modifyShader(child.material, this.uniforms, this.numberOfCurves);
        }
      }
    });
    this.curveArray = new Array(this.numberOfCurves);
    this.curveLengthArray = new Array(this.numberOfCurves);
  }

  public function updateCurve(index:Int, curve:Curve) {
    if (index >= this.curveArray.length) throw "Index out of range for Flow";
    var curveLength = curve.getLength();
    this.uniforms.get("spineLength").value = curveLength;
    this.curveLengthArray[index] = curveLength;
    this.curveArray[index] = curve;
    updateSplineTexture(this.splineTexure, curve, index);
  }

  public function moveAlongCurve(amount:Float) {
    this.uniforms.get("pathOffset").value += amount;
  }
}

class InstancedFlow extends Flow {
  public var offsets:Array<Float>;
  public var whichCurve:Array<Int>;

  public function new(count:Int, curveCount:Int, geometry:Dynamic, material:Material) {
    super(new InstancedMesh(geometry, material, count), curveCount);
    this.offsets = new Array(count).fill(0);
    this.whichCurve = new Array(count).fill(0);
    (this.object3D : InstancedMesh).instanceMatrix.setUsage(DynamicDrawUsage);
    (this.object3D : InstancedMesh).frustumCulled = false;
  }

  public function writeChanges(index:Int) {
    var matrix = new Matrix4();
    matrix.makeTranslation(this.curveLengthArray[this.whichCurve[index]], this.whichCurve[index], this.offsets[index]);
    (this.object3D : InstancedMesh).setMatrixAt(index, matrix);
    (this.object3D : InstancedMesh).instanceMatrix.needsUpdate = true;
  }

  public function moveIndividualAlongCurve(index:Int, offset:Float) {
    this.offsets[index] += offset;
    this.writeChanges(index);
  }

  public function setCurve(index:Int, curveNo:Int) {
    if (Math.isNaN(curveNo)) throw "curve index being set is Not a Number (NaN)";
    this.whichCurve[index] = curveNo;
    this.writeChanges(index);
  }
}

const CHANNELS:Int = 4;
const TEXTURE_WIDTH:Int = 1024;
const TEXTURE_HEIGHT:Int = 4;

function initSplineTexture(numberOfCurves:Int = 1):DataTexture {
  var dataArray = new Uint16Array(TEXTURE_WIDTH * TEXTURE_HEIGHT * numberOfCurves * CHANNELS);
  var dataTexture = new DataTexture(dataArray, TEXTURE_WIDTH, TEXTURE_HEIGHT * numberOfCurves, TextureFormat.RGBAFormat, TextureEncoding.LinearEncoding, null, HalfFloatType);
  dataTexture.wrapS = TextureWrapping.RepeatWrapping;
  dataTexture.wrapY = TextureWrapping.RepeatWrapping;
  dataTexture.magFilter = TextureFilter.LinearFilter;
  dataTexture.minFilter = TextureFilter.LinearFilter;
  dataTexture.needsUpdate = true;
  return dataTexture;
}

function updateSplineTexture(texture:DataTexture, splineCurve:Curve, offset:Int = 0) {
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

function setTextureValue(texture:DataTexture, index:Int, x:Float, y:Float, z:Float, o:Int) {
  var image = texture.image;
  var data = image.data;
  var i = CHANNELS * TEXTURE_WIDTH * o;
  data[index * CHANNELS + i + 0] = DataUtils.toHalfFloat(x);
  data[index * CHANNELS + i + 1] = DataUtils.toHalfFloat(y);
  data[index * CHANNELS + i + 2] = DataUtils.toHalfFloat(z);
  data[index * CHANNELS + i + 3] = DataUtils.toHalfFloat(1);
}

function getUniforms(splineTexture:DataTexture):Dynamic<Dynamic> {
  return {
    spineTexture: { value: splineTexture },
    pathOffset: { type: "f", value: 0 },
    pathSegment: { type: "f", value: 1 },
    spineOffset: { type: "f", value: 161 },
    spineLength: { type: "f", value: 400 },
    flow: { type: "i", value: 1 },
  };
}

function modifyShader(material:ShaderMaterial, uniforms:Dynamic<Dynamic>, numberOfCurves:Int) {
  if (material.__ok) return;
  material.__ok = true;
  material.onBeforeCompile = (shader:Dynamic) -> {
    if (shader.__modified) return;
    shader.__modified = true;
    shader.uniforms = cast shader.uniforms;
    shader.uniforms = cast shader.uniforms;
    shader.uniforms = cast shader.uniforms;
    shader.uniforms = cast shader.uniforms;
    shader.uniforms = cast shader.uniforms;
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
    .replace("#include <beginnormal_vertex>", "")
    .replace("#include <defaultnormal_vertex>", "")
    .replace("#include <begin_vertex>", "")
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
			`)
    .replace("#include <project_vertex>", `vec4 mvPosition = modelViewMatrix * vec4( transformed, 1.0 );
				gl_Position = projectionMatrix * mvPosition;`);
    shader.vertexShader = vertexShader;
  };
}