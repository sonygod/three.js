class LightsFragmentBegin {
    var geometryPosition:Float = -vViewPosition;
    var geometryNormal:Float = normal;
    var geometryViewDir:Float = (isOrthographic) ? Float.ofArray([0, 0, 1]) : normalize(vViewPosition);
    var geometryClearcoatNormal:Float = Float.ofArray([0.0, 0.0, 0.0]);

    #if defined(USE_CLEARCOAT)
        geometryClearcoatNormal = clearcoatNormal;
    #end

    #if defined(USE_IRIDESCENCE)
        var dotNVi:Float = saturate(dot(normal, geometryViewDir));
        if (material.iridescenceThickness == 0.0)
            material.iridescence = 0.0;
        else
            material.iridescence = saturate(material.iridescence);

        if (material.iridescence > 0.0) {
            material.iridescenceFresnel = evalIridescence(1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor);
            material.iridescenceF0 = Schlick_to_F0(material.iridescenceFresnel, 1.0, dotNVi);
        }
    #end

    var directLight:IncidentLight = null;

    // The rest of the code is not directly translatable to Haxe due to the use of GLSL syntax and preprocessor directives.
    // You would need to manually convert the GLSL code to Haxe or use a library that supports GLSL syntax in Haxe.
}