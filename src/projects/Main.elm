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
    , owner : String
    }


type alias NewProject =
     { name : String
     , owner : String
     }

type alias Model =
    { projectNameEdit : String
    , ownerNameEdit : String
    , projectNameNew : String
    , newMode : Bool
    , projects : List Project
    , editProject : Int
    , editMode : Bool
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { projectNameEdit = ""
      , ownerNameEdit = ""
      , projectNameNew = ""
      , newMode = False
      , projects = []
      , editProject = 0
      , editMode = False
      }
      , getProjects
      )


getProjects : Cmd Msg
getProjects =
    Http.get
        { url = "/projects"
        , expect = Http.expectJson GetProjects projectsDecoder
        }


postNewProject : NewProject -> Cmd Msg
postNewProject newProject =
    Http.post
        { url = "/new/project/"
        , body = Http.jsonBody (newProjectEncoder newProject)
        , expect = Http.expectWhatever PostNewProject
        }


editProject : Model -> Project
editProject model =
    { id = model.editProject, name = model.projectNameEdit, owner = model.ownerNameEdit }


postEditProject : Model -> Cmd Msg
postEditProject model =
    Http.post
        { url = "/edit/project/"
        , body = Http.jsonBody (projectEncoder (editProject model))
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
        (Decode.field "owner" Decode.string)


projectEncoder : Project -> Encode.Value
projectEncoder project =
               Encode.object
                [ ("id", Encode.int project.id)
                , ("name", Encode.string project.name)
                , ("owner", Encode.string project.owner)
                ]


newProjectEncoder : NewProject -> Encode.Value
newProjectEncoder newProject =
               Encode.object
                [ ("name", Encode.string newProject.name)
                , ("owner", Encode.string newProject.owner)
                ]


-- UPDATE


type Msg
    = ProjectNameEdit String
    | OwnerNameEdit String
    | GetProjects (Result Http.Error (List Project))
    | EditProject Int
    | SaveEditProject
    | CancelEditProject
    | ProjectNew
    | CancelNewProject
    | ProjectNameNew String
    | SaveNewProject
    | PostNewProject (Result Http.Error ())
    | PostEditProject (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
       case msg of
            ProjectNew ->
                       ( { model | newMode = True }, Cmd.none )


            EditProject id ->
                 ( { model | editMode = True, editProject = id }, Cmd.none )

            ProjectNameEdit projectName ->
                          ( { model | projectNameEdit = projectName }, Cmd.none )

            OwnerNameEdit ownerName ->
                           ( { model | ownerNameEdit = ownerName }, Cmd.none )

            SaveEditProject ->
                 ( model, postEditProject model )

            CancelEditProject ->
                 ( { model | editMode = False, projectNameEdit = "", ownerNameEdit = "" }, Cmd.none )


            CancelNewProject ->
                 ( { model | newMode = False, projectNameNew = "" }, Cmd.none )

            SaveNewProject ->
                 ( model, postNewProject { name = model.projectNameNew, owner = "FooBar" } )

            ProjectNameNew p ->
                 ( { model | projectNameNew = p }, Cmd.none )

            PostNewProject _ ->
                 ( { model | projectNameNew = "", newMode = False }, Cmd.none )

            PostEditProject _ ->
                 ( { model | editMode = False, projectNameEdit = "", ownerNameEdit = "" }, Cmd.none )

            GetProjects result ->
                case result of
                    Ok projects ->
                        ( { model | projects = projects }, Cmd.none )

                    Err _ ->
                        ( model, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
     div []
         [ button [ onClick ProjectNew ] [ text "+" ]
         , newProjectView model
         , projectsView model
         ]


newProjectView : Model -> Html Msg
newProjectView model =
               div []
                   [ input [ value model.projectNameNew, onInput ProjectNameNew ] []
                   , button [ onClick SaveNewProject ] [ text "Save" ]
                   , button [ onClick CancelNewProject ] [ text "Cancel" ]
                   ]


projectsView : Model -> Html Msg
projectsView model =
    div []
        (List.map
            (\project -> (projectView project model))
            model.projects
        )
                

projectView : Project -> Model -> Html Msg
projectView project model =
            if model.editMode && model.editProject == project.id then
               div []
                   [ input [ value model.projectNameEdit, onInput ProjectNameEdit ] []
                   , input [ value model.ownerNameEdit, onInput OwnerNameEdit ] []
                   , button [ onClick SaveEditProject ] [ text "Save" ]
                   , button [ onClick CancelEditProject ] [ text "Cancel" ]
                   ]
            else
                div []
                    [ text project.name
                    , text project.owner
                    , button [ onClick <| EditProject project.id ] []
                    ]
