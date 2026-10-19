(* ::Package:: *)

BeginPackage["Supergravity`"];


(* 
	Before loading this package, you must define the following quantities:
		- coord: A list of the coordinates in use.
		- metric: The metric in the form a matrix
	I would also be desirable to define the ranges of the coordinates to ease Mathematica calculations.
	
	Example of preload:
		coord = {r, theta, phi};
		$Assumptions = And[r>0, theta>0, theta<Pi, Element[phi,Reals]];
		metric = DiagonalMatrix[{1, r^2, r^2 * Sin[theta]^2}];
*)


(* Definitions *)

dimen::usage					=	"dimen is the dimensionality of the space (number of coordinates)"
inverse::usage					=	"Inverse metric"
coordQ::usage					=	"coordQ[expr] returns True if expr is a coordinate or a list of coordinates, False otherwise."
FullTensorQ::usage				=	"FullTensorQ[expr] returns True if expr is a full array with dimensionality at all levels equal to the number of coordinates, and False otherwise."
scalarQ::usage					=	"scalarQ[expr] returns False if expr is or contains a list, a SparseArray object, or a \[DoubleStruckD] object, and returns True otherwise."
rank::usage						=	"For a tensor, rank[expr] returns its rank (number of indices)"
transpose::usage				=	"transpose[tensor, {index1,index2,...}] puts index1 of tensor into first position, index2 into second position, etc.; unlisted indices are left in their current order following the listed ones."
swapIndices::usage				=	"swapIndices[tensor, {index1,index2}] performs a transpose that swaps index1 and index2, leaving all other indices unaffected."
tr::usage						=	"tr[tensor, {index1,index2}, {index3,index4}, . . . (optional)]: trace over index1 and index2, over index3 and index4, etc. (without using the metric, so one index should be up and the other down). If no index pair is given, it returns the trace over the first two indices."
outer::usage					=	"outer[tensor1, tensor2, ...] or tensor1 ** tensor2 ** ...  gives the outer product of an arbitrary number of tensors."
NonCommutativeMultiply::usage	=	"NonCommutativeMultiply[tensor1, tensor2, ...] or tensor1 ** tensor2 ** ...  gives the outer product of an arbitrary number of tensors."
symmetrize::usage				=	"symmetrize[tensor, {index1,index2,...} (optional)] symmetrizes on the listed indices of tensor; if the list is omitted, symmetrizes on all indices; if multiple lists of indices are given, then it symmetrizes separately on the indices in each list."
antisymmetrize::usage			=	"antisymmetrize[tensor, {index1,index2,...} (optional)] antisymmetrizes on the listed indices of tensor; if the list is omitted, antisymmetrizes on all indices; if multiple lists of indices are given, then it antisymmetrizes separately on the indices in each list."
symmetricQ::usage				=	"symmetricQ[tensor, {index1,index2,...} (optional)] tests whether tensor is fully symmetric under interchange of the listed indices; if the list is omitted, tests for symmetry under interchange of all indices."
antisymmetricQ::usage			=	"antisymmetricQ[tensor, {index1,index2,...} (optional)] tests whether tensor is fully antisymmetric under interchange of the listed indices; if the list is omitted, tests for antisymmetry under interchange of all indices."
zeroQ::usage					=	"zeroQ[tensor] returns True if all entries of tensor are zero, False otherwise."
contract::usage					=	"contract[tensor, {index1,index2}, {index3,index4}, . . . (optional)]: contraction of index1 with index2, index3 with index4, etc., using the inverse metric (i.e. all indices to be contracted are assumed to be down). If no index pair is given, it returns the contraction of the first two indices."
raise::usage					=	"raise[tensor, {index1,index2,...} (optional)] raises index1, index2, etc. using the inverse metric; if the list of indices is omitted then all indices are raised (so they should all be down in the original tensor)."
lower::usage					=	"lower[tensor, {index1,index2,...} (optional)] lowers index1, index2, etc. using the metric; if the list of indices is omitted then all indices are lowered (so they should all be up in the original tensor)."
norm::usage						=	"norm[tensor] returns the contraction of tensor with itself. All indices are assumed to be down."
partial::usage					=	"partial[tensor]: partial derivative of a tensor; the derivative index is the first index of the resulting `tensor'."
divergence::usage				=	"divergence[vector]: the covariant divergence, where vector is given with an upper index (this also works with any totally antisymmetric tensor with all upper indices)."
scalarLaplacian::usage			=	"scalarLaplacian[scalar]: Laplacian of the scalar."
covariant::usage				=	"covariant[tensor, indexpositions (optional)]: covariant derivative of a tensor; the derivative index is the first index of the resulting tensor; the indexpositions argument is a list of the form {up,down,down}; if it is omitted, then all indices are assumed to be down. (The index position none is also allowed, indicating that the corresponding index should be ignored, i.e. no connection should be used.)"
Lie::usage						=	"Lie[vector, tensor, index_positions (optional)]: Lie derivative of the tensor with respect to the vector; the vector should be a vector, not a co-vector (i.e. it should have an upper index); the index_positions argument gives the positions of all the indices of the tensor; it is a list of the form {up,down,down}; if it is omitted, then all indices are assumed to be down. tensor may also be a form (\[DoubleStruckD] expression), in which case the index_positions argument is omitted."
commutator::usage				=	"commutator[vector1, vector2] returns the commutator of the two vector fields."
Christoffel::usage				=	"Christoffel symbol, with the upper index first."
rg::usage						=	"Square root of the absolute value of the determinant of the metric."
LeviCivita::usage				=	"Levi-Civita tensor, with all indices down; equivalent to volumeForm, but as a tensor (array)."
Riemann::usage					=	"Riemann tensor, with first three indices down and fourth index up. Such that: \!\(\*SubscriptBox[SuperscriptBox[SubscriptBox[\(R\), \(\[Sigma]\[Mu]\)], \(\[Rho]\)], \(\[Nu]\)]\) = Riemann[[\[Mu],\[Nu],\[Sigma],\[Rho]]]"
RicciTensor::usage				=	"Ricci tensor, with both indices down."
RicciScalar::usage				=	"Ricci scalar."
Einstein::usage					=	"Einstein tensor, with both indices down."
Weyl::usage						=	"Weyl tensor, with all indices down."



Begin["`Private`"];


(* Unprotect the variable names, just in case the package was already previously loaded *)

Unprotect[
	coordQ,
	dimen,
	NameToNumber,
	FullTensorQ,
	scalarQ,
	rank,
	padindexlist,
	transpose,
	swapIndices,
	tr,
	outer,
	symmetrize,
	antisymmetrize,
	symmetricQ,
	antisymmetricQ,
	zeroQ,
	inverse,
	contract,
	raise,
	lower,
	norm,
	partial,
	divergence,
	scalarLaplacian,
	covariant,
	Lie,
	commutator,
	Christoffel,
	rg,
	LeviCivita,
	Riemann,
	RicciTensor,
	RicciScalar,
	Einstein,
	Weyl
];



(* Define the coordinate list and metric inside the Private environment *)

coord = Global`coord
metric = Global`metric
dimen = Length[coord]


(* Consider as a default assumption that every coordinate belong to the Real numbers *)

If[$Assumptions == True, $Assumptions = Element[coord, Reals]]



(* Allow index values to be specified by coordinate name rather than number *)

coordQ[{}] = False

coordQ[expr_List] := And @@ (MemberQ[ coord, # ]& /@ expr )

coordQ[expr_] := MemberQ[coord, expr]

NameToNumber = Thread[coord -> Range[dimen]]

Unprotect[Part];

Part /: tensor_[[indices1___, index_?coordQ, indices2___]] :=
	tensor[[indices1, index /. NameToNumber, indices2]] /;
		(Dimensions[tensor][[Length[{indices1}] + 1]] == dimen)

(tensor_[[indices1___, index_?coordQ, indices2___]] = expr_) ^:=
	(tensor[[indices1, index /. NameToNumber, indices2]] = expr) /;
		(Dimensions[tensor][[Length[{indices1}] + 1]] == dimen)

(tensor_[[indices1___, index_?coordQ, indices2___]] := expr_) ^:=
	(tensor[[indices1, index /. NameToNumber, indices2]] := expr) /;
		(Dimensions[tensor][[Length[{indices1}] + 1]] == dimen)

Protect[Part];

Unprotect[Extract]

Extract[tensor_?ArrayQ, {indices1___, index_?coordQ, indices2___}, h___] :=
	Extract[tensor, {indices1, index /. NameToNumber, indices2}, h] /;
		(Dimensions[tensor][[Length[{indices1}] + 1]] == dimen)

Protect[Extract]



(* Tensor size and shape testing *)

FullTensorQ[expr_] := FullTensorQ[expr, dimen]

FullTensorQ[expr_, n_Integer] := ArrayQ[expr] && (Union[Dimensions[expr]] == {n})

scalarQ[expr_] := FreeQ[expr, SparseArray | List | dd]

rank[scalar_?scalarQ] = 0

rank[tensor_?FullTensorQ] := ArrayDepth[tensor]



(* Basic tensor algebra *)

padindexlist[indic_List] := Join[indic, Complement[Range[Max[indic]], indic]]

transpose[tensor_?ArrayQ, indic_List] := Transpose[tensor, Ordering[padindexlist[indic]]]

swapIndices[tensor_?ArrayQ, {index1_Integer,index2_Integer}] /; (index1 =!= index2) :=
	With[
		{minindex = Min[index1,index2], maxindex = Max[index1,index2]},
		Transpose[
		tensor,
		Join[Range[minindex-1], {maxindex}, Range[minindex+1,maxindex-1], {minindex}]
		]
	]

tr[tensor_?ArrayQ ] := Tr[tensor, Plus, 2] //Simplify

tr[tensor_?ArrayQ, indic:{_,_}..] := Nest[tr, transpose[tensor,Join[indic]], Length[{indic}]]

Unprotect[NonCommutativeMultiply];

(scalar_?scalarQ) ** a_ := scalar a //Simplify

a_ ** (scalar_?scalarQ) := scalar a //Simplify

NonCommutativeMultiply[tensors__?ArrayQ] := Outer[Times, tensors] // Simplify

Protect[NonCommutativeMultiply]

outer = NonCommutativeMultiply

symmetrize[scalar_?scalarQ] := scalar

symmetrize[tensor_?ArrayQ] := symmetrize[tensor, Range[ArrayDepth[tensor]]]

symmetrize[tensor_?ArrayQ, indi_List] :=
	With[
		{
		temptensor = transpose[tensor,indi],
		numb = Length[indi]
		},
		Transpose[
			Mean[Map[Transpose[temptensor,#]&, Permutations[Range[numb]]]],
			padindexlist[indi]
			] //Simplify
		]

symmetrize[tensor_?ArrayQ, indi1_List, indi2__List] := symmetrize[symmetrize[tensor, indi1], indi2]

antisymmetrize[scalar_?scalarQ] := scalar

antisymmetrize[tensor_?ArrayQ] := antisymmetrize[tensor, Range[ArrayDepth[tensor]]]

antisymmetrize[tensor_?ArrayQ, indi_List] :=
	With[
		{
		temptensor = transpose[tensor,indi],
		numb = Length[indi]
		},
		Transpose[
			Mean[Map[Signature[#]Transpose[temptensor,#]&, Permutations[Range[numb]]]],
			padindexlist[indi]
		] //Simplify
	]

antisymmetrize[tensor_?ArrayQ, indi1_List, indi2__List] := antisymmetrize[antisymmetrize[tensor, indi1], indi2]

symmetricQ[tensor_?ArrayQ, indices_List] := Equal @@ Append[(swapIndices[tensor,#]&) /@ Partition[indices,2,1], tensor] //Simplify

symmetricQ[tensor_?ArrayQ] := symmetricQ[tensor, Range[rank[tensor]]]

antisymmetricQ[tensor_?ArrayQ, indices_List] := Equal @@ Append[(swapIndices[tensor,#]&) /@ Partition[indices,2,1], -tensor] //Simplify

antisymmetricQ[tensor_?ArrayQ] := antisymmetricQ[tensor, Range[rank[tensor]]]

zeroQ[tensor_]:= (tensor === 0 tensor)



(* Making sure the metric is kosher *)

If[
	!(SymmetricMatrixQ[metric] && (Length[metric] == dimen)),
	Print[
		"Warning: the metric given is not a symmetric matrix with the correct dimensions!"
	];
	Abort[]
]



(* Contracting, raising, and lowering indices *)

inverse = Inverse[metric] //FullSimplify

contract[tensor_?ArrayQ] := tr[inverse . tensor]

contract[tensor_?ArrayQ, indic:{_,_}..] := Nest[tr[inverse . #]&, transpose[tensor,Join[indic]], Length[{indic}]]

raise[tensor_?ArrayQ] := raise[tensor, Range[ArrayDepth[tensor]]]

raise[tensor_?ArrayQ, indic_List] :=
	Fold[
		Transpose[
			Inner[Times, #1, inverse, Plus, #2],
			Join[Range[#2-1], Range[#2+1,ArrayDepth[tensor]], {#2}]
			] &,
		tensor,
		indic
	] //Simplify

lower[tensor_?ArrayQ] := lower[tensor, Range[ArrayDepth[tensor]]]

lower[tensor_?ArrayQ, indic_List] :=
	Fold[
		Transpose[
			Inner[Times, #1, metric, Plus, #2],
			Join[Range[#2-1], Range[#2+1,ArrayDepth[tensor]], {#2}]
			] &,
		tensor,
		indic
	] //Simplify

norm[ tensor_?FullTensorQ ] :=
	With[
		{
		trank = rank[tensor]
		},
		contract[
			tensor**tensor,
			Sequence @@ Table[ {i,trank+i}, {i,trank} ]
		]
	]



(* Partial, Lie and covariant derivatives *)

partial[tensor_] := Map[D[tensor,#]&, coord] //Simplify

dg = partial[metric]

Christoffel = inverse . (Transpose[dg,{2,1,3}] + Transpose[dg,{3,2,1}] - dg) / 2 //Simplify

Chrfel = tr[Christoffel]

divergence[vector_?ArrayQ] := Inner[D,vector,coord,Plus,1] + Chrfel . vector //Simplify

scalarLaplacian[scalar_?scalarQ] := divergence[inverse . partial[scalar]]

covariant[scalar_?scalarQ] := partial[scalar]

covariant[tensor_?FullTensorQ] := covariant[tensor, ConstantArray[down, rank[tensor]]]

covariant[tensor_, indexp:{(up|down|none)...}] :=
	With[
		{
		trank = Length[indexp],
		Christoffelt = Transpose[Christoffel, {3,2,1}]
		},
		partial[tensor] +
		Sum[
			Which[
				indexp[[index]] === down,
				- Transpose[
					Inner[Times, tensor, Christoffel, Plus, index],
					Join[Range[2,index], Range[index+2,trank+1], {1,index+1}]
				],
				indexp[[index]] === up,
				Transpose[
					Inner[Times, tensor, Christoffelt, Plus, index],
					Join[Range[2,index], Range[index+2,trank+1], {1,index+1}]
				],
				indexp[[index]] === none,
				0
			],
			{index,trank}
		]
	] //Simplify

Lie[vector_?VectorQ, scalar_?scalarQ] := vector . partial[scalar] //Simplify

Lie[vector_?VectorQ, tensor_?ArrayQ] := Lie[vector, tensor, ConstantArray[down, rank[tensor]]]

Lie[vector_?VectorQ, tensor_?ArrayQ, indexp:{(up|down)...}] :=
	With[
		{
		trank = Length[indexp],
		dvector1 = partial[vector],
		dvector2 = Transpose[partial[vector]]
		},
		vector . partial[tensor] +
		Sum[
			Which[
				indexp[[index]] === down,
				Transpose[
					Inner[Times, tensor, dvector2, Plus, index],
					Join[Range[1,index-1], Range[index+1,trank], {index}]
				],
				indexp[[index]] === up,
				- Transpose[
					Inner[Times, tensor, dvector1, Plus, index],
					Join[Range[1,index-1], Range[index+1,trank], {index}]
				]
			],
			{index,trank}
		]
	] //Simplify

commutator[vector1_?VectorQ, vector2_?VectorQ] := vector1 . partial[vector2] - vector2 . partial[vector1] //Simplify



(* Predefined scalars and tensors *)

zeroTensor[trank_Integer] := ConstantArray[0, ConstantArray[dimen, trank]]

rg :=
	(
	Unprotect[rg];
	rg =
		(
		detmet = Det[metric] //Simplify;
		If[ValueQ[metricsign]==False,
			metricsign = FullSimplify[Sign[detmet]]
		];
		Sqrt[metricsign detmet] //Simplify
		);
	Protect[rg];
	rg
	)

LeviCivita :=
	(
	Unprotect[LeviCivita];
	LeviCivita = rg Normal[ LeviCivitaTensor[ dimen ] ];
	Protect[LeviCivita];
	LeviCivita
	)

Riemann :=
	(
	Unprotect[Riemann];
	Riemann =
		With[
			{Christoffelt = Transpose[Christoffel,{3,1,2}]},
			2 antisymmetrize[
				Transpose[Christoffelt . Christoffelt,{1,3,2}] - partial[Christoffelt],
				{1,2}
			]
		];
	Protect[ Riemann ];
	Riemann
	)

RicciTensor :=
	(
	Unprotect[RicciTensor];
	RicciTensor =
		(
		tr[partial[Christoffel]] - partial[Chrfel]
		+ Chrfel . Christoffel - tr[Transpose[Christoffel . Christoffel,{1,3,2}]]
		) //Simplify;
	Protect[RicciTensor];
	RicciTensor
	)

RicciScalar :=
	(
	Unprotect[RicciScalar];
	RicciScalar = Tr[RicciTensor . inverse] //Simplify;
	Protect[RicciScalar];
	RicciScalar
	)

Einstein :=
	(
	Unprotect[Einstein];
	Einstein = RicciTensor - RicciScalar metric / 2 //Simplify;
	Protect[Einstein];
	Einstein
	)

Weyl :=
	(
	Unprotect[Weyl];
	Weyl =
		(
		lower[Riemann, {4}] +
		antisymmetrize[
			Transpose[metric ** (RicciScalar metric / (dimen - 1) - 2 RicciTensor), {1,3,4,2}],
			{1,2}, {3,4}
			] 2 / (dimen-2)
		) //Simplify;
	Protect[Weyl];
	Weyl
	)

If[dimen == 3,
	Cotton :=
		(
		Unprotect[Cotton];
		Cotton = contract[
			LeviCivita ** antisymmetrize[covariant[RicciTensor - RicciScalar metric / 4], {1,2}],
			{1,4}, {2,5}
			] //Simplify
		)
]


Protect[
	coordQ,
	dimen,
	NameToNumber,
	FullTensorQ,
	scalarQ,
	rank,
	padindexlist,
	transpose,
	swapIndices,
	tr,
	outer,
	symmetrize,
	antisymmetrize,
	symmetricQ,
	antisymmetricQ,
	zeroQ,
	inverse,
	contract,
	raise,
	lower,
	norm,
	partial,
	divergence,
	scalarLaplacian,
	covariant,
	Lie,
	commutator,
	Christoffel,
	rg,
	LeviCivita,
	Riemann,
	RicciTensor,
	RicciScalar,
	Einstein,
	Weyl
];

Protect @@ coord;


End[];


EndPackage[];
