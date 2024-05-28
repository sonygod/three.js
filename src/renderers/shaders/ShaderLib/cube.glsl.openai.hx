package three.renderers.shaders.ShaderLib;

class CubeShader {
  public static var vertex = "
    varying vec3 vWorldDirection;

    #include <common>

    void main() {
      vWorldDirection = transformDirection(position, modelMatrix);
      #include <begin_vertex>
      #include <project_vertex>
      gl_Position.z = gl_Position.w; // set z to camera.far
    }
  ";

  public static var fragment = "
    uniform samplerCube tCube;
    uniform float tFlip;
    uniform float opacity;

    varying vec3 vWorldDirection;

    void main() {
      vec4 texColor = textureCube(tCube, vec3(tFlip * vWorldDirection.x, vWorldDirection.yz));
      gl_FragColor = texColor;
      gl_FragColor.a *= opacity;
      #include <tonemapping_fragment>
      #include <colorspace_fragment>
    }
  ";
}