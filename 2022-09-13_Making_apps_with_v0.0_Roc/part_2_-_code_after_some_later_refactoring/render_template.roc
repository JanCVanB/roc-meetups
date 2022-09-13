app "render_template"
    packages { pf: "../roc/examples/interactive/cli-platform/main.roc" }
    imports [pf.File, pf.Path, pf.Stderr, pf.Stdout, pf.Task]
    provides [main] to pf

main = Task.attempt steps handleResult

steps =
    template <- read "./template.txt" |> Task.await
    content <- read "./content.txt" |> Task.await
    { before, after } = split template "content goes here!\n"
    write "./rendered.txt" "\(before)\(content)\(after)"

read = \path -> path |> Path.fromStr |> File.readUtf8
write = \path, text -> path |> Path.fromStr |> File.writeUtf8 text
split = \text, splitPoint ->
    text
        |> Str.splitFirst splitPoint
        |> Result.withDefault { before: text, after: "" }

handleResult = \result ->
    when result is
        Err (FileWriteErr _ PermissionDenied) -> Stderr.line "Error: File write permission denied"
        Err (FileWriteErr _ Unsupported) -> Stderr.line "Error: File write unsupported"
        Err (FileWriteErr _ (Unrecognized _ other)) -> Stderr.line "Error: File write error code: \(other)"
        Err (FileReadErr _ NotFound) -> Stderr.line "Error: Read file not found, are you in the right directory?"
        Err (FileReadErr _ _) -> Stderr.line "Error: An unexpected file reading error occurred"
        Err _ -> Stderr.line "Error: An unexpected error occurred"
        Ok _ -> Stdout.line "Successfully rendered!"
