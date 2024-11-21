module BlogPost exposing (BlogPost, blogPostDecoder)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)


type alias BlogPost =
    { content : String
    , tags : List String
    , published : Date
    , title : String
    }


dateDecoder : Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case Date.fromIsoString str of
                    Ok date ->
                        Decode.succeed date

                    Err _ ->
                        Decode.fail "Invalid date"
            )


blogPostDecoder : String -> Decoder BlogPost
blogPostDecoder body =
    Decode.map4 BlogPost
        (Decode.succeed body)
        (Decode.field "tags" (Decode.list Decode.string))
        (Decode.field "published" dateDecoder)
        (Decode.field "title" Decode.string)
