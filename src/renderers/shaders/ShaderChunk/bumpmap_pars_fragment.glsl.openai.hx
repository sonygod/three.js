package three.shaderlib;

// Bump mapping shader chunk

#if (js && (USE_BUMPMAP))

// Uniforms
uniform sampler2D bumpMap;
uniform float bumpScale;

// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)
function dHdxy_fwd() : Vec2 {
  var dSTdx = dFdx(vBumpMapUv);
  var dSTdy = dFdy(vBumpMapUv);

  var Hll = bumpScale * texture2D(bumpMap, vBumpMapUv).x;
  var dBx = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdx).x - Hll;
  var dBy = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdy).x - Hll;

  return new Vec2(dBx, dBy);
}

// Perturb normal for bump mapping
function perturbNormalArb(surf_pos : Vec3, surf_norm : Vec3, dHdxy : Vec2, faceDirection : Float) : Vec3 {
  // normalize is done to ensure that the bump map looks the same regardless of the texture's scale
  var vSigmaX = normalize(dFdx(surf_pos));
  var vSigmaY = normalize(dFdy(surf_pos));
  var vN = surf_norm; // normalized

  var R1 = cross(vSigmaY, vN);
  var R2 = cross(vN, vSigmaX);

  var fDet = dot(vSigmaX, R1) * faceDirection;

  var vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
  return normalize(abs(fDet) * surf_norm - vGrad);
}

#end