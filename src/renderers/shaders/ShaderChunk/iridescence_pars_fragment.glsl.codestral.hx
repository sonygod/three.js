// Define constants
static var USE_IRIDESCENCEMAP = true;
static var USE_IRIDESCENCE_THICKNESSMAP = true;

// Conditional compilation
if (USE_IRIDESCENCEMAP) {
    trace("uniform sampler2D iridescenceMap;");
}

if (USE_IRIDESCENCE_THICKNESSMAP) {
    trace("uniform sampler2D iridescenceThicknessMap;");
}