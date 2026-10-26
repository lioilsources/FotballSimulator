import 'dart:math' as math;

/// Minimální neměnný 3D vektor (náhrada Godot Vector3). Vlastní typ místo
/// vector_math: immutable, `const` konstruktor a nulové závislosti.
class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);
  static const up = Vec3(0, 1, 0);
  static const down = Vec3(0, -1, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator -() => Vec3(-x, -y, -z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  Vec3 operator /(double s) => Vec3(x / s, y / s, z / s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get lengthSquared => x * x + y * y + z * z;
  double get length => math.sqrt(lengthSquared);

  Vec3 normalized() {
    final l = length;
    return l == 0 ? zero : this / l;
  }

  Vec3 withY(double ny) => Vec3(x, ny, z);

  Vec3 lerp(Vec3 o, double t) => this + (o - this) * t;

  @override
  bool operator ==(Object other) =>
      other is Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() =>
      '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

/// 2D vektor pro contact offset (náhrada Godot Vector2).
class Vec2 {
  final double x, y;
  const Vec2(this.x, this.y);

  static const zero = Vec2(0, 0);

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  Vec2 limitLength(double max) {
    final l = length;
    return l > max && l > 0 ? Vec2(x / l * max, y / l * max) : this;
  }
}

/// Rotační matice 3×3 (sloupce = tělesové osy míče ve světě) — jen pro
/// vizuální rotaci míče a zrcadlení na overlay.
class Basis {
  Vec3 x, y, z;
  Basis() : x = const Vec3(1, 0, 0), y = const Vec3(0, 1, 0), z = const Vec3(0, 0, 1);

  /// Ekvivalent Godot `Node3D.rotate(axis, angle)`: globální rotace zleva.
  void rotate(Vec3 axis, double angle) {
    x = _rodrigues(x, axis, angle);
    y = _rodrigues(y, axis, angle);
    z = _rodrigues(z, axis, angle);
    // přeortonormalizovat, ať se chyba nezačne kumulovat
    x = x.normalized();
    z = x.cross(y).normalized();
    y = z.cross(x);
  }

  void reset() {
    x = const Vec3(1, 0, 0);
    y = const Vec3(0, 1, 0);
    z = const Vec3(0, 0, 1);
  }

  static Vec3 _rodrigues(Vec3 v, Vec3 k, double a) {
    final c = math.cos(a), s = math.sin(a);
    return v * c + k.cross(v) * s + k * (k.dot(v) * (1 - c));
  }
}
