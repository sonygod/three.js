class Main {
  public static function main(): Void {
    // No need for a separate string variable, directly use the Haxe macro
    var glslCode: String = macro {
      #if macro
        #ifdef USE_ENVMAP
        
          #if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
        
            #define ENV_WORLDPOS
        
          #end
        
          #ifdef ENV_WORLDPOS
            
            varying vec3 vWorldPosition;
        
          #else
        
            varying vec3 vReflect;
            uniform float refractionRatio;
        
          #end
        
        #end
      #end;
    };

    // Now you can use the glslCode variable
    trace(glslCode); 
  }
}