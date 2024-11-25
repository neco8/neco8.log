module BackendTask.ConvertMarkdownFiles exposing (Rule, run, ConversionResult)

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Json.Encode as Encode


type alias Rule =
    { before : String
    , after : String
    }


type alias ConversionResult =
    { success : Bool
    , source : String
    , destination : Maybe String
    , error : Maybe String
    }


resultDecoder : Decode.Decoder ConversionResult
resultDecoder =
    Decode.map4 ConversionResult
        (Decode.field "success" Decode.bool)
        (Decode.field "source" Decode.string)
        (Decode.maybe (Decode.field "destination" Decode.string))
        (Decode.maybe (Decode.field "error" Decode.string))


encodeRule : Rule -> Encode.Value
encodeRule rule =
    Encode.object
        [ ( "before", Encode.string rule.before )
        , ( "after", Encode.string rule.after )
        ]


run :
    { sourceDir : String
    , destDir : String
    , rules : List Rule
    }
    -> BackendTask FatalError (List ConversionResult)
run params =
    BackendTask.Custom.run "convertMarkdownFiles"
        (Encode.object
            [ ( "sourceDir", Encode.string params.sourceDir )
            , ( "destDir", Encode.string params.destDir )
            , ( "rules", Encode.list encodeRule params.rules )
            ]
        )
        (Decode.list resultDecoder)
        |> BackendTask.allowFatal
