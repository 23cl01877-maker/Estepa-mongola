// ============================================================
//  Conector Tetradecaedro VERSIÓN 2 - PARA IMPRESIÓN 3D (FDM)
//  - Cara hexagonal apoyada en la cama: base plana, sin soportes
//  - Conductos horizontales en forma de GOTA (punta hacia arriba)
//    para que se impriman sin soportes (voladizo máx. 45°)
//  - Orificio vertical redondo pasante (arriba y abajo)
//  - Chaflán de entrada en cada orificio para insertar el palillo
//  Imprimir tal cual, sin soportes. Capa sugerida: 0.16-0.2 mm.
// ============================================================

// ---------- Parámetros ----------
d_palillo   = 3;      // diámetro del palillo (mm)
holgura     = 0.30;   // holgura radial total; prueba 0.2-0.4 según tu impresora
escala      = 3.6;    // tamaño: arista = escala * 1.414 mm (3.6 -> arista 5.1 mm, alto 12.5 mm, mitad de volumen)
n_horiz     = 3;      // conductos horizontales a 120° (3 = 0/120/240)
ang_inicio  = 0;      // 0 = los conductos salen por el centro de una cara hexagonal (tubo cerrado y limpio)
chaflan     = 0.6;    // chaflán de entrada (mm), 0 = sin chaflán
corte       = false;  // true = corte por la mitad para inspeccionar
$fn = 48;

d_hueco = d_palillo + holgura;
r_hueco = d_hueco / 2;
holgura_vert = 0.15;   // holgura EXTRA solo del orificio vertical (los huecos verticales salen más justos al imprimir)
r_vert  = (d_hueco + holgura_vert) / 2;
R_total = 3 * escala;
R_cara  = sqrt(3) * escala;       // distancia centro -> cara hexagonal
R_salida = sqrt(6) * 0.75 * escala; // distancia centro -> salida horizontal (cara)

// ---------- Tetradecaedro ----------
perms = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]];
puntos = [for (p = perms, sx = [-1,1], sy = [-1,1], sz = [-1,1])
            [p[0]*sx, p[1]*sy, p[2]*sz] * escala];

module tetradecaedro() {
    rotate([0, -atan(sqrt(2)), 0])
        rotate([0, 0, -45])
            hull() for (p = puntos) translate(p) cube(0.001, center = true);
}

// ---------- Conductos ----------
// Conducto horizontal en gota (eje +X, punta hacia +Z)
module hueco_gota(L) {
    hull() {
        rotate([0, 90, 0]) cylinder(r = r_hueco, h = L);
        translate([0, -0.005, r_hueco * sqrt(2)]) cube([L, 0.01, 0.01]);
    }
}

module chaflan_cono(R) {   // cono de entrada en la superficie, eje +X
    if (chaflan > 0)
        translate([R - chaflan, 0, 0]) rotate([0, 90, 0])
            cylinder(r1 = r_hueco, r2 = r_hueco + chaflan + 0.5, h = chaflan + 0.5);
}

// ---------- Conductos desde el centro a cada cara CUADRADA ----------
ductos_cuadrados = true;   // true = un conducto por cada cuadrado (6 en total)
R_cuadrado = 2 * escala;   // distancia centro -> cara cuadrada

function _cross(a, b) = [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]];
function _dot(a, b) = a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
function _norm(a) = a / norm(a);
// misma rotación que usa tetradecaedro(): Ry(-atan(sqrt2)) * Rz(-45)
_ty = -atan(sqrt(2));
_Rz = [[cos(-45), -sin(-45), 0], [sin(-45), cos(-45), 0], [0, 0, 1]];
_Ry = [[cos(_ty), 0, sin(_ty)], [0, 1, 0], [-sin(_ty), 0, cos(_ty)]];
function _rot(v) = _Ry * (_Rz * v);

// Conducto en gota alineado con el eje 'a' (punta hacia "arriba" perpendicular al eje)
module conducto_eje(a, L) {
    t = _norm([0,0,1] - _dot([0,0,1], a) * a);
    y = _cross(t, a);
    multmatrix([[a[0], y[0], t[0], 0],
                [a[1], y[1], t[1], 0],
                [a[2], y[2], t[2], 0],
                [0, 0, 0, 1]]) {
        hueco_gota(L);
        if (chaflan > 0)
            translate([R_cuadrado - chaflan, 0, 0]) rotate([0, 90, 0])
                cylinder(r1 = r_hueco, r2 = r_hueco + chaflan + 0.5, h = chaflan + 0.5);
    }
}

module conductos() {
    // Horizontales a 120°
    for (i = [0 : n_horiz - 1])
        rotate([0, 0, ang_inicio + i * 120]) {
            hueco_gota(R_total);
            chaflan_cono(R_salida);
        }
    // Un conducto desde el centro hacia cada cara cuadrada
    if (ductos_cuadrados)
        for (e = [[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]])
            conducto_eje(_rot(e), R_cuadrado + chaflan + 1);
    // Vertical pasante (arriba y abajo)
    cylinder(r = r_vert, h = R_total, center = true);
    for (s = [0, 1]) mirror([0, 0, s])
        translate([0, 0, R_cara - chaflan])
            if (chaflan > 0)
                cylinder(r1 = r_vert, r2 = r_vert + chaflan + 0.5, h = chaflan + 0.5);
}

// ---------- Pieza final ----------
// Se baja para que la cara hexagonal inferior quede en z = 0 (cama de impresión)
translate([0, 0, R_cara])
difference() {
    union() { tetradecaedro(); }
    conductos();
    if (corte) translate([-100, -200, -100]) cube([200, 200, 200]);
}
