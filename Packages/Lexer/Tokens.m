(* ::Package:: *)

(* Autogenerated Package *)

(* ::Section:: *)
(*Tokens*)



TokenStream::usage="An object representing a stream of tokens";


SetTokenizerCheckpoint::usage="Sets the Tokenizer checkpoint";
ResetTokenizerCheckpoint::usage="Reverts the Tokenizer checkpoint";
WithTokenizerCheckpoint::usage="Wrapper for tokenizing";


TokenRead::usage="Pulls n tokens out of a TokenStream";
TokenStreamer::usage="Lower-level object for faster token streaming";


Begin["`Private`"];


(* ::Subsection:: *)
(*TokenStream*)



RegisterInterface[
  TokenStream,
  {
    "Tokens",
    "Stream"
    },
  "Constructor"->buildTokenStream
  ]


(* ::Subsubsubsection::Closed:: *)
(*buildTokenStream*)



buildTokenStream[l_LexerObject, i_InputStream]:=
  <|"Tokens"->l["Tokens"], "Stream"->i|>;
buildTokenStream[l_LexerObject, s_String?(Not@*FileExistsQ)]:=
  buildTokenStream[l, StringToStream[s]];
buildTokenStream[l_LexerObject, s_String?(FileExistsQ)]:=
 buildTokenStream[l, OpenRead[s]];


(* ::Subsubsubsection::Closed:: *)
(*Methods*)



InterfaceMethod[TokenStream]@
  t_TokenStream["Read"][n:_Integer?Positive:1]:=
    TokenRead[t, n];
InterfaceMethod[TokenStream]@
  t_TokenStream["Streamer"][]:=
    TokenStreamer[t];
InterfaceMethod[TokenStream]@
  t_TokenStream["Close"][]:=
    Close@t["Stream"];


(* ::Subsection:: *)
(*TokenRead*)



(* ::Subsubsection::Closed:: *)
(*$checkpoints*)



(* ::Text:: *)
(*
	Might be better to do with Language`ExpressionStore ?
*)



If[!AssociationQ[$checkpoints], $checkpoints=<||>];


SetTokenizerCheckpoint[stream_]:=
  $checkpoints[stream] = StreamPosition[stream];
ResetTokenizerCheckpoint[stream_]:=
  SetStreamPosition[stream, $checkpoints[stream]];
WithTokenizerCheckpoint[stream_, expr_]:=
  Block[{$checkpoints = If[!AssociationQ[$checkpoints], <||>, $checkpoints]},
    SetTokenizerCheckpoint[stream];
    expr
    ];
WithTokenizerCheckpoint~SetAttributes~HoldRest;


(* ::Subsubsection::Closed:: *)
(*readStringToken*)



readStringToken[tok_, escape_:"\\"][stream_, body_, token_]:=
  Module[
    {
      tmp,
      str = Read[stream, Record, RecordSeparators->{tok}]
      },
    While[StringQ[str]&&StringEndsQ[str, escape],
      tmp = Read[stream, Record, RecordSeparators->{tok}];
      If[tmp===EndOfFile, Break[]];
      str = str<>tok<>tmp;
      ];
    str
    ]


(* ::Subsubsection::Closed:: *)
(*readLookAhead*)



readLookAhead[lookAheadDispatcher_]:=
  readLookAhead[lookAheadDispatcher, tokenPuller[Keys[lookAheadDispatcher]]];
readLookAhead[lookAheadDispatcher_, tokenPuller_][stream_, body_, token_]:=
  lookAheadDispatcher[tokenPuller[stream]][stream, body, token]


(* ::Subsubsection::Closed:: *)
(*TokenStreamer*)



(* ::Text:: *)
(*
	Designed to be as minimal overhead as can still be convenient
*)



TokenStreamer[t_]:=
  Module[{stream=t["Stream"], spec=prepTokenHandlers@t["Tokens"]},
    TokenStreamer[stream, spec, t]
    ];
TokenStreamer[stream_, spec_, t_]:=
  TokenStreamer[{
    t,
    stream,
    spec["Handlers"], 
    spec["Characters"],
    tokenPuller[spec["Characters"]]
    }];
TokenStreamerRead[TokenStreamer[{t_, stream_, handlers_, seps_, tokPuller_}], n_]:=
  Module[{body, token},
    Table[
      body = 
        Read[stream, Record,
          RecordSeparators->seps
          ];
      If[body===EndOfFile, 
        handlers[EndOfFile][
          t,
          EndOfFile,
          EndOfFile
          ],
        token = tokPuller[stream];
        handlers[token][
          t,
          body,
          token
          ]
        ],
      n
      ]
    ]
(tks:TokenStreamer[{t_, stream_, handlers_, seps_, tokPuller_}])@"Read"[n_]:=
  WithTokenizerCheckpoint[
    stream,
    TokenStreamerRead[tks, n]
    ];
 (tks:TokenStreamer[{t_, stream_, handlers_, seps_, tokPuller_}])@"Read"[]:=
   (tks@"Read"[1])[[1]];
 (tks:TokenStreamer[{t_, stream_, handlers_, seps_, tokPuller_}])@"Peek"[n_]:=
   WithTokenizerCheckpoint[
     stream,
     (ResetTokenizerCheckpoint[stream]; #)&@TokenStreamerRead[tks, n]
     ];
  (tks:TokenStreamer[{t_, stream_, handlers_, seps_, tokPuller_}])@"Peek"[]:=
   (tks@"Peek"[1])[[1]];


(* ::Subsubsection::Closed:: *)
(*tokenRead*)



(* ::Subsubsubsection::Closed:: *)
(*tokenPuller*)



tokenPuller[tokens_]:=
  tokenPuller[
    AssociationThread[Keys[tokens], None], 
    Min[StringLength/@Select[tokens, StringQ]]
    ];
tokenPuller[tokSet_, min_][stream_]:=
  pullTokenToo[stream, tokSet, min];
pullTokenToo[stream_, tokSet_, minTok_]:=
  Module[{tok=ReadList[stream, Character, minTok], tmp},
    If[AllTrue[tok, StringQ],
      tok = StringJoin[tok],
      Return[EndOfFile, Module]
      ];
    While[!KeyExistsQ[tokSet, tok],
      tmp = Read[stream, Character];
      If[tmp===EndOfFile, Return[EndOfFile, Module]];
      tok = tok<>tmp;
      ];
    tok
    ]


(* ::Subsubsubsection::Closed:: *)
(*tokenRead*)



tokenRead[stream_, spec_, t_]:=
  TokenStreamer[stream, spec, t]@"Read"[];


(* ::Subsubsubsection::Closed:: *)
(*tokenPeek*)



tokenRead[stream_, spec_, t_]:=
  TokenStreamer[stream, spec, t]@"Peek"[];


(* ::Subsubsubsection::Closed:: *)
(*tokenReadList*)



(* ::Subsubsubsubsection::Closed:: *)
(*old*)



(* ::Text:: *)
(*
	Realized this won\[CloseCurlyQuote]t work as the Handler gets applied too late...
*)



otokenReadList[stream_, spec_, n_]:=
  Module[
    {
      body, token, final, strPos,
        handlers=spec["Handlers"], 
        seps=spec["Characters"],
        nullHandle, read
        },
    body = 
      ReadList[stream, Record, n,
        RecordSeparators->seps
        ];
    body = PadRight[body, n, EndOfFile];
    final = Read[stream, Character];
    strPos = Pick[Range[n], StringQ/@body];
    If[Length@strPos < 2,
      nullHandle = Lookup[handlers, EndOfFile, LexerToken];
      Return[
        Map[
          nullHandle[
            stream,
            #,
            EndOfFile
            ]&,
          body
          ], 
        Module
        ]
      ];
    strPos = Rest@strPos;
    token = StringTake[body[[strPos]], 1];
    If[n-Max[strPos]>0,
      token = Join[token, ConstantArray[EndOfFile, n-Max[strPos]]]
      ];
    token = Append[token, final];
    MapThread[
      #[stream, #2, #3]&,
      {
        Lookup[handlers, token, LexerToken],
        body,
        token
        }
      ]
    ];


(* ::Subsubsubsubsection::Closed:: *)
(*new*)



tokenReadList[stream_, spec_, n_, t_]:=
  TokenStreamer[stream, spec, t]@"Read"[n];


(* ::Subsubsubsection::Closed:: *)
(*tokenPeekList*)



tokenPeekList[stream_, spec_, n_, t_]:=
  TokenStreamer[stream, spec, t]@"Peek"[n];


(* ::Subsubsection::Closed:: *)
(*TokenRead*)



(* ::Subsubsubsection::Closed:: *)
(*prepTokenHandlers*)



prepTokenHandler//Clear;
prepTokenHandler[{"Stream", char_, escape___}]:=readString[char, escape];
prepTokenHandler[{"LookAhead", dispatch_}]:=readLookAhead[dispatch];
prepTokenHandler[e_]:=e;


prepTokenHandlers[tokens_]:=
  ReplacePart[
    tokens,
    "Handlers"->
      Join[
        <|
          EndOfFile->LexerToken
          |>,
        Map[
          prepTokenHandler,
          tokens["Handlers"]
          ]
        ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*TokenRead*)



TokenRead[t_TokenStream, n:_Integer?Positive:1]:=
  Module[{stream=t["Stream"], spec=prepTokenHandlers@t["Tokens"]},
    If[n>1, 
        tokenReadList[stream, spec, n, t],
        tokenRead[stream, spec, t]
        ]
    ];


(* ::Subsubsubsection::Closed:: *)
(*TokenRead*)



TokenPeek[t_TokenStream, n:_Integer?Positive:1]:=
  Module[{stream=t["Stream"], spec=prepTokenHandlers@t["Tokens"]},
    If[n>1, 
      tokenPeekList[stream, spec, n, t],
      tokenPeek[stream, spec, t]
      ]
    ];


End[];



