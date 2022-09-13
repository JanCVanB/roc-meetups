app "elm_book_mimic"
    packages { pf: "../roc/examples/interactive/cli-platform/main.roc" }
    imports [pf.Stdout, pf.Stderr, pf.Task, pf.File, pf.Path]
    provides [main] to pf

main =
    templateFile = Path.fromStr "template.txt"
    contentFile = Path.fromStr "content.txt"
    renderFile = Path.fromStr "render.txt"
    task =
        template <- File.readUtf8 templateFile |> Task.await
        content <- File.readUtf8 contentFile |> Task.await
        { before, after } =
            Str.splitFirst template "content goes here!\n"
                |> Result.withDefault { before: template, after: "" }
        render = "\(before)\(content)\(after)"
        File.writeUtf8 renderFile render

    Task.attempt task \result ->
        when result is
            Err (FileWriteErr _ PermissionDenied) -> Stderr.line "Err: PermissionDenied"
            Err (FileWriteErr _ Unsupported) -> Stderr.line "Err: Unsupported"
            Err (FileWriteErr _ (Unrecognized _ other)) -> Stderr.line "Err: \(other)"
            Err (FileReadErr _ _) -> Stderr.line "Error reading file"
            Err _ -> Stderr.line "Uh oh, there was an error!"
            Ok _ -> Stdout.line "Successfully rendered!"
