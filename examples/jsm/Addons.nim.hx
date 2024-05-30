// File path: three.hx/examples/jsm/Addons.hx

@:build(haxe.macro.Compiler.extern("./animation/AnimationClipCreator.js"))
extern class AnimationClipCreator {}

@:build(haxe.macro.Compiler.extern("./animation/CCDIKSolver.js"))
extern class CCDIKSolver {}

@:build(haxe.macro.Compiler.extern("./animation/MMDAnimationHelper.js"))
extern class MMDAnimationHelper {}

@:build(haxe.macro.Compiler.extern("./animation/MMDPhysics.js"))
extern class MMDPhysics {}

// ...

@:build(haxe.macro.Compiler.extern("./capabilities/WebGL.js"))
extern class WebGL {}

// ...

@:build(haxe.macro.Compiler.extern("./controls/ArcballControls.js"))
extern class ArcballControls {}

@:build(haxe.macro.Compiler.extern("./controls/DragControls.js"))
extern class DragControls {}

// ...

// Repeat the process for the remaining exports.