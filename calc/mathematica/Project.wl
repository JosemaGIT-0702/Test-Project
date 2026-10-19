(* ::Package:: *)
(* Project.wl -- pipeline infrastructure shared by every Mathematica script in this project.

   Load it at the top of each script with
       Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Project.wl"}]];
       ScriptBegin["ScriptNN"];   ... calculation ...   ScriptEnd[];
   ScriptBegin gives the script a private, freshly wiped context, so it behaves identically in
   wolframscript (make calc) and in the persistent, context-isolated kernel of the Wolfram
   MCP server (no clashes between symbols of different scripts or sessions, no leaked state).

   Physics lives in packages, not here: calc/mathematica/packages/*.wl are the same packages the
   exploratory notebooks use (see packages/README.md). Load them with LoadPackage, or, for the
   metric-dependent supergrav.wl, with LoadGeometry[coords, metric].

   Conventions (keep in sync with notes/conventions.md):
     - mostly-plus signature (-,+,...,+)
     - Riemann tensor R^a_{bcd} = d_c Gamma^a_{db} - d_d Gamma^a_{cb} + Gamma^a_{ce} Gamma^e_{db} - Gamma^a_{de} Gamma^e_{cb},
       Ricci R_{bd} = R^a_{bad}, so AdS has R < 0. supergrav.wl agrees for RicciTensor, RicciScalar,
       Einstein; its Riemann[[m, n, b, a]] = R^a_{b n m}
     - action (1/(16 Pi G)) Int sqrt(-g) [R - 1/2 (dphi)^2 - V],  2 kappa^2 = 16 Pi G
*)

BeginPackage["Project`"];

$ProjectRoot::usage = "$ProjectRoot is the absolute path of the repository root.";

ScriptBegin::usage = "ScriptBegin[\"ScriptNN\"] starts a pipeline script: wipes and enters the private context \
ScriptNN`, drops stale Global`/Sessions` contexts from $ContextPath and resets $Assumptions. \
Pair with ScriptEnd[] at the end of the script.";
ScriptEnd::usage = "ScriptEnd[] leaves the script context and restores $Context, $ContextPath and $Assumptions. \
Called automatically by CheckFailed, and safe to call twice.";

LoadPackage::usage = "LoadPackage[\"name\"] loads calc/mathematica/packages/name.wl (call it at top level, \
before the definitions that use the package's symbols).";
LoadGeometry::usage = "LoadGeometry[coords, metric] (re)loads packages/supergrav.wl for this metric: afterwards \
Christoffel, Riemann, RicciTensor, RicciScalar, Einstein, covariant, scalarLaplacian, raise, lower, ... (context \
Supergravity`) refer to it. coords must be plain symbols. Call it once at top level before defining functions that \
use these symbols (they are resolved when a definition is read), then again whenever the metric changes.";

ExportValues::usage = "ExportValues[name, <|key -> value, ...|>] writes results/<name>.json. \
Each key becomes the LaTeX macro \\val<Key> via `make values`. \
A value may be a number or <|\"value\" -> x, \"digits\" -> n (or \"decimals\" -> n), \"unit\" -> \"GeV\"|>.";
ExportAnalytic::usage = "ExportAnalytic[name, expr] writes results/analytic/<name>.json \
(InputForm + TeXForm) and paper/generated/eq_<name>.tex for \\input in the paper.";
ImportAnalytic::usage = "ImportAnalytic[name] reads back an expression saved with ExportAnalytic.";
AssertZero::usage = "AssertZero[label, expr] checks expr == 0 (or a list of zeros): Simplify for at most 10 s, \
then 40-digit evaluation at random points; calls CheckFailed if it is not zero.";
AssertNumericZero::usage = "AssertNumericZero[label, expr] checks expr == 0 only numerically (40 digits, random \
rational points for all free symbols); use it for asymptotic checks and when Simplify is hopeless.";
CheckFailed::usage = "CheckFailed[msg] prints the failure and stops: Exit[1] under wolframscript, Abort[] in an \
interactive/MCP kernel (so the kernel survives).";

Begin["`Private`"];

$ProjectRoot = FileNameDrop[
	If[StringQ[$InputFileName] && $InputFileName =!= "", $InputFileName,
     FileNameJoin[{Directory[], "calc", "mathematica", "Project.wl"}]], -3];

(* ---------- packages ---------- *)

packageFile[name_String] := FileNameJoin[{$ProjectRoot, "calc", "mathematica", "packages", name <> ".wl"}];

LoadPackage[name_String] := If[FileExistsQ[packageFile[name]], Get[packageFile[name]],
	CheckFailed["LoadPackage: no package " <> packageFile[name]]];

(* supergrav.wl reads Global`coord and Global`metric when it is loaded: the one place where Global` is
   used, so that scripts can keep their own private context. *)
LoadGeometry[coords_List, metric_] := (
	If[!AllTrue[coords, MatchQ[#, _Symbol] &],
		CheckFailed["LoadGeometry: coordinates must be plain symbols, got " <> ToString[coords, InputForm]]];
	If[!(SymmetricMatrixQ[metric] && Dimensions[metric] === {Length[coords], Length[coords]}),
		CheckFailed["LoadGeometry: metric is not a symmetric " <> ToString[Length[coords]] <> "x" <>
			ToString[Length[coords]] <> " matrix"]];
	Quiet[Unprotect["Supergravity`*"]];          (* reload: usage messages of protected symbols *)
	ClearAll["Supergravity`Private`metricsign"];  (* cached sign of det g, would survive a reload *)
	Block[{Global`coord = coords, Global`metric = metric}, Get[packageFile["supergrav"]]];
	coords);

(* ---------- checks ---------- *)

numericallyZero[flat_List] := Module[{vars, pts, vals},
	vars = Select[Union[Cases[flat, _Symbol, {-1}]], !NumericQ[#] &];
	(* random rationals in (0.11, 1.89) that avoid "special" values such as 1 or 1/2 *)
	pts = Table[Thread[vars -> (RandomInteger[{1100, 18900}, Length[vars]] + 3/7)/10000], {12}];
	(* asymptotic checks deep in AdS regions need ~100 extra digits to resolve e^{-200} terms *)
	vals = Block[{$MaxExtraPrecision = 500},
		Quiet[Max[Abs[N[flat /. #, 40]]] & /@ pts, {N::meprec, Power::infy, Infinity::indet}]];
	vals = Select[vals, NumericQ[#] && # < Infinity &];   (* skip points on singularities *)
	Length[vals] >= 6 && Max[vals] < 10^-25];

AssertZero[label_String, expr_] := Module[{flat = Flatten[{expr}], s},
	(* 1. symbolic, but never let Simplify run away *)
	s = TimeConstrained[Simplify[flat], 10, $Failed];
	If[s =!= $Failed && AllTrue[s, # === 0 &], Return[True]];
	(* 2. inconclusive: 40-digit evaluation at random rational points (positive, O(1)) *)
	If[numericallyZero[flat], Return[True]];
	CheckFailed[label <> "  residual: " <> ToString[Short[If[s === $Failed, flat, s], 3], InputForm]]
];

AssertNumericZero[label_String, expr_] :=
	If[numericallyZero[Flatten[{expr}]], True,
		CheckFailed[label <> "  residual: " <> ToString[Short[expr, 3], InputForm]]];

CheckFailed[msg_String] := (Print["CHECK FAILED: ", msg]; ScriptEnd[];
	If[Length[$ScriptCommandLine] > 0, Exit[1], Abort[]]);

(* ---------- script isolation ---------- *)

$scriptSaved = None;

ScriptBegin[id_String] := Module[{ctx = id <> "`"},
	ScriptEnd[];                                  (* recover from an earlier aborted run *)
	$scriptSaved = <|"Script" -> ctx, "ContextPath" -> $ContextPath, "Assumptions" -> $Assumptions|>;
	Quiet[Unprotect[Evaluate[ctx <> "*"]]; Remove[Evaluate[ctx <> "*"]], {Remove::rmnsm, Unprotect::ssym}];
	$ContextPath = Select[$ContextPath, !StringStartsQ[#, "Global`" | "Sessions`"] &];
	$Assumptions = True;
	Begin[ctx];
	ctx];

ScriptEnd[] := If[AssociationQ[$scriptSaved], Module[{s = $scriptSaved},
	$scriptSaved = None;
	If[$Context === s["Script"], End[]];          (* pops the Begin of ScriptBegin *)
	$ContextPath = s["ContextPath"]; $Assumptions = s["Assumptions"];
	Null]];

(* ---------- export ---------- *)

ensureDir[d_] := If[!DirectoryQ[d], CreateDirectory[d, CreateIntermediateDirectories -> True]];

normalise[v_?NumericQ] := <|"value" -> N[v]|>;
normalise[a_Association] := MapAt[N, a, "value"];

ExportValues[name_String, vals_Association] := Module[{dir, file},
	dir = FileNameJoin[{$ProjectRoot, "results"}]; ensureDir[dir];
	file = FileNameJoin[{dir, name <> ".json"}];
	Export[file, normalise /@ vals, "RawJSON"];
	file
];

ExportAnalytic[name_String, expr_] := Module[{dir, gen, file},
	dir = FileNameJoin[{$ProjectRoot, "results", "analytic"}]; ensureDir[dir];
	gen = FileNameJoin[{$ProjectRoot, "paper", "generated"}]; ensureDir[gen];
	file = FileNameJoin[{dir, name <> ".json"}];
	Export[file, <|
		"name" -> name,
		"mathematica" -> ToString[expr, InputForm],
		"tex" -> ToString[TeXForm[expr]],
		"generated" -> DateString["ISODateTime"]|>, "RawJSON"];
	Export[FileNameJoin[{gen, "eq_" <> name <> ".tex"}],
		"% generated by calc/mathematica -- do not edit\n" <> ToString[TeXForm[expr]] <> "\n", "Text"];
	file
];

ImportAnalytic[name_String] := ToExpression[
	Import[FileNameJoin[{$ProjectRoot, "results", "analytic", name <> ".json"}], "RawJSON"]["mathematica"]];

End[];
EndPackage[];
