module App.Update exposing (..)

import Dom
import Dom.Scroll
import Task
import Keys exposing (ctrl, meta, enter)
import Utils exposing (isBlank, validateEmail)
import App.Model exposing (..)
import App.Messages exposing (..)
import App.Commands exposing (..)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []
            
        SessionFetched (Ok session) ->
            ( { model | session = Just session }, Cmd.none )
            
        SessionFetched (Err _) ->
            ( model, Cmd.none )
            
        CotosFetched (Ok cotos) ->
            ( { model | cotos = cotos }, Cmd.none )
            
        CotosFetched (Err _) ->
            ( model, Cmd.none )

        KeyDown key ->
            if key == ctrl.keyCode || key == meta.keyCode then
                ( { model | ctrlDown = True }, Cmd.none )
            else
                ( model, Cmd.none )

        KeyUp key ->
            if key == ctrl.keyCode || key == meta.keyCode then
                ( { model | ctrlDown = False }, Cmd.none )
            else
                ( model, Cmd.none )

        EditorFocus ->
            ( { model | editingNewCoto = True }, Cmd.none )

        EditorBlur ->
            ( { model | editingNewCoto = False }, Cmd.none )

        EditorInput content ->
            ( { model | newCoto = content }, Cmd.none )

        EditorKeyDown key ->
            if key == enter.keyCode && model.ctrlDown && (not (isBlank model.newCoto)) then
                post model
            else
                ( model, Cmd.none )
                
        Post ->
            post model
                
        CotoPosted (Ok coto) ->
            ( model, Cmd.none )
          
        CotoPosted (Err _) ->
            ( model, Cmd.none )
            
        SigninClick ->
            ( { model | showSigninModal = True }, Cmd.none )
            
        SigninModalClose ->
            ( { model | showSigninModal = False, signinRequestDone = False }, Cmd.none )
            
        SigninEmailInput content ->
            ( { model | signinEmail = content }, Cmd.none )
            
        SigninWithAnonymousCotosCheck checked ->
            ( { model | signinWithAnonymousCotos = checked }, Cmd.none )
           
        SigninRequestClick ->
            { model | signinRequestProcessing = True }
                ! [ requestSignin model.signinEmail model.signinWithAnonymousCotos ]
           
        SigninRequestDone (Ok message) ->
            ( { model | signinEmail = "", signinRequestProcessing = False, signinRequestDone = True }, Cmd.none )
            
        SigninRequestDone (Err _) ->
            ( { model | signinRequestProcessing = False }, Cmd.none )


post : Model -> ( Model, Cmd Msg )
post model =
    { model | cotos = (Coto model.newCoto) :: model.cotos, newCoto = "" }
        ! [ Task.attempt handleScrollResult (Dom.Scroll.toBottom "timeline") 
          , postCoto (Coto model.newCoto)
          ]


handleScrollResult : Result Dom.Error () -> Msg
handleScrollResult result =
    case result of
        Ok _ ->
            NoOp

        Err _ ->
            NoOp