depthWrite: false,
      depthTest: false,
    });
    var backgroundBox = new Mesh(new BoxGeometry(), backgroundMaterial);
    var useSolidColor = false;
    var background = scene.background;
    if (background != null) {
      if (background.isColor) {
        backgroundMaterial.color.copy(background);
        scene.background = null;
        useSolidColor = true;
      }
    } else {
      backgroundMaterial.color.copy(_clearColor);
      useSolidColor = true;
    }
    for (i in 0...6) {
      var col = i % 3;
      if (col == 0) {
        cubeCamera.up.set(0, upSign[i], 0);
        cubeCamera.lookAt(forwardSign[i], 0, 0);
      } else if (col == 1) {
        cubeCamera.up.set(0, 0, upSign[i]);
        cubeCamera.lookAt(0, forwardSign[i], 0);
      } else {
        cubeCamera.up.set(0, upSign[i], 0);
        cubeCamera.lookAt(0, 0, forwardSign[i]);
      }
      var size = this._cubeSize;
      _setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);
      renderer.setRenderTarget(cubeUVRenderTarget);
      if (useSolidColor) {
        renderer.render(backgroundBox, cubeCamera);
      }
      renderer.render(scene, cubeCamera);
    }
    backgroundBox.geometry.dispose();
    backgroundBox.material.dispose();
    renderer.toneMapping = toneMapping;
    renderer.autoClear = originalAutoClear;
    scene.background = background;
  }

  private function _textureToCubeUV(texture:three.textures.Texture, cubeUVRenderTarget:WebGLRenderTarget) {
    var renderer = this._renderer;
    var isCubeTexture = (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping);
    if (isCubeTexture) {
      if (this._cubemapMaterial == null) {
        this._cubemapMaterial = _getCubemapMaterial();
      }
      this._cubemapMaterial.uniforms.flipEnvMap.value = (texture.isRenderTargetTexture == false) ? -1 : 1;
    } else {
      if (this._equirectMaterial == null) {
        this._equirectMaterial = _getEquirectMaterial();
      }
    }
    var material = isCubeTexture ? this._cubemapMaterial : this._equirectMaterial;
    var mesh = new Mesh(this._lodPlanes[0], material);
    var uniforms = material.uniforms;
    uniforms['envMap'].value = texture;
    var size = this._cubeSize;
    _setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);
    renderer.setRenderTarget(cubeUVRenderTarget);
    renderer.render(mesh, _flatCamera);
  }

  private function _applyPMREM(cubeUVRenderTarget:WebGLRenderTarget) {
    var renderer = this._renderer;
    var autoClear = renderer.autoClear;
    renderer.autoClear = false;
    var n = this._lodPlanes.length;
    for (i in 1...n) {
      var sigma = Math.sqrt(this._sigmas[i] * this._sigmas[i] - this._sigmas[i - 1] * this._sigmas[i - 1]);
      var poleAxis = _axisDirections[(n - i - 1) % _axisDirections.length];
      this._blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);
    }
    renderer.autoClear = autoClear;
  }

  /**
   * This is a two-pass Gaussian blur for a cubemap. Normally this is done
   * vertically and horizontally, but this breaks down on a cube. Here we apply
   * the blur latitudinally (around the poles), and then longitudinally (towards
   * the poles) to approximate the orthogonally-separable blur. It is least
   * accurate at the poles, but still does a decent job.
   */
  private function _blur(cubeUVRenderTarget:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3) {
    var pingPongRenderTarget = this._pingPongRenderTarget;
    this._halfBlur(cubeUVRenderTarget, pingPongRenderTarget, lodIn, lodOut, sigma, 'latitudinal', poleAxis);
    this._halfBlur(pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigma, 'longitudinal', poleAxis);
  }

  private function _halfBlur(targetIn:WebGLRenderTarget, targetOut:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigmaRadians:Float, direction:String, poleAxis:Vector3) {
    var renderer = this._renderer;
    var blurMaterial = this._blurMaterial;
    if (direction != 'latitudinal' && direction != 'longitudinal') {
      console.error('blur direction must be either latitudinal or longitudinal!');
    }
    // Number of standard deviations at which to cut off the discrete approximation.
    var STANDARD_DEVIATIONS = 3;
    var blurMesh = new Mesh(this._lodPlanes[lodOut], blurMaterial);
    var blurUniforms = blurMaterial.uniforms;
    var pixels = this._sizeLods[lodIn] - 1;
    var radiansPerPixel = isFinite(sigmaRadians) ? Math.PI / (2 * pixels) : 2 * Math.PI / (2 * MAX_SAMPLES - 1);
    var sigmaPixels = sigmaRadians / radiansPerPixel;
    var samples = isFinite(sigmaRadians) ? 1 + Math.floor(STANDARD_DEVIATIONS * sigmaPixels) : MAX_SAMPLES;
    if (samples > MAX_SAMPLES) {
      console.warn('sigmaRadians, ' + sigmaRadians + ', is too large and will clip, as it requested ' + samples + ' samples when the maximum is set to ' + MAX_SAMPLES);
    }
    var weights = new Array<Float>();
    var sum = 0;
    for (i in 0...MAX_SAMPLES) {
      var x = i / sigmaPixels;
      var weight = Math.exp(- x * x / 2);
      weights.push(weight);
      if (i == 0) {
        sum += weight;
      } else if (i < samples) {
        sum += 2 * weight;
      }
    }
    for (i in 0...weights.length) {
      weights[i] = weights[i] / sum;
    }
    blurUniforms['envMap'].value = targetIn.texture;
    blurUniforms['samples'].value = samples;
    blurUniforms['weights'].value = weights;
    blurUniforms['latitudinal'].value = direction == 'latitudinal';
    if (poleAxis != null) {
      blurUniforms['poleAxis'].value = poleAxis;
    }
    var _lodMax = this._lodMax;
    blurUniforms['dTheta'].value = radiansPerPixel;
    blurUniforms['mipInt'].value = _lodMax - lodIn;
    var outputSize = this._sizeLods[lodOut];
    var x = 3 * outputSize * (lodOut > _lodMax - LOD_MIN ? lodOut - _lodMax + LOD_MIN : 0);
    var y = 4 * (this._cubeSize - outputSize);
    _setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
    renderer.setRenderTarget(targetOut);
    renderer.render(blurMesh, _flatCamera);
  }

}

const LOD_MIN = 4;

// The standard deviations (radians) associated with the extra mips. These are
// chosen to approximate a Trowbridge-Reitz distribution function times the
// geometric shadowing function. These sigma values squared must match the
// variance #defines in cube_uv_reflection_fragment.glsl.js.
const EXTRA_LOD_SIGMA = [0.125, 0.215, 0.35, 0.446, 0.526, 0.582];

// The maximum length of the blur for loop. Smaller sigmas will use fewer
// samples and exit early, but not recompile the shader.
const MAX_SAMPLES = 20;

const _flatCamera = new OrthographicCamera();
const _clearColor = new Color();
var _oldTarget = null;
var _oldActiveCubeFace = 0;
var _oldActiveMipmapLevel = 0;
var _oldXrEnabled = false;

// Golden Ratio
const PHI = (1 + Math.sqrt(5)) / 2;
const INV_PHI = 1 / PHI;

// Vertices of a dodecahedron (except the opposites, which represent the
// same axis), used as axis directions evenly spread on a sphere.
const _axisDirections = [
  new Vector3(-PHI, INV_PHI, 0),
  new Vector3(PHI, INV_PHI, 0),
  new Vector3(-INV_PHI, 0, PHI),
  new Vector3(INV_PHI, 0, PHI),
  new Vector3(0, PHI, -INV_PHI),
  new Vector3(0, PHI, INV_PHI),
  new Vector3(-1, 1, -1),
  new Vector3(1, 1, -1),
  new Vector3(-1, 1, 1),
  new Vector3(1, 1, 1)
];

function _createPlanes(lodMax:Int, sizeLods:Array<Int>, lodPlanes:Array<BufferGeometry>, sigmas:Array<Float>) {
  var lod = lodMax;
  var totalLods = lodMax - LOD_MIN + 1 + EXTRA_LOD_SIGMA.length;
  for (i in 0...totalLods) {
    var sizeLod = Math.pow(2, lod);
    sizeLods.push(sizeLod);
    var sigma = 1.0 / sizeLod;
    if (i > lodMax - LOD_MIN) {
      sigma = EXTRA_LOD_SIGMA[i - lodMax + LOD_MIN - 1];
    } else if (i == 0) {
      sigma = 0;
    }
    sigmas.push(sigma);
    var texelSize = 1.0 / (sizeLod - 2);
    var min = -texelSize;
    var max = 1 + texelSize;
    var uv1 = [min, min, max, min, max, max, min, min, max, max, min, max];
    var cubeFaces = 6;
    var vertices = 6;
    var positionSize = 3;
    var uvSize = 2;
    var faceIndexSize = 1;
    var position = new Float32Array(positionSize * vertices * cubeFaces);
    var uv = new Float32Array(uvSize * vertices * cubeFaces);
    var faceIndex = new Float32Array(faceIndexSize * vertices * cubeFaces);
    for (face in 0...cubeFaces) {
      var x = (face % 3) * 2 / 3 - 1;
      var y = face > 2 ? 0 : -1;
      var coordinates = [
        x, y, 0,
        x + 2 / 3, y, 0,
        x + 2 / 3, y + 1, 0,
        x, y, 0,
        x + 2 / 3, y + 1, 0,
        x, y + 1, 0
      ];
      position.set(coordinates, positionSize * vertices * face);
      uv.set(uv1, uvSize * vertices * face);
      var fill = [face, face, face, face, face, face];
      faceIndex.set(fill, faceIndexSize * vertices * face);
    }
    var planes = new BufferGeometry();
    planes.setAttribute('position', new BufferAttribute(position, positionSize));
    planes.setAttribute('uv', new BufferAttribute(uv, uvSize));
    planes.setAttribute('faceIndex', new BufferAttribute(faceIndex, faceIndexSize));
    lodPlanes.push(planes);
    if (lod > LOD_MIN) {
      lod--;
    }
  }
}

function _createRenderTarget(width:Int, height:Int, params:Dynamic):WebGLRenderTarget {
  var cubeUVRenderTarget = new WebGLRenderTarget(width, height, params);
  cubeUVRenderTarget.texture.mapping = CubeUVReflectionMapping;
  cubeUVRenderTarget.texture.name = 'PMREM.cubeUv';
  cubeUVRenderTarget.scissorTest = true;
  return cubeUVRenderTarget;
}

function _setViewport(target:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int) {
  target.viewport.set(x, y, width, height);
  target.scissor.set(x, y, width, height);
}

function _getBlurShader(lodMax:Int, width:Int, height:Int):ShaderMaterial {
  var weights = new Float32Array(MAX_SAMPLES);
  var poleAxis = new Vector3(0, 1, 0);
  var shaderMaterial = new ShaderMaterial({
    name: 'SphericalGaussianBlur',
    defines: {
      'n': MAX_SAMPLES,
      'CUBEUV_TEXEL_WIDTH': 1.0 / width,
      'CUBEUV_TEXEL_HEIGHT': 1.0 / height,
      'CUBEUV_MAX_MIP': '' + lodMax + '.0',
    },
    uniforms: {
      'envMap': { value: null },
      'samples': { value: 1 },
      'weights': { value: weights },
      'latitudinal': { value: false },
      'dTheta': { value: 0 },
      'mipInt': { value: 0 },
      'poleAxis': { value: poleAxis }
    },
    vertexShader: _getCommonVertexShader(),
    fragmentShader: /* glsl */`
      precision mediump float;
      precision mediump int;
      varying vec3 vOutputDirection;
      uniform sampler2D envMap;
      uniform int samples;
      uniform float weights[ n ];
      uniform bool latitudinal;
      uniform float dTheta;
      uniform float mipInt;
      uniform vec3 poleAxis;
      #define ENVMAP_TYPE_CUBE_UV
      #include <cube_uv_reflection_fragment>
      vec3 getSample( float theta, vec3 axis ) {
        float cosTheta = cos( theta );
        // Rodrigues' axis-angle rotation
        vec3 sampleDirection = vOutputDirection * cosTheta
          + cross( axis, vOutputDirection ) * sin( theta )
          + axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );
        return bilinearCubeUV( envMap, sampleDirection, mipInt );
      }
      void main() {
        vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );
        if ( all( equal( axis, vec3( 0.0 ) ) ) ) {
          axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );
        }
        axis = normalize( axis );
        gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
        gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );
        for ( int i = 1; i < n; i++ ) {
          if ( i >= samples ) {
            break;
          }
          float theta = dTheta * float( i );
          gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
          gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );
        }
      }
    `,
    blending: NoBlending,
    depthTest: false,
    depthWrite: false
  });
  return shaderMaterial;
}

function _getEquirectMaterial():ShaderMaterial {
  return new ShaderMaterial({
    name: 'EquirectangularToCubeUV',
    uniforms: {
      'envMap': { value: null }
    },
    vertexShader: _getCommonVertexShader(),
    fragmentShader: /* glsl */`
      precision mediump float;
      precision mediump int;
      varying vec3 vOutputDirection;
      uniform sampler2D envMap;
      #include <common>
      void main() {
        vec3 outputDirection = normalize( vOutputDirection );
        vec2 uv = equirectUv( outputDirection );
        gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );
      }
    `,
    blending: NoBlending,
    depthTest: false,
    depthWrite: false
  });
}

function _getCubemapMaterial():ShaderMaterial {
  return new ShaderMaterial({
    name: 'CubemapToCubeUV',
    uniforms: {
      'envMap': { value: null },
      'flipEnvMap': { value: -1 }
    },
    vertexShader: _getCommonVertexShader(),
    fragmentShader: /* glsl */`
      precision mediump float;
      precision mediump int;
      uniform float flipEnvMap;
      varying vec3 vOutputDirection;
      uniform samplerCube envMap;
      void main() {
        gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );
      }
    `,
    blending: NoBlending,
    depthTest: false,
    depthWrite: false
  });
}

function _getCommonVertexShader():String {
  return /* glsl */`
    precision mediump float;
    precision mediump int;
    attribute float faceIndex;
    varying vec3 vOutputDirection;
    // RH coordinate system; PMREM face-indexing convention
    vec3 getDirection( vec2 uv, float face ) {
      uv = 2.0 * uv - 1.0;
      vec3 direction = vec3( uv, 1.0 );
      if ( face == 0.0 ) {
        direction = direction.zyx; // ( 1, v, u ) pos x
      } else if ( face == 1.0 ) {
        direction = direction.xzy;
        direction.xz *= -1.0; // ( -u, 1, -v ) pos y
      } else if ( face == 2.0 ) {
        direction.x *= -1.0; // ( -u, v, 1 ) pos z
      } else if ( face == 3.0 ) {
        direction = direction.zyx;
        direction.xz *= -1.0; // ( -1, v, -u ) neg x
      } else if ( face == 4.0 ) {
        direction = direction.xzy;
        direction.xy *= -1.0; // ( -u, -1, v ) neg y
      } else if ( face == 5.0 ) {
        direction.z *= -1.0; // ( u, v, -1 ) neg z
      }
      return direction;
    }
    void main() {
      vOutputDirection = getDirection( uv, faceIndex );
      gl_Position = vec4( position, 1.0 );
    }
  `;
}