(* ::Package:: *)
(* 02_ghost_fluctuations.wl -- EXAMPLE calculation (from arXiv:2605.16168; /init-project removes it).

   Gauge-invariant ghost fluctuation Z_eta on the example-1 wormhole (d = 4), app. B-C.
   Starting from the general equation (B.33)-(B.35) with H_S = 0,
       Z'' + d A' Z' + (e^{-2A} M^2 + Q_ZZ) Z = 0 ,
   derive the form used for the spectral method of app. C:
       r = L log((1+v)/(1-v)),  z(v) = v^2 (1+v)^2 psi(v),  v = (s-1)/2,
       (1-s^2) psi'' + [A0 + A1 M^2] psi' + [B0 + B1 M^2] psi = 0 ,   M^2 in units of 1/L^2.
   Checks (each against the paper):
     - the r-form of app. C (needs the background EOMs);
     - eq. (C.6) for z(v);
     - the coefficients A0, A1 = 0, B0, B1 of eq. (C.10)-(C.12).
   Outputs: results/analytic/zeta_ex1_{A0,B0,B1}.json   (consumed by 03_ghost_spectrum.py)
*)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Project.wl"}]];

ScriptBegin["Script02"];
$Assumptions = L > 0 && c > 0 && -1 < v < 1 && -1 < s < 1;

d = 4;
W = 6/L Cos[eta/Sqrt[3]];
V[e_] := Evaluate[-1/2 D[W, eta]^2 - d/(4 (d - 1)) W^2 /. eta -> e];

(* symmetric example-1 background, boundary metric c eta_{mu nu}/2 *)
eta0 = 2 Sqrt[3] ArcTan[E^(2 r/L)];
a = c/Sin[eta0/Sqrt[3]];              (* a = e^{2A} *)
A = Log[a]/2;

(* ---------- general invariant equation, eqs. (B.33)-(B.35) ---------- *)
dA = D[A, r]; ddA = D[A, {r, 2}]; de = D[eta0, r]; dde = D[eta0, {r, 2}];
QZH = E^(-2 A)/(d - 1) (de ddA - dA dde)/dA^2;
QZZ = V''[eta0] - 1/(d - 1) de/dA V'[eta0] - de E^(2 A) QZH;
p1 = d dA;                            (* coefficient of Z' *)
p0 = E^(-2 A) M2 + QZZ;               (* coefficient of Z, M2 = -k^2 *)

(* ---------- check 1: r-form of app. C ---------- *)
da = D[a, r];
p0paper = M2/a - 4 a de V'[eta0]/(3 da) - 2 a^2 de^4/(9 da^2) + V''[eta0] - 4/3 de^2;
AssertZero["Z eq: Z' coefficient vs app. C", p1 - 2 da/a];
AssertZero["Z eq: Z coefficient vs app. C", p0 - p0paper];

(* ---------- change to the compact coordinate v ---------- *)
rv = L Log[(1 + v)/(1 - v)];
vr = 1/D[rv, v];                      (* dv/dr as a function of v *)
vrr = D[vr, v] vr;                    (* d^2v/dr^2 *)
toV[expr_] := Simplify[expr /. r -> rv];
q1 = Simplify[(vrr + toV[p1] vr)/vr^2];      (* z'' + q1 z' + q0 z = 0 *)
q0 = Simplify[toV[p0]/vr^2];

(* ---------- check 2: eq. (C.6); M^2 there is in units of 1/L^2 and fixes c ---------- *)
q1paper = 2 v (v^4 - 10 v^2 - 15)/(v^6 + 5 v^4 - 5 v^2 - 1);
q0paper[m2_] := 2 (m2/(1 + 6 v^2 + v^4) - (v^8 - 12 v^6 - 10 v^4 - 12 v^2 + 1)/(v^2 (v^4 - 1)^2));
AssertZero["z eq: z' coefficient vs (C.6)", q1 - q1paper];
cSol = Solve[D[(q0 /. M2 -> m2/L^2) - q0paper[m2], m2] == 0 /. v -> 1/2, c];
If[Length[cSol] =!= 1, CheckFailed["normalisation of the boundary metric: " <> ToString[cSol]]];
AssertZero["boundary metric normalisation e^{2 a0} = 2 (sec. 4.2)", (c /. First[cSol]) - 2];
AssertZero["z eq: z coefficient vs (C.6)", (q0 /. {c -> 2, M2 -> m2/L^2}) - q0paper[m2]];

(* ---------- psi and the Chebyshev variable s ---------- *)
zOfPsi = v^2 (1 + v)^2 psi[v];
eqV = Simplify[(D[zOfPsi, {v, 2}] + q1paper D[zOfPsi, v] + q0paper[m2] zOfPsi)/(v^2 (1 + v)^2)];
eqS = eqV /. {psi[v] -> P0, psi'[v] -> 2 P1, psi''[v] -> 4 P2} /. v -> (s - 1)/2;
(* the equation is linear in P0, P1, P2 and in m2: extract coefficients with D, which is robust
   (Coefficient silently returns 0 on unexpanded rational functions) *)
norm = Simplify[D[eqS, P2]/(1 - s^2)];
coef[p_] := Simplify[D[eqS, p]/norm];
A0 = Simplify[coef[P1] /. m2 -> 0];
A1 = Simplify[D[coef[P1], m2]];
B0 = Simplify[coef[P0] /. m2 -> 0];
B1 = Simplify[D[coef[P0], m2]];
AssertZero["psi eq: coefficient of psi''", coef[P2] - (1 - s^2)];
AssertZero["psi eq: linear in psi", D[eqS, P0, P0]];

(* ---------- check 3: eqs. (C.10)-(C.12) ---------- *)
den = (s - 2) s ((s - 2) s + 26) + 41;
A0paper = 32 (3 (s - 1) s^2 + s + 7)/den - 10 s + 24/(s - 3) - 2;
B0paper = -64 (s - 3)/((s - 2) s + 5)^2 - 32/((s - 2) s + 5) - 32 (s ((s - 15) s + 39) - 41)/den +
	28/(s - 3) - 32/(s - 3)^2 - 18;
B1paper = 8 (1 - s^2)/den;
AssertZero["A0 vs (C.10)", A0 - A0paper];
AssertZero["A1 = 0", A1];
AssertZero["B0 vs (C.11)", B0 - B0paper];
AssertZero["B1 vs (C.12)", B1 - B1paper];

ExportAnalytic["zeta_ex1_A0", Together[A0]];
ExportAnalytic["zeta_ex1_B0", Together[B0]];
ExportAnalytic["zeta_ex1_B1", Together[B1]];

Print["02_ghost_fluctuations: OK"];
ScriptEnd[];
