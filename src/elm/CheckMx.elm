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


port checkEmailResponse : MailCheck -> Cmd msg



-- Elm-Bound


port checkEmail : (String -> msg) -> Sub msg



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
         checkEmail CheckEmail
         , Phoenix.Socket.listen model.socket PhoenixMsg
        ]


socketServer : String
socketServer =
    -- http://web.production-elixir-service.36cf5ace.svc.dockerapp.io:8080/socket/websocket
    "ws://localhost:4000/socket/websocket"

joinChannel : (Phoenix.Socket.Socket Msg) -> ( Phoenix.Socket.Socket Msg , Cmd (Phoenix.Socket.Msg Msg) )
joinChannel aSocket =
    let
        channel = Phoenix.Channel.init "dns"
    in
        Phoenix.Socket.join channel aSocket
 
initSocket : Phoenix.Socket.Socket Msg
initSocket =
    Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "check-mx" "dns" ReceiveMailCheck


init : ( Model, Cmd Msg )
init =
    let
        (socket, cmd) = joinChannel initSocket
    in
      let
          initModel = { current_check_email = ""
                      , socket = socket
                      , mailCheck = Nothing
                      }

      in
      ( initModel
      , Cmd.map PhoenixMsg cmd
      )


updateCheckEmail: Model -> String -> (Model, Cmd Msg)
updateCheckEmail model email =
    let
        payload =
            (Json.Encode.object [ ( "email", Json.Encode.string email ) ])

        push_ =
            Phoenix.Push.init "check-mx" "dns"
                |> Phoenix.Push.withPayload payload
        ( phxSocket, phxCmd ) =
            Phoenix.Socket.push push_ model.socket
    in
        ( { model
            | current_check_email = (log "email" email)
            , socket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd
        )

updatePhoenixMsg: Model -> (Phoenix.Socket.Msg Msg) -> (Model , Cmd Msg)
updatePhoenixMsg model msg =
    let
      ( phxSocket, phxCmd ) = Phoenix.Socket.update (log "msg" msg) model.socket
    in
      ( { model | socket = phxSocket }
      , Cmd.map PhoenixMsg phxCmd
      )


updateRecieveMailCheck: Model -> Json.Decode.Value -> (Model , Cmd Msg)
updateRecieveMailCheck model raw =
    case Json.Decode.decodeValue decodeMailCheck (log "raw " raw) of
        Ok mailCheck ->
            ( { model| mailCheck = Just (log "mailCheck" mailCheck) }, Cmd.none)
        Err error ->
            (model, Cmd.none)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            updatePhoenixMsg model msg
        CheckEmail email ->
            updateCheckEmail model email
        ReceiveMailCheck raw ->
            updateRecieveMailCheck model raw


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
