import Cocoa
import FlutterMacOS

private final class WaydirWindowState {
  static var window: NSWindow?
}

private func windowOnMain(_ body: @escaping (NSWindow) -> Void) {
  let run = {
    guard let window = WaydirWindowState.window else { return }
    body(window)
  }
  if Thread.isMainThread {
    run()
  } else {
    DispatchQueue.main.async(execute: run)
  }
}

private func windowResultOnMain<T>(_ fallback: T, _ body: @escaping (NSWindow) -> T) -> T {
  let run = {
    guard let window = WaydirWindowState.window else { return fallback }
    return body(window)
  }
  if Thread.isMainThread {
    return run()
  }
  return DispatchQueue.main.sync(execute: run)
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = false
    self.toolbar = nil
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    WaydirWindowState.window = self

    RegisterGeneratedPlugins(registry: flutterViewController)
    SystemScale.shared.register(controller: flutterViewController, window: self)

    super.awakeFromNib()
  }
}

@_cdecl("waydir_window_set_min_size")
public func waydir_window_set_min_size(_ width: Int32, _ height: Int32) {
  windowOnMain {
    $0.minSize = NSSize(width: CGFloat(width), height: CGFloat(height))
  }
}

@_cdecl("waydir_window_show")
public func waydir_window_show() {
  windowOnMain {
    $0.makeKeyAndOrderFront(nil)
  }
}

@_cdecl("waydir_window_hide")
public func waydir_window_hide() {
  windowOnMain {
    $0.orderOut(nil)
  }
}

@_cdecl("waydir_window_minimize")
public func waydir_window_minimize() {
  windowOnMain {
    $0.miniaturize(nil)
  }
}

@_cdecl("waydir_window_maximize")
public func waydir_window_maximize() {
  windowOnMain {
    if !$0.isZoomed {
      $0.zoom(nil)
    }
  }
}

@_cdecl("waydir_window_restore")
public func waydir_window_restore() {
  windowOnMain {
    if $0.isMiniaturized {
      $0.deminiaturize(nil)
    }
    if $0.isZoomed {
      $0.zoom(nil)
    }
  }
}

@_cdecl("waydir_window_close")
public func waydir_window_close() {
  windowOnMain {
    $0.performClose(nil)
  }
}

@_cdecl("waydir_window_start_dragging")
public func waydir_window_start_dragging() {
  windowOnMain {
    guard let event = NSApp.currentEvent else { return }
    $0.performDrag(with: event)
  }
}

@_cdecl("waydir_window_center")
public func waydir_window_center() {
  windowOnMain {
    $0.center()
  }
}

@_cdecl("waydir_window_is_maximized")
public func waydir_window_is_maximized() -> Int32 {
  windowResultOnMain(0) {
    $0.isZoomed ? 1 : 0
  }
}

@_cdecl("waydir_window_is_visible")
public func waydir_window_is_visible() -> Int32 {
  windowResultOnMain(0) {
    $0.isVisible ? 1 : 0
  }
}

@_cdecl("waydir_window_set_size")
public func waydir_window_set_size(_ width: Int32, _ height: Int32) {
  windowOnMain {
    var frame = $0.frame
    let top = frame.maxY
    frame.size = NSSize(width: CGFloat(width), height: CGFloat(height))
    frame.origin.y = top - frame.height
    $0.setFrame(frame, display: true)
  }
}

@_cdecl("waydir_window_get_size")
public func waydir_window_get_size(
  _ width: UnsafeMutablePointer<Int32>?,
  _ height: UnsafeMutablePointer<Int32>?
) {
  let size = windowResultOnMain(NSSize(width: 0, height: 0)) {
    $0.frame.size
  }
  width?.pointee = Int32(size.width)
  height?.pointee = Int32(size.height)
}

@_cdecl("waydir_window_set_title")
public func waydir_window_set_title(_ title: UnsafePointer<CChar>?) {
  guard let title else { return }
  let value = String(cString: title)
  windowOnMain {
    $0.title = value
  }
}
