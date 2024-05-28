Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.shader;

class EnvmapPhysicalParsFragment {
  public static function getIBLIrradiance(normal:Vec3):Vec3 {
    #if USE_ENVMAP
      #if ENVMAP_TYPE_CUBE_UV
        var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);
        var envMapColor:Vec4 = textureCubeUV(envMap, envMapRotation * worldNormal, 1.0);
        return PI * envMapColor.rgb * envMapIntensity;
      #else
        return new Vec3(0.0, 0.0, 0.0);
      #end
    #end
  }

  public static function getIBLRadiance(viewDir:Vec3, normal:Vec3, roughness:Float):Vec3 {
    #if USE_ENVMAP
      #if ENVMAP_TYPE_CUBE_UV
        var reflectVec:Vec3 = reflect(-viewDir, normal);
        reflectVec = normalize(mix(reflectVec, normal, roughness * roughness));
        reflectVec = inverseTransformDirection(reflectVec, viewMatrix);
        var envMapColor:Vec4 = textureCubeUV(envMap, envMapRotation * reflectVec, roughness);
        return envMapColor.rgb * envMapIntensity;
      #else
        return new Vec3(0.0, 0.0, 0.0);
      #end
    #end
  }

  #if USE_ANISOTROPY
  public static function getIBLAnisotropyRadiance(viewDir:Vec3, normal:Vec3, roughness:Float, bitangent:Vec3, anisotropy:Float):Vec3 {
    #if ENVMAP_TYPE_CUBE_UV
      var bentNormal:Vec3 = cross(bitangent, viewDir);
      bentNormal = normalize(cross(bentNormal, bitangent));
      bentNormal = normalize(mix(bentNormal, normal, Math.pow(1.0 - anisotropy * (1.0 - roughness), 2)));
      return getIBLRadiance(viewDir, bentNormal, roughness);
    #else
      return new Vec3(0.0, 0.0, 0.0);
    #end
  }
  #end
}
```
Note that I've assumed that `Vec3` and `Vec4` are Haxe types representing 3D and 4D vectors, respectively. I've also assumed that `textureCubeUV`, `inverseTransformDirection`, and `reflect` are functions that are defined elsewhere in the codebase.

Also, I've used Haxe's conditional compilation directives (`#if` and `#else`) to replicate the behavior of the JavaScript code.