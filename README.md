# llfw: Low Level Firewall

This tool adds rules to the macOS `pf` firewall. The `pf` firewall has no UI other than `pfctl` so it works well for fleet-wide low-level security purposes.

Rules are embedded in the file Sources/llfw/Ruleset.swift

* `engage` - if `llfw` isn't disabled, will create or overwrite the rule file and load it into `pf`. It will also retain `pf` and store the token value at `/Library/Application Support/llfw/pfReferenceToken`
* `disable` will unload these rules, release our claim on `pf` if we had one, and create a touchfile that deactivates future `enagage` commands. The touchfile is `/Library/Application Support/llfw/doNotLoadLLFWRules`
* `enable` removes the touchfile `/Library/Application Support/llfw/doNotLoadLLFWRules`
