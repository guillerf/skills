import Foundation
import AppKit
import Security

let email = "guillermo.ruiz@crisalix.com"
let expectedName = "Guillermo Ruiz"
let service = "com.crisalix.codex.jira.82b5fe1b-d904-46bb-a485-32f01e7ea2d7"
let base = "https://api.atlassian.com/ex/jira/82b5fe1b-d904-46bb-a485-32f01e7ea2d7/rest/api/3"
typealias Object = [String: Any]
struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) { description = message }
}
func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw Failure(message) }
}
func emit(_ object: Object) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    print(String(decoding: data, as: UTF8.self))
}
func keychainQuery() -> Object {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service, kSecAttrAccount as String: email,
     kSecAttrSynchronizable as String: false]
}
func loadToken() throws -> String {
    var query = keychainQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    try require(status == errSecSuccess, "Token local no disponible (llavero \(status)). Ejecuta jira setup; no pegues el token en el chat.")
    guard let data = result as? Data, let token = String(data: data, encoding: .utf8), !token.isEmpty else {
        throw Failure("La entrada del llavero no contiene un token válido.")
    }
    return token
}
func saveToken(_ token: String) throws {
    let query = keychainQuery()
    let update = [kSecValueData as String: Data(token.utf8)] as CFDictionary
    var status = SecItemUpdate(query as CFDictionary, update)
    if status == errSecItemNotFound {
        var item = query
        item[kSecValueData as String] = Data(token.utf8)
        item[kSecAttrLabel as String] = "Crisalix Jira — Codex — Guillermo Ruiz"
        status = SecItemAdd(item as CFDictionary, nil)
    }
    try require(status == errSecSuccess, "No se pudo guardar en el llavero (\(status)).")
}

// Never follow redirects with credentials, and never persist URL caches/cookies.
final class NoRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}
final class ResponseBox: @unchecked Sendable {
    var data: Data?; var response: URLResponse?; var error: Error?
}
typealias Transport = (String, String, Object?) throws -> Object
func network(_ token: String) -> Transport {
    let credential = Data("\(email):\(token)".utf8).base64EncodedString()
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 45
    let session = URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
    return { method, path, body in
        try require(path.hasPrefix("/") && !path.contains("..") && !path.contains("#"), "Ruta no válida.")
        guard let url = URL(string: base + path), url.host == "api.atlassian.com" else { throw Failure("Host no permitido.") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Basic " + credential, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let result = ResponseBox()
        let done = DispatchSemaphore(value: 0)
        session.dataTask(with: request) { data, response, error in
            result.data = data; result.response = response; result.error = error; done.signal()
        }.resume()
        done.wait()
        if result.error != nil {
            throw Failure("Error de transporte. Si ocurrió durante POST /issue, el resultado es incierto: no reintentes automáticamente; busca primero la card.")
        }
        guard let response = result.response as? HTTPURLResponse else { throw Failure("Respuesta HTTP ausente.") }
        guard (200..<300).contains(response.statusCode) else {
            var detail = ""
            if let data = result.data, let object = (try? JSONSerialization.jsonObject(with: data)) as? Object {
                let errors = ["errors": object["errors"] ?? [:], "errorMessages": object["errorMessages"] ?? []]
                if let bytes = try? JSONSerialization.data(withJSONObject: errors), let text = String(data: bytes, encoding: .utf8) {
                    detail = " " + text.replacingOccurrences(of: token, with: "[REDACTED]").replacingOccurrences(of: credential, with: "[REDACTED]")
                }
            }
            throw Failure("Jira HTTP \(response.statusCode).\(detail)")
        }
        guard let data = result.data, !data.isEmpty else { return [:] }
        guard let object = try JSONSerialization.jsonObject(with: data) as? Object else { throw Failure("Respuesta JSON inesperada.") }
        return object
    }
}
func identity(_ request: Transport) throws -> Object {
    let user = try request("GET", "/myself", nil)
    try require(user["active"] as? Bool == true && user["displayName"] as? String == expectedName,
                "Identidad incorrecta o inactiva en /myself. No se permite escribir en Jira.")
    try require((user["emailAddress"] as? String)?.lowercased() == email,
                "No se pudo confirmar el correo esperado en /myself. No se permite escribir en Jira.")
    try require(!(user["accountId"] as? String ?? "").isEmpty, "Falta accountId en /myself.")
    return user
}
func issueKey(_ value: String) throws -> String {
    try require(value.range(of: "^[A-Z][A-Z0-9]*-[0-9]+$", options: .regularExpression) != nil, "Clave de card no válida.")
    return value
}
func fetchIssue(_ key: String, _ request: Transport) throws -> Object {
    try request("GET", "/issue/\(issueKey(key))?fields=summary,status,creator,reporter", nil)
}
func verifyIssue(_ issue: Object, _ user: Object) throws {
    let fields = issue["fields"] as? Object ?? [:]
    for role in ["creator", "reporter"] {
        let person = fields[role] as? Object ?? [:]
        try require(person["accountId"] as? String == user["accountId"] as? String && person["displayName"] as? String == expectedName,
                    "La card \(issue["key"] ?? "") tiene \(role) distinto de Guillermo Ruiz. Detén las escrituras; no recrees ni borres la card.")
    }
}
func create(_ input: Object, _ request: Transport, created: (String) -> Void) throws -> Object {
    var payload = input
    var fields = payload["fields"] as? Object ?? [:]
    try require(!(fields["summary"] as? String ?? "").isEmpty, "Falta summary.")
    try require((fields["description"] as? Object)?["type"] as? String == "doc", "description debe ser ADF.")
    try require(fields["creator"] == nil, "creator lo establece Jira.")
    let user = try identity(request)
    if let reporter = fields["reporter"] as? Object {
        try require(reporter["accountId"] as? String == user["accountId"] as? String, "reporter debe ser Guillermo Ruiz.")
    }
    fields["reporter"] = ["accountId": user["accountId"]!]
    payload["fields"] = fields
    let response = try request("POST", "/issue", payload)
    guard let key = response["key"] as? String else { throw Failure("POST /issue respondió sin clave. No reintentes sin reconciliar.") }
    created(key) // Print the key before read-back so a verification failure cannot hide a created card.
    let issue = try fetchIssue(key, request)
    try verifyIssue(issue, user)
    return issue
}
func transition(_ key: String, _ target: String, _ request: Transport) throws -> Object {
    let ids = ["To Do": "11", "Backlog": "111"]
    guard let id = ids[target] else { throw Failure("Estado permitido: To Do o Backlog.") }
    let user = try identity(request)
    let before = try fetchIssue(key, request)
    try verifyIssue(before, user)
    if ((before["fields"] as? Object)?["status"] as? Object)?["name"] as? String != target {
        _ = try request("POST", "/issue/\(issueKey(key))/transitions", ["transition": ["id": id]])
    }
    let after = try fetchIssue(key, request)
    try verifyIssue(after, user)
    try require(((after["fields"] as? Object)?["status"] as? Object)?["name"] as? String == target,
                "El estado final no coincide; no repitas la transición automáticamente.")
    return after
}
func promptAndSave() throws {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    app.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Token Jira para este Mac"
    alert.informativeText = "Cuenta: \(email)\nPega aquí tu API token nuevo. Se verificará /myself y se guardará en el llavero local. No se creará ninguna card. No lo pegues en Codex."
    alert.addButton(withTitle: "Verificar y guardar")
    alert.addButton(withTitle: "Cancelar")
    let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 440, height: 26))
    input.placeholderString = "API token de Atlassian"
    alert.accessoryView = input
    alert.window.initialFirstResponder = input
    try require(alert.runModal() == .alertFirstButtonReturn, "Configuración cancelada; no se guardó ningún token.")
    let token = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    input.stringValue = ""
    try require(!token.isEmpty, "Token vacío.")
    let user = try identity(network(token))
    try saveToken(token)
    try emit(["configured": true, "displayName": user["displayName"]!, "emailAddress": email,
              "accountId": user["accountId"]!, "storage": "macOS Keychain (local, no sync)"])
    let success = NSAlert()
    success.messageText = "Jira configurado"
    success.informativeText = "Identidad verificada: Guillermo Ruiz. Token guardado en el llavero. No se ha creado ninguna card."
    success.addButton(withTitle: "Aceptar")
    success.runModal()
}

func selfTest() throws {
    let user: Object = ["active": true, "displayName": expectedName, "emailAddress": email, "accountId": "guillermo-test"]
    let issue: Object = ["key": "CORE-123", "fields": ["summary": "mock", "status": ["name": "Backlog"], "creator": user, "reporter": user]]
    let input: Object = ["fields": ["summary": "mock", "description": ["type": "doc", "version": 1, "content": []]]]
    var calls: [String] = []
    let mock: Transport = { method, path, body in
        calls.append(method + " " + path)
        if path == "/myself" { return user }
        if method == "POST" {
            try require(((body?["fields"] as? Object)?["reporter"] as? Object)?["accountId"] as? String == "guillermo-test", "Reporter injection failed")
            return ["key": "CORE-123"]
        }
        return issue
    }
    _ = try create(input, mock, created: { _ in })
    try require(calls == ["GET /myself", "POST /issue", "GET /issue/CORE-123?fields=summary,status,creator,reporter"], "Unexpected request order")
    var writes = 0
    let wrongIdentity: Transport = { method, _, _ in
        if method == "POST" { writes += 1 }
        var wrong = user; wrong["displayName"] = "Pere Calopa"; return wrong
    }
    var rejected = false
    do { _ = try create(input, wrongIdentity, created: { _ in }) } catch { rejected = true }
    try require(rejected && writes == 0, "Wrong identity must stop writes")
    var mismatch = issue
    var fields = issue["fields"] as! Object
    fields["reporter"] = ["displayName": "Pere Calopa", "accountId": "pere-test"]
    mismatch["fields"] = fields
    rejected = false
    do { try verifyIssue(mismatch, user) } catch { rejected = true }
    try require(rejected, "Wrong reporter accepted")
    fields["reporter"] = user; fields["creator"] = ["displayName": expectedName, "accountId": "other-test"]
    mismatch["fields"] = fields
    rejected = false
    do { try verifyIssue(mismatch, user) } catch { rejected = true }
    try require(rejected, "Wrong creator accountId accepted")
    var transitioned = false
    calls = []
    let transitionMock: Transport = { method, path, body in
        calls.append(method + " " + path)
        if path == "/myself" { return user }
        if method == "POST" {
            try require((body?["transition"] as? Object)?["id"] as? String == "11", "Wrong transition ID")
            transitioned = true
            return [:]
        }
        var current = issue
        var currentFields = issue["fields"] as! Object
        currentFields["status"] = ["name": transitioned ? "To Do" : "Backlog"]
        current["fields"] = currentFields
        return current
    }
    _ = try transition("CORE-123", "To Do", transitionMock)
    try require(calls == ["GET /myself", "GET /issue/CORE-123?fields=summary,status,creator,reporter",
                          "POST /issue/CORE-123/transitions", "GET /issue/CORE-123?fields=summary,status,creator,reporter"],
                "Transition identity/read/write/read order failed")
    writes = 0
    let badReporter: Transport = { method, path, _ in
        if method == "POST" { writes += 1 }
        if path == "/myself" { return user }
        return mismatch
    }
    rejected = false
    do { _ = try transition("CORE-123", "To Do", badReporter) } catch { rejected = true }
    try require(rejected && writes == 0, "Transition must stop on issue identity mismatch")
    print("Self-test OK: create/transition request order, reporter injection, identity guards, creator/reporter mismatches. No network or keychain calls.")
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else { throw Failure("Uso: jira setup | check | create payload.json | read KEY | transition KEY 'To Do' | get /ruta | self-test") }
    if command == "setup" { try promptAndSave() }
    else if command == "self-test" { try selfTest() }
    else {
        let request = network(try loadToken())
        switch command {
        case "check": try emit(try identity(request))
        case "create":
            try require(args.count == 2, "create requiere un archivo JSON.")
            let data = try Data(contentsOf: URL(fileURLWithPath: args[1]))
            guard let payload = try JSONSerialization.jsonObject(with: data) as? Object else { throw Failure("Payload inválido.") }
            try emit(try create(payload, request, created: { key in print("Created: \(key) https://crisalix.atlassian.net/browse/\(key)"); fflush(stdout) }))
        case "read":
            try require(args.count == 2, "read requiere una clave.")
            let user = try identity(request)
            let issue = try fetchIssue(args[1], request)
            try verifyIssue(issue, user)
            try emit(issue)
        case "transition":
            try require(args.count == 3, "transition requiere clave y estado.")
            try emit(try transition(args[1], args[2], request))
        case "get":
            try require(args.count == 2, "get requiere una ruta REST relativa.")
            _ = try identity(request)
            try emit(try request("GET", args[1], nil))
        default: throw Failure("Comando desconocido.")
        }
    }
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
