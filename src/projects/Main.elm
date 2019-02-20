import Browser

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
    ( (Model "", "", "", False, [], 0, False) , getProjects )


getProjects : Cmd Msg
getProjects =
    Http.get
        { url = "/projects"
        , expect = Http.expectJson GetProjects projectsDecoder
        }


postNewProject : Project -> Cmd Msg
postNewProject project =
    Http.post
        { url = "/new/project/"
        , body = Http.jsonBody projectEncoder project
        , expect = Http.expectWhatever PostNewProject
        }


postEditProject : Project -> Cmd Msg
postEditProject project =
    Http.post
        { url = "/edit/project/"
        , body = Http.jsonBody projectEncoder project
        , expect = Http.expectWhatever PostEditProject
        }
        
projectsDecoder : Decode.Decoder List Project
projectsDecoder =
    Decode.list projectDecoder


projectDecoder : Decode.Decoder Project
projectDecoder =
    Decode.map3 Project
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "owner" Decode.string)


-- UPDATE


type Msg
    = ProjectNameEdit String
    | OwnerNameEdit String
    | GetProjects (Result Http.Error (List Project))
    | EditProject Int
    | SaveEditProject
    | CancelEditProject
    | NewProject
    | CancelNewProject
    | ProjectNameNew
    | SaveNewProject
    | PostNewProject (Result Http.Error ())
    | PostEditProject (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
       case msg of
            NewProject ->
                       ( { model | newMode = True }, Cmd.none )


            EditProject id ->
                 ( { model | editMode = True, editProject = id }, Cmd.none )

            ProjectNameEdit projectName ->
                          ( { model | projectNameEdit = projectName }, Cmd.none )

            OwnerNameEdit ownerName ->
                           ( { model | ownerNameEdit = ownerName, Cmd.none )

            SaveEditProject ->
                 ( model, postEditProject )

            CancelEditProject ->
                 ( { model | editMode = False, projectNameEdit = "", ownerNameEdit = "" } )

            NewProject ->
                 ( { model | newMode = True }, Cmd.none )

            CancelNewProject ->
                 ( { model | newMode = False, projectNameNew = "" }, Cmd.none )

            SaveNewProject ->
                 ( model, postNewProject model )

            ProjectNameNew p ->
                 ( { model | projectNameNew = p, Cmd.none } )

            PostNewProject _ ->
                 ( { model | projectNameNew = "", newMode = False }, Cmd.none )

            PostEditProject _ ->
                 ( { model | editMode = False, projectNameEdit = "", ownerNameEdit = "" }, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
     div []
         [ button [ onClick NewProject ]
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
             let
                context = \project -> projectView project model
             in
                div []
                    List.map context model.projects
                

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
