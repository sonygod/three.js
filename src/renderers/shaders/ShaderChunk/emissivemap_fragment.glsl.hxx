@:js("export default /* glsl */`\n#ifdef USE_EMISSIVEMAP\n\n\tvec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );\n\n\ttotalEmissiveRadiance *= emissiveColor.rgb;\n\n#endif\n`;")
class EmissiveMapFragment {
}