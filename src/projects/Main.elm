import Browser
import Html
import Http
import Json.Encode as Encode
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view >> toUnstyled
        }


-- MODEL


type alias Project =
    { id : Int
    , name : String
    , owner : Int    
    }


type alias NewProject =
     { name : String
     , owner : Int
     }


type alias User =
    { id : Int
    , name : String
    , accessToken : String
    }


type alias Model =
    { projectNameNew : String
    , newMode : Bool
    , projects : List Project
    , editProject : Maybe Project
    , user : User
    , errorMessage : String
    }


emptyProject : Project
emptyProject =
    { id = -1, name = "", owner = -1 }

        
init : User -> ( Model, Cmd Msg )
init user =
    ( { projectNameNew = ""
      , newMode = False
      , projects = []
      , editProject = Nothing
      , user = user
      , errorMessage = ""
      }
      , getProjects
      )


getProjects : Cmd Msg
getProjects =
    Http.get
        { url = "/get/projects"
        , expect = Http.expectJson GetProjects projectsDecoder
        }


postNewProject : NewProject -> Cmd Msg
postNewProject newProject =
    Http.post
        { url = "/new/project"
        , body = Http.jsonBody (newProjectEncoder newProject)
        , expect = Http.expectWhatever PostNewProject
        }


postEditProjectName : Project -> Cmd Msg
postEditProjectName project =
    Http.post
        { url = "/edit/project"
        , body = Http.jsonBody (projectEncoder project)
        , expect = Http.expectWhatever PostEditProject
        }


projectsDecoder : Decode.Decoder (List Project)
projectsDecoder =
    Decode.list projectDecoder


projectDecoder : Decode.Decoder Project
projectDecoder =
    Decode.map3 Project
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "created-by" Decode.int)


projectEncoder : Project -> Encode.Value
projectEncoder project =
               Encode.object
                [ ("id", Encode.int project.id)
                , ("name", Encode.string project.name)
                , ("created-by", Encode.int project.owner)
                ]


newProjectEncoder : NewProject -> Encode.Value
newProjectEncoder newProject =
               Encode.object
                [ ("name", Encode.string newProject.name)
                , ("created-by", Encode.int newProject.owner)
                ]


-- UPDATE


toErrorMessage : Http.Error -> String
toErrorMessage error =
    case error of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "timeout"

        Http.NetworkError ->
            "network error"

        Http.BadStatus status ->
            "Bad Status Code: " ++ (String.fromInt status)

        Http.BadBody message ->
            message

                
type Msg
    = ProjectNameEdit String
    | GetProjects (Result Http.Error (List Project))
    | EditProject Project
    | SaveEditProject
    | CancelEditProject
    | ProjectNew
    | CancelNewProject
    | ProjectNameNew String
    | SaveNewProject
    | PostNewProject (Result Http.Error ())
    | PostEditProject (Result Http.Error ())

      
setProjectName : Project -> String -> Project
setProjectName project newName =
    { project | name = newName }

        
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
       case msg of
            ProjectNew ->
                       ( { model | newMode = True }, Cmd.none )

            EditProject project ->
                 ( { model | editProject = Just project }, Cmd.none )

            ProjectNameEdit projectName ->
                let
                    ep = Maybe.withDefault emptyProject model.editProject
                in
                    ( { model | editProject = Just (setProjectName ep projectName) }, Cmd.none )

            SaveEditProject ->
                let
                    ep = Maybe.withDefault emptyProject model.editProject
                in
                    ( model, postEditProjectName ep )

            CancelEditProject ->
                 ( { model | editProject = Nothing }, Cmd.none )

            CancelNewProject ->
                 ( { model | newMode = False, projectNameNew = "" }, Cmd.none )

            SaveNewProject ->
                 ( { model | newMode = False, projectNameNew = "" },  postNewProject { name = model.projectNameNew, owner = model.user.id } )

            ProjectNameNew p ->
                 ( { model | projectNameNew = p }, Cmd.none )

            PostNewProject result ->
                case result of
                    Ok _ ->
                        ( { model | projectNameNew = "", newMode = False }, getProjects )

                    Err err ->
                        ( { model | errorMessage = (toErrorMessage err) }, Cmd.none )

            PostEditProject result ->
                case result of
                    Ok _ ->
                        ( { model | editProject = Nothing }, getProjects )

                    Err err ->
                        ( { model | errorMessage = (toErrorMessage err) }, Cmd.none )

            GetProjects result ->
                case result of
                    Ok projects ->
                        ( { model | projects = projects }, Cmd.none )

                    Err err ->
                        ( { model | errorMessage = (toErrorMessage err) }, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
     div []
         [ div [] [ text ("Welcome " ++ model.user.name) ]
         , button [ onClick ProjectNew ] [ text "+" ]
         , text model.errorMessage
         , newProjectView model
         , projectsView model
         ]


newProjectView : Model -> Html Msg
newProjectView model =
    if model.newMode then
        div []
            [ input [ value model.projectNameNew, onInput ProjectNameNew ] []
            , button [ onClick SaveNewProject ] [ text "Save" ]
            , button [ onClick CancelNewProject ] [ text "Cancel" ]
            ]
     else
         div [] [ text "Click + to create a new project" ]


projectsView : Model -> Html Msg
projectsView model =
    div []
        (List.map
            (\project -> (projectView project model))
            model.projects
        )


tasksUrl : Model -> Project -> String
tasksUrl model project =
    "/tasks?projectid=" ++ (String.fromInt project.id) ++ "&projectname=" ++ project.name ++ "&userid=" ++ (String.fromInt model.user.id) ++ "&username=" ++ model.user.name

defaultProjectView : Model -> Project -> Html Msg
defaultProjectView model project =
    div []
        [ a [ href (tasksUrl model project) ] [ text project.name ]
        , button [ onClick <| EditProject project ] [ text "Edit" ]
        ]


editProjectView : Project -> Html Msg
editProjectView project =
    div []
        [ input [ value project.name, onInput ProjectNameEdit ] []        
        , button [ onClick SaveEditProject ] [ text "Save" ]
        , button [ onClick CancelEditProject ] [ text "Cancel" ]
        ]        


projectView : Project -> Model -> Html Msg
projectView project model =
    if model.editProject == Nothing then
        defaultProjectView model project
    else        
        let
            ep = Maybe.withDefault emptyProject model.editProject
        in
            if ep.id == project.id then
                editProjectView ep
            else
                defaultProjectView model project
