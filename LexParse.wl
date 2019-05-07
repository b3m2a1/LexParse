(* ::Subsection::Closed:: *)
(*Temp Loading Flag Code*)


Temp`PackageScope`LexParseLoading`Private`$PackageLoadData=
  If[#===None, <||>, Replace[Quiet@Get@#, Except[_?OptionQ]-><||>]]&@
    Append[
      FileNames[
        "LoadInfo."~~"m"|"wl",
        FileNameJoin@{DirectoryName@$InputFileName, "Config"}
        ],
      None
      ][[1]];
Temp`PackageScope`LexParseLoading`Private`$PackageLoadMode=
  Lookup[Temp`PackageScope`LexParseLoading`Private`$PackageLoadData, "Mode", "Primary"];
Temp`PackageScope`LexParseLoading`Private`$DependencyLoad=
  TrueQ[Temp`PackageScope`LexParseLoading`Private`$PackageLoadMode==="Dependency"];


(* ::Subsection:: *)
(*Main*)


If[Temp`PackageScope`LexParseLoading`Private`$DependencyLoad,
  If[!TrueQ[Evaluate[Symbol["`LexParse`PackageScope`Private`$LoadCompleted"]]],
    Get@FileNameJoin@{DirectoryName@$InputFileName, "LexParseLoader.wl"}
    ],
  If[!TrueQ[Evaluate[Symbol["LexParse`PackageScope`Private`$LoadCompleted"]]],
    <<LexParse`LexParseLoader`,
   BeginPackage["LexParse`"];
   EndPackage[];
   ]
  ]