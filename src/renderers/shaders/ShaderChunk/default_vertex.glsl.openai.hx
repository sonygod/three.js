package three.js.renderers.shaders.ShaderChunk;

#if glsl
extern class DefaultVertex {
  public static function main():Void {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
}
#end