require "bundler/setup"
require "potato_lang"
require "language_server/protocol"
require "json"

include LanguageServer::Protocol

reader = $stdin
writer = $stdout

$documents = {}
$latest = {}
queue = Queue.new
$shutdown = false

Thread.new do
  loop do
    uri = queue.pop
    text = $latest[uri]
    next unless text

    diagnostics = run_diagnostics(text)
    send_diagnostics(writer, uri, diagnostics)
  end
end

def write_message(writer, msg)
  json = JSON.dump(msg)
  writer.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
  writer.flush
end

def send_response(writer, id, result)
  write_message(writer, { jsonrpc: "2.0", id: id, result: result })
end

def send_diagnostics(writer, uri, diagnostics)
  write_message(writer, {
    jsonrpc: "2.0",
    method: "textDocument/publishDiagnostics",
    params: { uri: uri, diagnostics: diagnostics }
  })
end

def run_diagnostics(text)
  diagnostics = []

  begin
    ast = Potato::Parser.parse(text)
    Potato::ScopeTree.build(ast)
  rescue => e
    line = e.message =~ /L(\d+)/ ? $1.to_i : nil
    return [] unless line

    msg = e.message.gsub(/\e\[\d+m/, "")
    return [] unless msg

    diagnostics << {
      range: {
        start: { line: line - 1, character: 0 },
        end: { line: line - 1, character: 400 }
      },
      severity: 1,
      message: msg,
      source: "potato"
    }
  end

  diagnostics
end

def read_message(reader)
  headers = {}

  while (line = reader.gets)
    line = line.strip
    break if line.empty?
    key, value = line.split(":", 2)
    headers[key] = value.strip if key && value
  end

  length = headers["Content-Length"]&.to_i
  return nil unless length

  body = reader.read(length)
  JSON.parse(body)
end

loop do
  break if $shutdown

  request = read_message(reader)
  break unless request

  case request["method"]
  when "initialize"
    send_response(writer, request["id"], {
      capabilities: {
        textDocumentSync: {
          openClose: true,
          change: 1
        },
        documentFormattingProvider: true
      }
    })

  when "shutdown"
    send_response(writer, request["id"], nil)
    $shutdown = true

  when "exit"
    exit(0)

  when "textDocument/didOpen", "textDocument/didChange"
    uri = request.dig("params", "textDocument", "uri")
    text =
      request.dig("params", "textDocument", "text") ||
      request.dig("params", "contentChanges", -1, "text") ||
      ""

    $documents[uri] = text
    $latest[uri] = text
    queue << uri

  when "textDocument/formatting"
    uri = request.dig("params", "textDocument", "uri")
    text = $documents[uri] || ""

    formatted = text
      .gsub(/ {2,}/, " ")
      .gsub(/,(?=[^\s])/, ", ")

    send_response(writer, request["id"], [{
      range: {
        start: { line: 0, character: 0 },
        end: { line: text.lines.count, character: 0 }
      },
      newText: formatted
    }])
  end
end