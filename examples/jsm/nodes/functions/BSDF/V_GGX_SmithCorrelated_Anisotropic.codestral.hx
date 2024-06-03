import js.Browser.document;
import js.html.HtmlElement;
import js.html.InputElement;

class V_GGX_SmithCorrelated_Anisotropic {

    static public function calculate(alphaT: Float, alphaB: Float, dotTV: Float, dotBV: Float, dotTL: Float, dotBL: Float, dotNV: Float, dotNL: Float): Float {
        var gv: Float = dotNL * Math.sqrt(alphaT * dotTV * alphaT * dotTV + alphaB * dotBV * alphaB * dotBV + dotNV * dotNV);
        var gl: Float = dotNV * Math.sqrt(alphaT * dotTL * alphaT * dotTL + alphaB * dotBL * alphaB * dotBL + dotNL * dotNL);
        var v: Float = 0.5 / (gv + gl);

        return Math.min(Math.max(v, 0), 1);
    }
}