(* ::Package:: *)
(* 01_wormhole_backgrounds.wl -- EXAMPLE calculation (from arXiv:2605.16168; /init-project removes it).

   Wormholes from analytically extended BPS domain walls, examples 1, 2, 5 of sec. 2.2:
     1. Coulomb branch of N=4 SYM, SO(3)xSO(3)   (d = 4, one ghost)
     2. Coulomb branch of ABJM, SO(4)xSO(4)      (d = 3, one ghost)
     5. GPPZ                                       (d = 4, two ghosts)

   Assumptions: ghost scalars only (phi^a = i eta^a), metric dr^2 + e^{2A} eta_{mu nu} dx dx, mostly plus.
   Checks:
     - the closed-form flows solve the BPS equations, eq. (2.7);
     - they solve the full second-order equations, R_MN = 1/2 Ttilde_MN and the ghost scalar equations,
       with Ricci computed from the metric by packages/supergrav.wl (not the reduced equations of app. B);
     - asymptotics: two AdS boundaries of equal radius; throat is a minimum of the warp factor;
     - V(eta) from eq. (2.8) agrees with the expressions quoted in app. C.
   Outputs:
     results/analytic/warp_ex{1,2,5}[_r].json            e^{2A} in u = r/L (and in r), Minkowski boundaries
     results/analytic/{potential_ex1,potential_ex2}.json  V(eta)
     results/analytic/{delta_eta_ex*,idb_upper_d*}.json    imaginary distance vs bound, sec. 5
     results/01_wormhole_backgrounds.json                  slopes of I(width), eq. (4.21)
*)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Project.wl"}]];

ScriptBegin["Script01"];
$Assumptions = L > 0 && Element[{r, u, r0, r1, r2, a0}, Reals];

(* ---------- domain-wall geometry (packages/supergrav.wl) ---------- *)

(* dr^2 + e^{2 Aw(r)} eta_{mu nu} dx^mu dx^nu in d+1 dimensions, mostly plus *)
wallCoordinates[d_Integer] := Join[{r, t}, Table[Symbol["x" <> ToString[i]], {i, d - 1}]];
wallMetric[d_Integer] := DiagonalMatrix[Join[{1}, E^(2 Aw[r]) Join[{-1}, ConstantArray[1, d - 1]]]];
(* load once here, so that RicciTensor, scalarLaplacian below resolve to Supergravity` *)
LoadGeometry[wallCoordinates[4], wallMetric[4]];

(* ---------- generic checker for ghost-only domain walls ---------- *)

ghostPotential[W_, etas_, d_] := -1/2 Total[D[W, #]^2 & /@ etas] - d/(4 (d - 1)) W^2;

(* Second-order equations for a generic domain wall with ghosts e[i][r] and warp exponent Aw[r],
   with Ricci computed from the metric. BPS flows must solve them identically once A', eta', A'',
   eta'' are eliminated with the BPS equations: what remains is a function of the scalars only. *)
bpsSolvesEOM[label_, d_, W_, etas_] := Module[
	{x = wallCoordinates[d], g = wallMetric[d], n = Length[etas], ef, toFields, rhsA, rhsE, rule1, rule2,
   V, ricci, tTilde, residuals},
	ef = Table[Unique["e"], {n}];
	toFields = Thread[etas -> Through[ef[r]]];
	rhsA = -W/(2 (d - 1)) /. toFields;
	rhsE = -(D[W, #] & /@ etas) /. toFields;
	rule1 = Join[{Aw'[r] -> rhsA}, Thread[Through[(Derivative[1] /@ ef)[r]] -> rhsE]];
	rule2 = Join[{Aw''[r] -> (D[rhsA, r] /. rule1)},
		Thread[Through[(Derivative[2] /@ ef)[r]] -> (D[rhsE, r] /. rule1)]];
	LoadGeometry[x, g];
	V = ghostPotential[W, etas, d];
	ricci = RicciTensor;
	tTilde = -Sum[Outer[Times, #, #] &[D[f[r], #] & /@ x], {f, ef}] + 2/(d - 1) g (V /. toFields);
	residuals = Join[Flatten[ricci - 1/2 tTilde],
		MapThread[scalarLaplacian[#2[r]] + (D[V, #1] /. toFields) &, {etas, ef}]];
	residuals = residuals /. rule2 /. rule1 /. Thread[Through[ef[r]] -> etas];
	AssertZero[label <> ": BPS flows solve Einstein + ghost scalar equations", residuals]
];

(* the closed-form profiles solve the BPS equations, eq. (2.7) *)
checkProfiles[label_, d_, W_, etas_, etaSol_, warp2_] := Module[{sol = Thread[etas -> etaSol]},
	AssertZero[label <> ": BPS eta", D[etaSol, r] + (D[W, #] & /@ etas /. sol)];
	AssertZero[label <> ": BPS A", D[Log[warp2]/2, r] + (W /. sol)/(2 (d - 1))]
];

checkWormhole[label_, d_, W_, etas_, etaSol_, warp2_] := (
	bpsSolvesEOM[label, d, W, etas]; checkProfiles[label, d, W, etas, etaSol, warp2]);

(* Asymptotic coefficients: Limit on arctan profiles takes ~10 s each, so evaluate deep in the
   asymptotic region instead (corrections ~ e^{-200} at |r| = 100 L, far below the 10^-25 tolerance). *)
atMinusInfinity[expr_] := expr /. r -> -100 L;
atPlusInfinity[expr_] := expr /. r -> 100 L;
(* endpoint values of the arctan profiles, exactly *)
endpoints[expr_] := {expr /. ArcTan[_] -> 0, expr /. ArcTan[_] -> Pi/2};

(* ---------- example 1: N=4 Coulomb branch, d = 4 ---------- *)

W1 = 6/L Cos[eta/Sqrt[3]];
eta1Sol = 2 Sqrt[3] ArcTan[E^(2 (r - r0)/L)];
warp1 = E^(2 a0)/Sin[eta1Sol/Sqrt[3]];
checkWormhole["ex1", 4, W1, {eta}, {eta1Sol}, warp1];
AssertZero["ex1: V vs app. C", ghostPotential[W1, {eta}, 4] + 3 (3 + Cos[2 eta/Sqrt[3]])/L^2];
AssertNumericZero["ex1: AdS at r -> -oo",
	atMinusInfinity[warp1 E^(2 (r - r0)/L)] - E^(2 a0)/2];
AssertNumericZero["ex1: AdS at r -> +oo",
	atPlusInfinity[warp1 E^(-2 (r - r0)/L)] - E^(2 a0)/2];

(* ---------- example 2: ABJM Coulomb branch, d = 3 ---------- *)

W2 = 4/L Cos[eta/2];
eta2Sol = 4 ArcTan[E^((r - r0)/L)];
warp2 = E^(2 a0)/Sin[eta2Sol/2]^2;
checkWormhole["ex2", 3, W2, {eta}, {eta2Sol}, warp2];
AssertZero["ex2: V vs app. C", ghostPotential[W2, {eta}, 3] + 2 (2 + Cos[eta])/L^2];
AssertNumericZero["ex2: AdS at r -> -oo",
	atMinusInfinity[warp2 E^(2 (r - r0)/L)] - E^(2 a0)/4];
AssertNumericZero["ex2: AdS at r -> +oo",
	atPlusInfinity[warp2 E^(-2 (r - r0)/L)] - E^(2 a0)/4];

(* ---------- example 5: GPPZ, d = 4, two ghosts ---------- *)

W5 = 3/L (Cos[eta1/Sqrt[3]] + Cos[eta2]);
eta5Sol = {2 Sqrt[3] ArcTan[E^((r - r1)/L)], 2 ArcTan[E^(3 (r - r2)/L)]};
warp5 = E^(2 a0) Cosh[(r - r1)/L] Cosh[3 (r - r2)/L]^(1/3);
checkWormhole["ex5", 4, W5, {eta1, eta2}, eta5Sol, warp5];
AssertNumericZero["ex5: AdS at r -> -oo",
	atMinusInfinity[warp5 E^((2 r - r1 - r2)/L)] - E^(2 a0)/2^(4/3)];
AssertNumericZero["ex5: AdS at r -> +oo",
	atPlusInfinity[warp5 E^(-(2 r - r1 - r2)/L)] - E^(2 a0)/2^(4/3)];

(* ---------- Minkowski boundaries (sec. 4.2): symmetric wormholes, unit boundary metric ---------- *)

warpMink = <|
	"ex1" -> {4, warp1 /. {r0 -> 0, a0 -> Log[2]/2}, 2 Cosh[2 u]},
	"ex2" -> {3, warp2 /. {r0 -> 0, a0 -> Log[4]/2}, 4 Cosh[u]^2},
	"ex5" -> {4, warp5 /. {r1 -> 0, r2 -> 0, a0 -> Log[2^(4/3)]/2}, 2^(4/3) Cosh[u] Cosh[3 u]^(1/3)}|>;

slopes = KeyValueMap[Function[{ex, data}, Module[{d, w, paper, A, A0},
		{d, w, paper} = data;
		w = w /. r -> L u;
		AssertZero[ex <> ": Minkowski warp factor vs sec. 4.2", w - paper];
		AssertNumericZero[ex <> ": unit boundary metric", (paper E^(-2 u) /. u -> 100) - 1];
		A = Log[paper]/2;
		AssertZero[ex <> ": throat at u = 0", D[A, u] /. u -> 0];
		If[!TrueQ[(D[A, {u, 2}] /. u -> 0) > 0], CheckFailed[ex <> ": throat is not a minimum"]];
		ExportAnalytic["warp_" <> ex, paper];               (* in u = r/L, for Python *)
		ExportAnalytic["warp_" <> ex <> "_r", paper /. u -> r/L];  (* in r, for the paper *)
		(* large-width mutual information slope, eq. (4.21): I/(C V) ~ m Delta l / L, m = e^{(d-1)A(0)}/2 *)
		ex -> FullSimplify[E^((d - 1) A /. u -> 0)/2]]], warpMink];

(* ---------- imaginary distance travelled by the scalars vs the bound of sec. 5 ---------- *)

deltaEta = <|
	"ex1" -> Subtract @@ Reverse[endpoints[eta1Sol]],
	"ex2" -> Subtract @@ Reverse[endpoints[eta2Sol]],
	"ex5" -> Norm[Subtract @@ Reverse[endpoints[eta5Sol]]]|>;
(* the exact endpoints agree with the profiles deep in each asymptotic region *)
AssertNumericZero["eta endpoints",
	Flatten[{atMinusInfinity[#] - endpoints[#][[1]], atPlusInfinity[#] - endpoints[#][[2]]} & /@
		{eta1Sol, eta2Sol, eta5Sol}]];
idbUpper[d_] := Pi Sqrt[2 d/(d - 1)];
Scan[If[!TrueQ[deltaEta[#[[1]]] > idbUpper[#[[2]]]], CheckFailed[#[[1]] <> ": Delta eta below IDB"]] &,
	{{"ex1", 4}, {"ex2", 3}, {"ex5", 4}}];

ExportAnalytic["potential_ex1", -3 (3 + Cos[2 eta/Sqrt[3]])/L^2];
ExportAnalytic["potential_ex2", -2 (2 + Cos[eta])/L^2];
KeyValueMap[ExportAnalytic["delta_eta_" <> #1, FullSimplify[#2]] &, deltaEta];
ExportAnalytic["idb_upper_d4", idbUpper[4]];
ExportAnalytic["idb_upper_d3", idbUpper[3]];

ExportValues["01_wormhole_backgrounds", <|
	"MISlopeAnalyticExOne" -> <|"value" -> slopes[[1]][[2]], "digits" -> 6|>,
	"MISlopeAnalyticExTwo" -> <|"value" -> slopes[[2]][[2]], "digits" -> 6|>,
	"MISlopeAnalyticExFive" -> <|"value" -> slopes[[3]][[2]], "digits" -> 6|>
|>];

Print["01_wormhole_backgrounds: OK  slopes = ", slopes, "  Delta eta = ", deltaEta];
ScriptEnd[];
