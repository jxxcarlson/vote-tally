module User exposing
    ( Password
    , PasswordDict
    , User
    , UserDict
    , UserInfo
    , Username
    , add
    , castVote
    , deleteUser
    , encrypt
    , enterUserAsVoted
    , fromDict
    , getData
    , validateChangePassword
    , validateSignUpInfo
    , validateUser
    )

import Dict exposing (Dict)


type alias Username =
    String


type alias Password =
    String


type alias PasswordDict =
    Dict Username Password


type alias UserDict =
    Dict Username UserInfo


type alias UserInfo =
    { email : String, admin : Bool, voted : Bool }


type alias User =
    { username : Username, email : String, admin : Bool, voted : Bool }


castVote : User -> User
castVote user =
    { user | voted = True }


enterUserAsVoted : Username -> UserDict -> UserDict
enterUserAsVoted username userDict =
    let
        updater =
            Maybe.map (\userInfo -> { userInfo | voted = True })
    in
    Dict.update username updater userDict


fromDict : UserDict -> Username -> Maybe User
fromDict userDict username =
    case Dict.get username userDict of
        Nothing ->
            Nothing

        Just userInfo ->
            Just { username = username, email = userInfo.email, admin = userInfo.admin, voted = userInfo.voted }


getData : Username -> UserDict -> Maybe UserInfo
getData username dict =
    Dict.get username dict


encrypt : String -> String
encrypt str =
    "!@" ++ String.reverse str ++ "@!"


validatePassword : String -> String -> Bool
validatePassword password encryptedPassword =
    encrypt password == encryptedPassword


validateUser : PasswordDict -> Username -> String -> Bool
validateUser passwordDict username passWord =
    case Dict.get username passwordDict of
        Nothing ->
            False

        Just encryptedPassword ->
            validatePassword passWord encryptedPassword


validateSignUpInfo : Username -> String -> String -> List String
validateSignUpInfo username password email =
    []
        |> userNameLongEnough username
        |> passwordLongEnough password
        |> emailValid email


validateChangePassword : String -> String -> List String
validateChangePassword password1 password2 =
    []
        |> passwordsMatch password1 password2
        |> passwordLongEnough password1


passwordsMatch : String -> String -> List String -> List String
passwordsMatch password1 password2 errorList =
    case password1 == password2 of
        True ->
            errorList

        False ->
            "Passwords don't match" :: errorList


userNameLongEnough username errorList =
    case String.length username < 6 of
        True ->
            "Username must have at least six characters" :: errorList

        False ->
            errorList


passwordLongEnough password errorList =
    case String.length password < 6 of
        True ->
            "Password must have at least six characters" :: errorList

        False ->
            errorList


emailValid email errorList =
    case String.contains "@" email && String.length email > 3 of
        False ->
            "Email is not valid" :: errorList

        True ->
            errorList


add : String -> String -> String -> ( PasswordDict, UserDict ) -> Result String ( PasswordDict, UserDict )
add username password email ( passwordDict, userDict ) =
    case ( Dict.member username userDict, passwordErrors password ) of
        ( False, [] ) ->
            let
                newPasswordDict =
                    Dict.insert username (encrypt password) passwordDict

                newUserInfo =
                    { email = email, admin = False, voted = False }

                newUserDict =
                    Dict.insert username newUserInfo userDict
            in
            Ok ( newPasswordDict, newUserDict )

        _ ->
            Err "user already exists"


passwordErrors : String -> List String
passwordErrors str =
    []


deleteUser : Username -> ( PasswordDict, UserDict ) -> ( PasswordDict, UserDict )
deleteUser username ( passwordDict, userDict ) =
    ( Dict.remove username passwordDict, Dict.remove username userDict )
