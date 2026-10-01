# Evidence contract

Use the package's DATA_AND_TIMING_MODEL, EDITING_API and ACCEPTANCE_TESTS as task-specific references. Load only relevant sections.

For each criterion record the implementation path, test or review method, exact executed command, fixture/config hash, code/tree fingerprint, result, artifact path, environment and reviewer findings. Distinguish not implemented, implemented, contract tested, live tested, blocked and deferred.

For media changes, decode real output and inspect independent known event timing, geometry, selected audio, overlays, captions and color as applicable. Compare source hashes before and after. A correct plan is not evidence of a correct render.

For providers, use mocks for malformed outputs, timeouts and capability contracts; separately execute a credentialed live smoke test before claiming live support. For GPU paths, record the real device and successful encode. Missing hardware or credentials remains an explicit gap.

Use staged fast/integration/release checks. Avoid no-op verification and reentrant infinite hooks. Invalidate results after relevant source/schema/test changes. Preserve a deliberately failing regression to prove the gate can fail.
