fn main() {
    // 仅当目标平台是 Windows 时嵌入图标与版本资源（WSL 交叉编译也可用）
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        let out_dir = std::env::var("OUT_DIR").unwrap();
        let res_path = format!("{out_dir}/app_rc.o");
        let windres = std::env::var("WINDRES")
            .unwrap_or_else(|_| "x86_64-w64-mingw32-windres".to_string());
        let status = std::process::Command::new(&windres)
            .args(["-i", "app.rc", "-o", &res_path, "--codepage=65001"])
            .status();
        match status {
            Ok(s) if s.success() => {
                println!("cargo:rustc-link-arg={res_path}");
                println!("cargo:rerun-if-changed=app.rc");
                println!("cargo:rerun-if-changed=app.ico");
            }
            _ => {
                println!("cargo:warning=windres 资源编译失败（图标未嵌入）");
            }
        }
    }
}