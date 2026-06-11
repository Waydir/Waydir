import AppKit

private let waydirClipboardModeType = NSPasteboard.PasteboardType("org.waydir.clipboard-mode")

@_cdecl("waydir_clipboard_write_files")
public func waydir_clipboard_write_files(_ joined: UnsafePointer<CChar>?, _ isCut: Int32) {
  guard let joined else { return }
  let raw = String(cString: joined)
  let urls = raw
    .split(separator: "\n", omittingEmptySubsequences: true)
    .map { URL(fileURLWithPath: String($0)) }

  let pb = NSPasteboard.general
  pb.clearContents()
  if !urls.isEmpty {
    pb.writeObjects(urls as [NSURL])
  }
  pb.setString(isCut != 0 ? "cut" : "copy", forType: waydirClipboardModeType)
}

@_cdecl("waydir_clipboard_read_files")
public func waydir_clipboard_read_files() -> UnsafeMutablePointer<CChar>? {
  let pb = NSPasteboard.general
  let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
  let objects = pb.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
  let joined = objects.map { $0.path }.joined(separator: "\n")
  return strdup(joined)
}

@_cdecl("waydir_clipboard_is_cut")
public func waydir_clipboard_is_cut() -> Int32 {
  let pb = NSPasteboard.general
  return pb.string(forType: waydirClipboardModeType) == "cut" ? 1 : 0
}

@_cdecl("waydir_clipboard_free")
public func waydir_clipboard_free(_ ptr: UnsafeMutablePointer<CChar>?) {
  free(ptr)
}
