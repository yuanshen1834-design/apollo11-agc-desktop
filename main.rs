//! Apollo 11 AGC 桌面版 —— WebView2 套壳
//! 核心代码和素材原样加载（不做任何修改），通过本地 HTTP 服务提供静态文件。
//! 引擎：wry（WebView2）+ tao（窗口）
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::io::{Read, Write};
use std::net::TcpListener;
use std::path::PathBuf;
use std::thread;

use tao::event::{Event, WindowEvent};
use tao::event_loop::{ControlFlow, EventLoop};
use tao::window::WindowBuilder;
use wry::WebViewBuilder;

fn content_type(path: &str) -> &'static str {
    if path.ends_with(".html") || path.ends_with(".htm") {
        "text/html; charset=utf-8"
    } else if path.ends_with(".js") {
        "application/javascript; charset=utf-8"
    } else if path.ends_with(".css") {
        "text/css; charset=utf-8"
    } else if path.ends_with(".json") {
        "application/json"
    } else if path.ends_with(".png") {
        "image/png"
    } else if path.ends_with(".jpg") || path.ends_with(".jpeg") {
        "image/jpeg"
    } else if path.ends_with(".gif") {
        "image/gif"
    } else if path.ends_with(".svg") {
        "image/svg+xml"
    } else if path.ends_with(".woff2") {
        "font/woff2"
    } else if path.ends_with(".wasm") {
        "application/wasm"
    } else {
        "application/octet-stream"
    }
}

/// 简易静态文件 HTTP 服务（127.0.0.1 随机端口）
fn start_server(root: PathBuf) -> u16 {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind failed");
    let port = listener.local_addr().unwrap().port();
    thread::spawn(move || {
        for stream in listener.incoming() {
            let Ok(mut stream) = stream else { continue };
            let root = root.clone();
            thread::spawn(move || {
                let mut buf = [0u8; 8192];
                let n = match stream.read(&mut buf) {
                    Ok(n) => n,
                    Err(_) => return,
                };
                let req = String::from_utf8_lossy(&buf[..n]);
                let mut lines = req.lines();
                let first = lines.next().unwrap_or("");
                let mut parts = first.split_whitespace();
                let _method = parts.next().unwrap_or("GET");
                let raw_path = parts.next().unwrap_or("/");
                // 去掉 query
                let path_only = raw_path.split('?').next().unwrap_or("/");
                // 解码 %xx
                let decoded = url_decode(path_only);
                let rel = if decoded == "/" || decoded.is_empty() {
                    "index.html".to_string()
                } else {
                    decoded.trim_start_matches('/').to_string()
                };
                // 防目录穿越
                if rel.contains("..") {
                    let _ = stream.write_all(b"HTTP/1.1 403 Forbidden\r\n\r\n");
                    return;
                }
                let file_path = root.join(&rel);
                match std::fs::read(&file_path) {
                    Ok(data) => {
                        let ct = content_type(&rel);
                        let header = format!(
                            "HTTP/1.1 200 OK\r\nContent-Type: {}\r\nContent-Length: {}\r\nCache-Control: no-cache\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n",
                            ct,
                            data.len()
                        );
                        let _ = stream.write_all(header.as_bytes());
                        let _ = stream.write_all(&data);
                    }
                    Err(_) => {
                        // 404：尝试 index.html（游戏是 SPA 结构时兜底）
                        let fallback = root.join("index.html");
                        if file_path != fallback {
                            if let Ok(data) = std::fs::read(&fallback) {
                                let header = format!(
                                    "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                                    data.len()
                                );
                                let _ = stream.write_all(header.as_bytes());
                                let _ = stream.write_all(&data);
                                return;
                            }
                        }
                        let _ = stream.write_all(b"HTTP/1.1 404 Not Found\r\n\r\n");
                    }
                }
            });
        }
    });
    port
}

fn url_decode(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(v) = u8::from_str_radix(
                std::str::from_utf8(&bytes[i + 1..i + 3]).unwrap_or("00"),
                16,
            ) {
                out.push(v);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// 资源目录：exe 同目录的 web/ 子目录
fn web_root() -> PathBuf {
    std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|d| d.join("web")))
        .filter(|p| p.exists())
        .unwrap_or_else(|| PathBuf::from("web"))
}

fn main() {
    let root = web_root();
    let port = start_server(root);
    let url = format!("http://127.0.0.1:{}/index.html", port);

    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("Apollo 11 AGC — 阿波罗11号制导计算机模拟")
        .with_inner_size(tao::dpi::LogicalSize::new(1440.0, 900.0))
        .with_min_inner_size(tao::dpi::LogicalSize::new(1024.0, 640.0))
        .build(&event_loop)
        .expect("window failed");

    let _webview = WebViewBuilder::new()
        .with_url(&url)
        .with_devtools(true)
        .build(&window)
        .expect("webview failed");

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;
        if let Event::WindowEvent {
            event: WindowEvent::CloseRequested,
            ..
        } = event
        {
            *control_flow = ControlFlow::Exit;
        }
    });
}
