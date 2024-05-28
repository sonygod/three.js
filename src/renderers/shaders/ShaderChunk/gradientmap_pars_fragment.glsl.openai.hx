@:glsl(
#ifdef USE_GRADIENTMAP
uniform sampler2D gradientMap;
#end
)

vec3 getGradientIrradiance(vec3 normal, vec3 lightDirection) {
    // dotNL will be from -1.0 to 1.0
    var dotNL = dot(normal, lightDirection);
    var coord = vec2(dotNL * 0.5 + 0.5, 0.0);

#ifdef USE_GRADIENTMAP
    return vec3(texture2D(gradientMap, coord).r);
#else
    var fw = fwidth(coord) * 0.5;
    return mix(vec3(0.7), vec3(1.0), smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x));
#end
}