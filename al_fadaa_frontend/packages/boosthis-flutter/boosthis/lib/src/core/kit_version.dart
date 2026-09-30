/// The kit's OWN version string.
///
/// This is the single source the hosted MCP compares an install against and
/// the value emitted as `latest_version` / `kitVersion` on the wire. It starts
/// at "0.1.0" for the tenth (Flutter) runtime and is bumped in lock-step with
/// the package version and the changelog — never on its own.
///
/// Named per the contract: `RUNTIME_VERSION`.
// ignore: constant_identifier_names
const String RUNTIME_VERSION = '0.1.66';
