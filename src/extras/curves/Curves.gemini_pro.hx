class Curves {
  static var ArcCurve:Dynamic;
  static var CatmullRomCurve3:Dynamic;
  static var CubicBezierCurve:Dynamic;
  static var CubicBezierCurve3:Dynamic;
  static var EllipseCurve:Dynamic;
  static var LineCurve:Dynamic;
  static var LineCurve3:Dynamic;
  static var QuadraticBezierCurve:Dynamic;
  static var QuadraticBezierCurve3:Dynamic;
  static var SplineCurve:Dynamic;
}

// Import the classes from the respective files
import ArcCurve from "./ArcCurve.hx";
import CatmullRomCurve3 from "./CatmullRomCurve3.hx";
import CubicBezierCurve from "./CubicBezierCurve.hx";
import CubicBezierCurve3 from "./CubicBezierCurve3.hx";
import EllipseCurve from "./EllipseCurve.hx";
import LineCurve from "./LineCurve.hx";
import LineCurve3 from "./LineCurve3.hx";
import QuadraticBezierCurve from "./QuadraticBezierCurve.hx";
import QuadraticBezierCurve3 from "./QuadraticBezierCurve3.hx";
import SplineCurve from "./SplineCurve.hx";

// Assign the classes to the respective properties
Curves.ArcCurve = ArcCurve;
Curves.CatmullRomCurve3 = CatmullRomCurve3;
Curves.CubicBezierCurve = CubicBezierCurve;
Curves.CubicBezierCurve3 = CubicBezierCurve3;
Curves.EllipseCurve = EllipseCurve;
Curves.LineCurve = LineCurve;
Curves.LineCurve3 = LineCurve3;
Curves.QuadraticBezierCurve = QuadraticBezierCurve;
Curves.QuadraticBezierCurve3 = QuadraticBezierCurve3;
Curves.SplineCurve = SplineCurve;

// Export the Curves class
export Curves;