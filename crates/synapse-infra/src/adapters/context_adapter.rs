use async_trait::async_trait;
use synapse_core::ports::{ContextPort, WindowInfo};
use synapse_core::error::Result;


#[cfg(target_os = "windows")]
use windows::Win32::UI::WindowsAndMessaging::{
    GetForegroundWindow, GetWindowTextW, GetWindowThreadProcessId, IsWindowVisible, GetWindowRect,
};
#[cfg(target_os = "windows")]
use windows::Win32::System::ProcessStatus::K32GetModuleBaseNameW;
#[cfg(target_os = "windows")]
use windows::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_INFORMATION, PROCESS_VM_READ};
#[cfg(target_os = "windows")]
use windows::Win32::Foundation::{HWND, RECT};

pub struct WindowsContextAdapter;

impl WindowsContextAdapter {
    pub fn new() -> Self {
        Self
    }
}

#[cfg(target_os = "windows")]
impl WindowsContextAdapter {
    fn get_window_title(hwnd: HWND) -> String {
        unsafe {
            let mut text: [u16; 512] = [0; 512];
            let len = GetWindowTextW(hwnd, &mut text);
            String::from_utf16_lossy(&text[..len as usize])
        }
    }

    fn get_process_name(process_id: u32) -> String {
        unsafe {
            let process_handle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, process_id);
            if let Ok(handle) = process_handle {
                let mut name: [u16; 512] = [0; 512];
                let len = K32GetModuleBaseNameW(handle, None, &mut name);
                let _ = windows::Win32::Foundation::CloseHandle(handle); // Clean up
                if len > 0 {
                    return String::from_utf16_lossy(&name[..len as usize]);
                }
            }
            "Unknown".to_string()
        }
    }
}

#[async_trait]
impl ContextPort for WindowsContextAdapter {
    async fn capture_screen(&self) -> Result<Vec<u8>> {
        // TODO: Implement GDI screen capture
        // For now returning empty to focus on metadata
        Ok(vec![])
    }

    #[cfg(target_os = "windows")]
    async fn get_active_window(&self) -> Result<WindowInfo> {
        unsafe {
            let hwnd = GetForegroundWindow();
            if hwnd.0 == 0 {
                return Err(synapse_core::error::Error::System("No active window".into()));
            }

            let mut process_id: u32 = 0;
            GetWindowThreadProcessId(hwnd, Some(&mut process_id));

            let mut rect = RECT::default();
            let _ = GetWindowRect(hwnd, &mut rect);

            Ok(WindowInfo {
                title: Self::get_window_title(hwnd),
                process_name: Self::get_process_name(process_id),
                is_visible: IsWindowVisible(hwnd).as_bool(),
                bounds: (rect.left, rect.top, (rect.right - rect.left) as u32, (rect.bottom - rect.top) as u32),
            })
        }
    }

    #[cfg(not(target_os = "windows"))]
    async fn get_active_window(&self) -> Result<WindowInfo> {
        Err(synapse_core::error::Error::System("Not implemented for this OS".into()))
    }

    #[cfg(target_os = "windows")]
    async fn get_running_processes(&self) -> Result<Vec<String>> {
         // TODO: Implement EnumProcesses
         Ok(vec![])
    }

    #[cfg(not(target_os = "windows"))]
    async fn get_running_processes(&self) -> Result<Vec<String>> {
        Ok(vec![])
    }

    async fn analyze_input_pattern(&self, _duration_ms: u64) -> Result<f32> {
        // Placeholder for input pattern analysis (e.g., mouse jitter, typing cadence)
        // Returns 1.0 (Human) for now.
        Ok(1.0)
    }
}

