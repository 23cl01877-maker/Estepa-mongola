// ============================================================
//  Conector Tetradecaedro VERSIÓN 1 (octaedro truncado, modelo original)
//  - Conductos redondos horizontales a 120° para palillos de 3 mm
//    (dos palillos a 120° = vértice de un hexágono; con 3 conductos
//     también sirve para una malla de hexágonos / panal)
//  - Orificio vertical central pasante (arriba y abajo) para otra unión
//  La cara hexagonal queda hacia arriba/abajo (impresión 3D cómoda).
// ============================================================

// ---------- Parámetros ----------
d_palillo   = 3;      // diámetro del palillo (mm)
holgura     = 0.3;    // holgura para impresión 3D (mm)
escala      = 8;      // tamaño: arista del poliedro = escala * 1.414 mm
n_horiz     = 3;      // nº de conductos horizontales a 120° (3 = 0/120/240; 2 = solo un ángulo de 120°)
ang_inicio  = 90;     // ángulo del primer conducto (°)
prof_horiz  = 0;      // profundidad de cada conducto horizontal desde el centro (0 = pasante hasta la superficie)
prof_vert   = 0;      // profundidad del orificio vertical (0 = pasante arriba y abajo)
corte       = false;  // true = corta el modelo por la mitad para ver los conductos
ver_palillos= false;  // true = muestra palillos de ejemplo (solo vista previa)
$fn = 48;

d_hueco = d_palillo + holgura;
R_total = 4 * escala;   // longitud suficiente para atravesar el sólido

// ---------- Tetradecaedro ----------
// Vértices: todas las permutaciones de (0, ±1, ±2)
perms = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]];
puntos = [for (p = perms, sx = [-1,1], sy = [-1,1], sz = [-1,1])
            [p[0]*sx, p[1]*sy, p[2]*sz] * escala];

module tetradecaedro_base() {
    hull() for (p = puntos) translate(p) cube(0.001, center = true);
}

// Gira el sólido para que una cara hexagonal (eje 1,1,1) quede hacia arriba
module tetradecaedro() {
    rotate([0, -atan(sqrt(2)), 0])
        rotate([0, 0, -45])
            tetradecaedro_base();
}

// ---------- Conductos ----------
module conductos() {
    // Horizontales a 120°
    for (i = [0 : n_horiz - 1])
        rotate([0, 0, ang_inicio + i * 120])
            rotate([0, 90, 0])
                cylinder(d = d_hueco, h = prof_horiz > 0 ? prof_horiz : R_total);

    // Vertical central (arriba y abajo)
    if (prof_vert > 0) {
        cylinder(d = d_hueco, h = prof_vert);
        mirror([0,0,1]) cylinder(d = d_hueco, h = prof_vert);
    } else {
        cylinder(d = d_hueco, h = R_total, center = true);
    }
}

// ---------- Pieza final ----------
module conector() {
    difference() {
        tetradecaedro();
        conductos();
        if (corte) translate([-100, -200, -100]) cube([200, 200, 200]); // quita y<0
    }
}

conector();

if (ver_palillos) %union() {
    for (i = [0 : n_horiz - 1])
        rotate([0, 0, ang_inicio + i * 120])
            rotate([0, 90, 0])
                cylinder(d = d_palillo, h = 3 * escala);
    cylinder(d = d_palillo, h = 3 * escala, center = true);
}
