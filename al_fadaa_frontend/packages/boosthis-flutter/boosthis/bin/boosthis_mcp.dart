#!/usr/bin/env dart
// boosthis_mcp runs the Boosthis Flutter kit as a local stdio MCP server: it
// speaks newline-delimited JSON-RPC 2.0 over stdin/stdout so an AI editor
// (Replit AI, Cursor, Claude, …) can browse the Flutter performance rule book,
// match rules against code, and read this project's recorded perf samples — the
// Flutter sibling of lib/boosthis-php/bin/boosthis-mcp,
// lib/boosthis-go/cmd/boosthis-mcp, `java app.boosthis.Mcp`, and
// lib/boosthis-ruby/bin/boosthis-mcp.
//
// It opens no network listener; the only outbound bytes are the fire-and-forget,
// PII-guarded rule proposal from the report_unmatched_pattern tool.
//
// NOTE: this entrypoint is PLAIN DART (dart:io), so it runs with the standalone
// `dart` VM without a Flutter SDK — an AI editor can launch it from any checkout.
// The kit's on-device meters need the Flutter engine, but the rule book and the
// recorded-sample tools do not, so the MCP server is fully useful here.
//
// Usage: register this binary as an MCP server in your editor's MCP config, e.g.
//
//   {
//     "mcpServers": {
//       "boosthis": { "command": "dart", "args": ["run", "boosthis:boosthis_mcp"] }
//     }
//   }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../lib/src/mcp/mcp.dart';

Future<void> main(List<String> args) async {
  // stdio MCP servers must keep stdout clean: no stray warnings, prompts, or
  // output may reach the JSON-RPC pipe. Decode stdin as UTF-8 line-by-line and
  // write UTF-8 lines back, flushing each intact.
  final lines = stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();
  final iterator = StreamIterator<String>(lines);

  await Mcp.run(
    () async {
      final has = await iterator.moveNext();
      return has ? iterator.current : null;
    },
    (String out) {
      stdout.write(out);
    },
  );
}
