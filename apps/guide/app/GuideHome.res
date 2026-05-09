let navigateToDocsIntro = url => window.location->WebAPI.Location.assign(url)

@react.component
let make = (
  ~lessons: array<GuideLesson.t>,
  ~compilerData: option<GuideCompilerData.t>=?,
  ~goToDocsIntro=navigateToDocsIntro,
) => {
  let layout = GuideLayoutHook.useLayout()
  let navigation = GuideLessonNavigationHook.useLessonNavigation(~lessons, ~goToDocsIntro)
  let lesson = navigation.lesson
  let exercise = lesson.exercise
  let editor = GuideEditorHook.useEditor(~exercise, ~theme=layout.theme)

  <>
    <div className="guide-screen-size-message">
      <h1> {React.string("This guide needs a wider screen.")} </h1>
      <p> {React.string("Use a desktop browser or resize this window to continue.")} </p>
    </div>
    <main
      className={"guide-shell " ++ layout.theme->GuideLayout.themeClass}
      dataTestId="guide-mvp"
      ref={ReactDOM.Ref.domRef(layout.shellRef)}
    >
      <section className="guide-instructions" ariaLabel="Guide instructions">
        <div className="guide-copy">
          <div className="guide-topbar">
            <p className="guide-kicker"> {React.string(lesson.missionLabel)} </p>
            <button
              ariaLabel={layout.theme->GuideLayout.themeToggleLabel}
              className="guide-theme-toggle"
              onClick={layout.toggleTheme}
              title={layout.theme->GuideLayout.themeToggleLabel}
              type_="button"
            >
              {React.string(layout.theme->GuideLayout.themeToggleText)}
            </button>
          </div>
          <h1> {React.string(lesson.title)} </h1>
          <GuideMarkdown> lesson.content </GuideMarkdown>
          <div
            className={"guide-check-status " ++ if navigation.checkpointComplete {
              "guide-check-status-complete"
            } else {
              "guide-check-status-pending"
            }}
            dataTestId="guide-check-status"
          >
            <span className="guide-check-label"> {React.string("Checkpoint")} </span>
            <span>
              {React.string(
                if navigation.checkpointComplete {
                  "Checkpoint complete"
                } else {
                  "Waiting for matching output"
                },
              )}
            </span>
          </div>
        </div>
        <div className="guide-lesson-actions">
          <button
            className="guide-back-button"
            disabled={!navigation.hasPreviousLesson}
            onClick={navigation.goToPreviousLesson}
            type_="button"
          >
            {React.string("Back")}
          </button>
          <button
            className="guide-next-button"
            disabled={!navigation.forwardActionEnabled}
            onClick={navigation.goToNextLesson}
            type_="button"
          >
            {React.string(
              if navigation.hasNextLesson {
                "Next"
              } else {
                "Done"
              },
            )}
          </button>
        </div>
      </section>
      <div
        ariaLabel="Resize instructions pane"
        className="guide-resize-handle guide-resize-handle-columns"
        dataTestId="guide-column-resize"
        onMouseDown={layout.startColumnResize}
        role="separator"
      />
      <section className="guide-workspace" ariaLabel="Guide workspace">
        <div className="guide-editor-panel">
          <div className="guide-label"> {React.string("Editor")} </div>
          <div
            ariaLabel="Guide code"
            className="guide-editor"
            dataTestId="guide-code-editor"
            ref={ReactDOM.Ref.domRef(editor.containerRef)}
            role="textbox"
          />
        </div>
        <div
          ariaLabel="Resize output pane"
          className="guide-resize-handle guide-resize-handle-rows"
          dataTestId="guide-row-resize"
          onMouseDown={layout.startRowResize}
          role="separator"
        />
        <div className="guide-output-panel">
          <div className="guide-label"> {React.string("Output")} </div>
          <div className="guide-output-frame" dataTestId="guide-output">
            <GuideOutputPanel output={navigation.output} />
          </div>
        </div>
      </section>
      {switch compilerData {
      | Some({bundleBaseUrl, versions}) =>
        <GuideCompilerBridge
          bundleBaseUrl
          versions
          code=editor.code
          editorRef=editor.editorRef
          setOutput={navigation.setOutput}
        />
      | None => React.null
      }}
    </main>
  </>
}
