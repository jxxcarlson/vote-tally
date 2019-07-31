module Backend exposing (Model, app, userList)

import Dict exposing (Dict)
import Frontend
import Lamdera.Backend
import Lamdera.Types exposing (..)
import Maybe.Extra
import Msg exposing (..)
import Set exposing (Set)
import TestData exposing (passwordDict)
import User exposing (PasswordDict, User, UserDict, UserInfo, Username)
import Vote exposing (VoteCount)


app =
    Lamdera.Backend.application
        { init = init
        , update = update
        , subscriptions = \m -> Sub.none
        , updateFromFrontend = updateFromFrontend
        }



--
-- MODEL
--


type alias Model =
    { passwordDict : PasswordDict
    , userDict : UserDict
    , voteCount : VoteCount
    , clients : Set ClientId
    }


init : ( Model, Cmd BackendMsg )
init =
    ( { passwordDict = TestData.passwordDict
      , userDict = TestData.userDict
      , voteCount = TestData.voteCount
      , clients = Set.empty
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        -- Our sendToFrontend Cmd has completed
        SentToFrontendResult clientId result ->
            case result of
                Ok () ->
                    ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


updateFromFrontend : ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        RequestUsers ->
            ( model, sendToFrontend clientId (SendUserList (userList model.userDict)) )

        SignInUser username password ->
            case User.validateUser model.passwordDict username password of
                True ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId <| ValidateUser (User.fromDict model.userDict username)
                        , sendToFrontend clientId (SendVoteCount model.voteCount)
                        ]
                    )

                False ->
                    ( model, sendToFrontend clientId <| ValidateUser Nothing )

        SendChangePasswordInfo username password newPassword ->
            case User.validateUser model.passwordDict username password of
                True ->
                    let
                        passwordUpdater =
                            Maybe.map (\ep -> User.encrypt newPassword)

                        newPasswordDict =
                            Dict.update username passwordUpdater model.passwordDict
                    in
                    ( { model | passwordDict = newPasswordDict }, sendToFrontend clientId <| SendMessage "Password changed" )

                False ->
                    ( model, sendToFrontend clientId <| SendMessage "Could not change password" )

        SendSignUpInfo username password email ->
            case User.add username password email ( model.passwordDict, model.userDict ) of
                Ok ( newPasswordDict, newUserDict ) ->
                    ( { model | userDict = newUserDict, passwordDict = newPasswordDict }
                    , sendToFrontend clientId <| ValidateUser (User.fromDict newUserDict username)
                    )

                Err str ->
                    ( model, sendToFrontend clientId <| ValidateUser Nothing )

        BECastVote username candidate ->
            let
                newVoteCount =
                    Vote.cast candidate model.voteCount
            in
            ( { model
                | userDict = User.enterUserAsVoted username model.userDict
                , voteCount = newVoteCount
              }
            , broadcast model.clients (SendVoteCount newVoteCount)
            )

        ClientJoin ->
            ( model, Cmd.none )


broadcast clients msg =
    clients
        |> Set.toList
        |> List.map (\clientId -> sendToFrontend clientId msg)
        |> Cmd.batch


sendToFrontend : ClientId -> ToFrontend -> Cmd BackendMsg
sendToFrontend clientId msg =
    Lamdera.Backend.sendToFrontend 1000 clientId (\_ -> NoOpBackendMsg) msg



--
-- HELPERS
--


userList : UserDict -> List User
userList userDict =
    List.map (User.fromDict userDict) (Dict.keys userDict)
        |> Maybe.Extra.values
