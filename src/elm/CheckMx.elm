port module CheckMx exposing (..)

{-
   some bug means that this needs to be explicitly imported
   though it is used implicitly
-}

import Json.Decode
import Json.Encode

import Debug exposing (log)
import Json.Decode exposing (field)

import Maybe
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push


type alias Model =
    { current_check_email : String
    , socket : Phoenix.Socket.Socket Msg
    , mailCheck : Maybe MailCheck
    }


type alias MailCheck =
    { validMx : Bool
    , suggestion : String
    , hostname : String
    , hasSuggestion : Bool
    }



-- Browser Bound


port check_email_response : MailCheck -> Cmd msg



-- Elm-Bound


port check_email : (String -> msg) -> Sub msg



{- -}


type Msg
    = CheckEmail String
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveMailCheck Json.Encode.Value



-- generated with http://eeue56.github.io/json-to-elm/


decodeMailCheck : Json.Decode.Decoder MailCheck
decodeMailCheck =
    Json.Decode.map4 MailCheck
        (field "validMx" Json.Decode.bool)
        (field "suggestion" Json.Decode.string)
        (field "hostname" Json.Decode.string)
        (field "hasSuggestion" Json.Decode.bool)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [
         Phoenix.Socket.listen model.socket PhoenixMsg
        ]


socketServer : String
socketServer =
    -- http://web.production-elixir-service.36cf5ace.svc.dockerapp.io:8080/socket/websocket
    "ws://localhost:4000/socket/websocket"

initSocket : Phoenix.Socket.Socket Msg
initSocket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "check-mx" "dns" ReceiveMailCheck
initModel : Model
initModel =
     { current_check_email = ""
      , socket = initSocket
      , mailCheck = Nothing
      }


init : ( Model, Cmd msg )
init =
    ( initModel
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
          let
            ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.socket
          in
            ( { model | socket = phxSocket }
            , Cmd.map PhoenixMsg phxCmd
            )
        CheckEmail email ->
            log email
                ( { model | current_check_email = email }
                , Cmd.none
                )
        ReceiveMailCheck raw ->
            case Json.Decode.decodeValue decodeMailCheck raw of
                Ok mailCheck ->
                    ( { model| mailCheck = Just (log "mailCheck" mailCheck) }, Cmd.none)
                Err error ->
                    (model, Cmd.none)



main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
