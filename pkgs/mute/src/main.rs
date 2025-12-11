
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "mute")]
#[command(about = "Mute/unmute the default input device")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    Mute,
    Unmute,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        None => {
            // Default behavior: toggle
            if let Err(e) = toggle_input() {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
        Some(Commands::Mute) => {
            if let Err(e) = mute_input() {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
        Some(Commands::Unmute) => {
            if let Err(e) = unmute_input() {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
    }
}

#[cfg(target_os = "macos")]
mod macos {
    use coreaudio_sys::*;
    use std::error::Error;
    use std::fmt;
    use std::mem;
    use std::ptr;

    #[derive(Debug)]
    pub struct AudioError(String);

    impl fmt::Display for AudioError {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            write!(f, "{}", self.0)
        }
    }

    impl Error for AudioError {}

    pub fn mute_input() -> Result<(), Box<dyn Error>> {
        set_input_mute(true)
    }

    pub fn unmute_input() -> Result<(), Box<dyn Error>> {
        set_input_mute(false)
    }

    pub fn toggle_input() -> Result<(), Box<dyn Error>> {
        let is_muted = get_input_mute_status()?;
        set_input_mute(!is_muted)
    }

    fn get_default_input_device() -> Result<AudioDeviceID, Box<dyn Error>> {
        let mut device_id: AudioDeviceID = 0;
        let mut property_size = mem::size_of::<AudioDeviceID>() as UInt32;

        let property_address = AudioObjectPropertyAddress {
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain,
        };

        let status = unsafe {
            AudioObjectGetPropertyData(
                kAudioObjectSystemObject,
                &property_address,
                0,
                ptr::null(),
                &mut property_size,
                &mut device_id as *mut _ as *mut std::ffi::c_void,
            )
        };

        if status != kAudioHardwareNoError as OSStatus {
            return Err(Box::new(AudioError(format!("Failed to get default input device: {}", status))));
        }

        if device_id == kAudioObjectUnknown {
            return Err(Box::new(AudioError("No input device found".to_string())));
        }

        Ok(device_id)
    }

    fn get_input_mute_status() -> Result<bool, Box<dyn Error>> {
        let device_id = get_default_input_device()?;

        let property_address = AudioObjectPropertyAddress {
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain,
        };

        // Check if mute property exists
        let has_property = unsafe {
            AudioObjectHasProperty(device_id, &property_address) != 0
        };

        if !has_property {
            return Err(Box::new(AudioError("Device does not support mute".to_string())));
        }

        let mut mute_value: UInt32 = 0;
        let mut property_size = mem::size_of::<UInt32>() as UInt32;

        let status = unsafe {
            AudioObjectGetPropertyData(
                device_id,
                &property_address,
                0,
                ptr::null(),
                &mut property_size,
                &mut mute_value as *mut _ as *mut std::ffi::c_void,
            )
        };

        if status != kAudioHardwareNoError as OSStatus {
            return Err(Box::new(AudioError(format!("Failed to get mute status: {}", status))));
        }

        Ok(mute_value != 0)
    }

    fn set_input_mute(mute: bool) -> Result<(), Box<dyn Error>> {
        let device_id = get_default_input_device()?;

        let property_address = AudioObjectPropertyAddress {
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain,
        };

        // Check if mute property exists
        let has_property = unsafe {
            AudioObjectHasProperty(device_id, &property_address) != 0
        };

        if !has_property {
            return Err(Box::new(AudioError("Device does not support mute".to_string())));
        }

        let mute_value: UInt32 = if mute { 1 } else { 0 };
        let property_size = mem::size_of::<UInt32>() as UInt32;

        let status = unsafe {
            AudioObjectSetPropertyData(
                device_id,
                &property_address,
                0,
                ptr::null(),
                property_size,
                &mute_value as *const _ as *const std::ffi::c_void,
            )
        };

        if status != kAudioHardwareNoError as OSStatus {
            return Err(Box::new(AudioError(format!("Failed to set mute status: {}", status))));
        }

        let status_msg = if mute { "🔇 Muted" } else { "🎤 Unmuted" };
        show_notification(status_msg);

        Ok(())
    }

    fn show_notification(message: &str) {
        let _ = std::process::Command::new("/opt/homebrew/bin/hs")
            .arg("-c")
            .arg(&format!("hs.alert.closeAll(); hs.alert.show('{}', 1.5)", message))
            .output();
    }
}

#[cfg(target_os = "linux")]
mod linux {
    use alsa::mixer::{Mixer, SelemChannelId, SelemId};
    use std::error::Error;
    use std::fmt;
    use std::process::Command;

    #[derive(Debug)]
    pub struct AudioError(String);

    impl fmt::Display for AudioError {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            write!(f, "{}", self.0)
        }
    }

    impl Error for AudioError {}

    pub fn mute_input() -> Result<(), Box<dyn Error>> {
        set_input_mute(true)
    }

    pub fn unmute_input() -> Result<(), Box<dyn Error>> {
        set_input_mute(false)
    }

    pub fn toggle_input() -> Result<(), Box<dyn Error>> {
        let is_muted = get_input_mute_status()?;
        set_input_mute(!is_muted)
    }

    fn get_input_mute_status() -> Result<bool, Box<dyn Error>> {
        // Try ALSA first
        if let Ok(status) = try_alsa_get_mute_status() {
            return Ok(status);
        }

        // Fallback: assume unmuted
        Ok(false)
    }

    fn set_input_mute(mute: bool) -> Result<(), Box<dyn Error>> {
        // Try ALSA first
        if try_alsa_mute(mute).is_ok() {
            return Ok(());
        }

        // Fall back to PulseAudio commands
        try_pulseaudio_mute(mute)
    }

    fn try_alsa_get_mute_status() -> Result<bool, Box<dyn Error>> {
        let mixer = Mixer::new("default", false)?;

        // Try common capture control names
        let control_names = ["Capture", "Mic", "Microphone", "Internal Mic"];

        for name in &control_names {
            let selem_id = SelemId::new(name, 0);
            if let Some(selem) = mixer.find_selem(&selem_id) {
                if selem.has_capture_switch() {
                    return Ok(selem.get_capture_switch(SelemChannelId::mono())? == 0);
                }
            }
        }

        Err(Box::new(AudioError("No capture control found".to_string())))
    }

    fn try_alsa_mute(mute: bool) -> Result<(), Box<dyn Error>> {
        let mixer = Mixer::new("default", false)?;

        // Try common capture control names
        let control_names = ["Capture", "Mic", "Microphone", "Internal Mic"];

        for name in &control_names {
            let selem_id = SelemId::new(name, 0);
            if let Some(selem) = mixer.find_selem(&selem_id) {
                if selem.has_capture_switch() {
                    // ALSA switch: 1 = enabled, 0 = disabled (muted)
                    // So we invert the mute boolean
                    let value: i32 = if mute { 0 } else { 1 };
                    selem.set_capture_switch_all(value)?;

                    let status = if mute { "🔇 Muted" } else { "🎤 Unmuted" };
                    show_notification(status);
                    return Ok(());
                }
            }
        }

        Err(Box::new(AudioError("No capture control found".to_string())))
    }

    fn try_pulseaudio_mute(mute: bool) -> Result<(), Box<dyn Error>> {
        let mute_arg = if mute { "1" } else { "0" };

        let output = Command::new("pactl")
            .args(&["set-source-mute", "@DEFAULT_SOURCE@", mute_arg])
            .output()?;

        if !output.status.success() {
            return Err(Box::new(AudioError(
                String::from_utf8_lossy(&output.stderr).to_string()
            )));
        }

        let status = if mute { "🔇 Muted" } else { "🎤 Unmuted" };
        show_notification(status);

        Ok(())
    }

    fn show_notification(message: &str) {
        let _ = Command::new("notify-send")
            .args(&["Audio Control", message])
            .output();
    }
}

#[cfg(target_os = "macos")]
use macos::{mute_input, unmute_input, toggle_input};

#[cfg(target_os = "linux")]
use linux::{mute_input, unmute_input, toggle_input};