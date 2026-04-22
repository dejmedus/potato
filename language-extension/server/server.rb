require "bundler/setup"
require "potato_lang"
require "language_server/protocol"

include LanguageServer::Protocol

reader = $stdin
writer = $stdout
$documents = {}
$debounce_threads = {}

def send_response(writer, id, result)
  response = {
    jsonrpc: "2.0",
    id: id,
    result: result
  }

  json = response.to_json
  writer.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
  writer.flush
end

def send_diagnostics(writer, uri, diagnostics)
  message = {
    jsonrpc: "2.0",
    method: "textDocument/publishDiagnostics",
    params: {
      uri: uri,
      diagnostics: diagnostics
    }
  }

  json = message.to_json
  writer.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
  writer.flush
end

def run_diagnostics(text)
  diagnostics = []
  begin
    ast = Potato::Parser.parse(text)
    Potato::ScopeTree.build(ast)
  rescue => e
    line = e.message =~ /L(\d+)/ ? $1.to_i : nil
    return unless line

    msg = e.message.gsub(/\e\[\d+m/, "")
    return unless msg

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

loop do
  header = reader.gets
  next unless header

  if header.start_with?("Content-Length:")
    length = header.split(":").last.to_i
    reader.gets

    body = reader.read(length)
    request = JSON.parse(body)

    case request["method"]
    when "initialize"
      send_response(writer, request["id"], {
        capabilities: {
          textDocumentSync: 1,
          documentFormattingProvider: true
        }
      })

    when "textDocument/didOpen", "textDocument/didChange"
      uri = request["params"]["textDocument"]["uri"]
      text = request["params"]["textDocument"]["text"] ||
             request["params"]["contentChanges"]&.last&.dig("text")
      text ||= ""

      $documents[uri] = text
      $debounce_threads[uri]&.kill
      $debounce_threads[uri] = Thread.new do
        sleep 0.5
        diagnostics = run_diagnostics(text)
        send_diagnostics(writer, uri, diagnostics)
      end
    when "textDocument/formatting"
      uri = request["params"]["textDocument"]["uri"]
      text = $documents[uri]
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
end