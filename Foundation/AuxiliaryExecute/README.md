# AuxiliaryExecute

A Swift wrapper for system shell over posix_spawn with search path and env support.

## Usage

```
import AuxiliaryExecute

AuxiliaryExecute.local.bash(command: "echo nya")
```

## Customization & Defaults

The source for this package is well explained in details along with comments. Feel free looking for them.

```
// automatically search for binary within env PATH
let result = AuxiliaryExecute.local.shell(
    command: "bash",
    args: ["-c", "echo $mua"],
    environment: ["mua": "nya"],
    timeout: 0
) { stdout in
    print(stdout)
} stderrBlock: { stderr in
    print(stderr)
}

// or call with binary's full path
func spawn(
    command: String,
    args: [String] = [],
    environment: [String: String] = [:],
    timeout: Double = 0,
    stdoutBlock: ((String) -> Void)? = nil,
    stderrBlock: ((String) -> Void)? = nil
)

// for customize option for shell
func appendSearchPath(with value: String)
func updateExtraSearchPath(with block: (inout [String]) -> Void)
func updateOverwriteTable(with block: (inout [String: String?]) -> Void)
```

## License

AuxiliaryExecute is licensed under [MIT](./LICENSE).

---

Copyright © 2021 Lakr Aream. All Rights Reserved.
