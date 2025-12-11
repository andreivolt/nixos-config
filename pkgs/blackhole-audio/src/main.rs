use anyhow::{anyhow, Result};
use clap::Parser;
use core_foundation::array::CFArray;
use core_foundation::base::{CFType, TCFType};
use core_foundation::dictionary::CFDictionary;
use core_foundation::number::CFNumber;
use core_foundation::string::CFString;
use coreaudio_sys::*;
use rodio::{Decoder, OutputStream, Sink};
use signal_hook::{consts::{SIGINT, SIGTERM}, iterator::Signals};
use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;
use std::mem;
use std::ptr;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Arc;
use std::thread;

#[derive(Parser)]
#[command(author, about = "Route audio through BlackHole", long_about = None)]
struct Cli {
    /// Use BH-Monitor for output (speakers + BlackHole)
    #[arg(short, long)]
    monitor: bool,
    /// Audio file to play
    audiofile: Option<String>,
}

#[derive(Debug)]
struct AudioDevice {
    id: u32,
    #[allow(dead_code)]
    uid: String,
    name: String,
    is_output: bool,
    transport_type: String,
}

fn get_string_property(device_id: AudioDeviceID, selector: AudioObjectPropertySelector) -> Result<String> {
    let property_address = AudioObjectPropertyAddress {
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster,
    };

    unsafe {
        let mut property_size: u32 = 0;
        let status = AudioObjectGetPropertyDataSize(device_id, &property_address, 0, ptr::null(), &mut property_size);
        if status != 0 { return Err(anyhow!("Property size error: {}", status)); }

        let mut string_ref = ptr::null_mut();
        let status = AudioObjectGetPropertyData(device_id, &property_address, 0, ptr::null(), &mut property_size, &mut string_ref as *mut _ as *mut _);
        if status != 0 { return Err(anyhow!("Property data error: {}", status)); }

        Ok(CFString::wrap_under_create_rule(string_ref).to_string())
    }
}

fn get_transport_type(device_id: AudioDeviceID) -> Result<String> {
    unsafe {
        let property_address = AudioObjectPropertyAddress {
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster,
        };

        let mut property_size: u32 = mem::size_of::<u32>() as u32;
        let mut transport_type: u32 = 0;

        let status = AudioObjectGetPropertyData(
            device_id,
            &property_address,
            0,
            ptr::null(),
            &mut property_size,
            &mut transport_type as *mut _ as *mut _,
        );

        if status != 0 {
            return Err(anyhow!("Failed to get transport type: {}", status));
        }

        #[allow(non_upper_case_globals)]
        let transport_str = match transport_type {
            kAudioDeviceTransportTypeBuiltIn => "builtin",
            kAudioDeviceTransportTypeVirtual => "virtual",
            kAudioDeviceTransportTypeUSB => "usb",
            kAudioDeviceTransportTypePCI => "pci",
            kAudioDeviceTransportTypeFireWire => "firewire",
            kAudioDeviceTransportTypeBluetooth => "bluetooth",
            kAudioDeviceTransportTypeBluetoothLE => "bluetooth-le",
            kAudioDeviceTransportTypeHDMI => "hdmi",
            kAudioDeviceTransportTypeDisplayPort => "displayport",
            kAudioDeviceTransportTypeAirPlay => "airplay",
            kAudioDeviceTransportTypeAVB => "avb",
            kAudioDeviceTransportTypeThunderbolt => "thunderbolt",
            _ => "unknown",
        };

        Ok(transport_str.to_string())
    }
}

fn is_output_device(device_id: AudioDeviceID) -> Result<bool> {
    unsafe {
        let property_address = AudioObjectPropertyAddress {
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster,
        };

        let mut property_size: u32 = 0;
        let status = AudioObjectGetPropertyDataSize(
            device_id,
            &property_address,
            0,
            ptr::null(),
            &mut property_size,
        );

        if status != 0 {
            return Ok(false);
        }

        Ok(property_size > 0)
    }
}

fn list_devices() -> Result<Vec<AudioDevice>> {
    unsafe {
        let property_address = AudioObjectPropertyAddress {
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster,
        };

        let mut property_size: u32 = 0;
        let status = AudioObjectGetPropertyDataSize(
            kAudioObjectSystemObject,
            &property_address,
            0,
            ptr::null(),
            &mut property_size,
        );

        if status != 0 {
            return Err(anyhow!("Failed to get device list size: {}", status));
        }

        let device_count = property_size / mem::size_of::<AudioDeviceID>() as u32;
        let mut device_ids = vec![0 as AudioDeviceID; device_count as usize];

        let status = AudioObjectGetPropertyData(
            kAudioObjectSystemObject,
            &property_address,
            0,
            ptr::null(),
            &mut property_size,
            device_ids.as_mut_ptr() as *mut _,
        );

        if status != 0 {
            return Err(anyhow!("Failed to get device list: {}", status));
        }

        let mut devices = Vec::new();

        for &device_id in &device_ids {
            if let (Ok(name), Ok(uid), Ok(transport_type), Ok(is_output)) = (
                get_string_property(device_id, kAudioDevicePropertyDeviceNameCFString),
                get_string_property(device_id, kAudioDevicePropertyDeviceUID),
                get_transport_type(device_id),
                is_output_device(device_id),
            ) {
                devices.push(AudioDevice {
                    id: device_id,
                    uid,
                    name,
                    is_output,
                    transport_type,
                });
            }
        }

        Ok(devices)
    }
}

fn find_device_by_name(name: &str) -> Result<Option<AudioDevice>> {
    let devices = list_devices()?;
    Ok(devices.into_iter().find(|d| d.name == name))
}

fn create_aggregate_device(name: &str, main_device_id: AudioDeviceID, sub_device_id: AudioDeviceID) -> Result<AudioDeviceID> {
    let main_uid = get_string_property(main_device_id, kAudioDevicePropertyDeviceUID)?;
    let sub_uid = get_string_property(sub_device_id, kAudioDevicePropertyDeviceUID)?;

    let _device_uids = CFArray::from_CFTypes(&[
        CFString::new(&main_uid),
        CFString::new(&sub_uid),
    ]);

    let subdevice_list = vec![
        {
            let mut main_subdevice = HashMap::new();
            main_subdevice.insert("uid", CFString::new(&main_uid).as_CFType());
            main_subdevice.insert("drift", CFNumber::from(0i32).as_CFType());
            main_subdevice
        },
        {
            let mut sub_subdevice = HashMap::new();
            sub_subdevice.insert("uid", CFString::new(&sub_uid).as_CFType());
            sub_subdevice.insert("drift", CFNumber::from(1i32).as_CFType());
            sub_subdevice
        }
    ];

    let subdevice_dicts: Vec<CFType> = subdevice_list
        .into_iter()
        .map(|config| {
            let pairs: Vec<(CFString, CFType)> = config.into_iter()
                .map(|(k, v)| (CFString::new(k), v))
                .collect();
            CFDictionary::from_CFType_pairs(&pairs).as_CFType()
        })
        .collect();

    let subdevice_array = CFArray::from_CFTypes(&subdevice_dicts);

    let mut description = HashMap::new();
    description.insert("name", CFString::new(name).as_CFType());
    description.insert("uid", CFString::new(&format!("{}-aggregate", name)).as_CFType());
    description.insert("subdevices", subdevice_array.as_CFType());
    description.insert("master", CFString::new(&main_uid).as_CFType());
    description.insert("stacked", CFNumber::from(1i32).as_CFType());

    let pairs: Vec<(CFString, CFType)> = description.into_iter()
        .map(|(k, v)| (CFString::new(k), v))
        .collect();
    let description_dict = CFDictionary::from_CFType_pairs(&pairs);

    unsafe {
        let mut aggregate_id: AudioDeviceID = 0;
        let status = AudioHardwareCreateAggregateDevice(description_dict.as_concrete_TypeRef() as *const _ as *const _, &mut aggregate_id);

        if status != 0 {
            return Err(anyhow!("Failed to create aggregate device: {}", status));
        }

        Ok(aggregate_id)
    }
}

fn set_default_output_device(device_id: AudioDeviceID) -> Result<()> {
    let property_address = AudioObjectPropertyAddress {
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster,
    };

    unsafe {
        let status = AudioObjectSetPropertyData(
            kAudioObjectSystemObject,
            &property_address,
            0,
            ptr::null(),
            mem::size_of::<AudioDeviceID>() as u32,
            &device_id as *const _ as *const _,
        );

        if status != 0 {
            return Err(anyhow!("Failed to set default output device: {}", status));
        }
    }

    Ok(())
}

fn get_default_output_device() -> Result<AudioDeviceID> {
    let property_address = AudioObjectPropertyAddress {
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster,
    };

    unsafe {
        let mut device_id: AudioDeviceID = 0;
        let mut property_size = mem::size_of::<AudioDeviceID>() as u32;

        let status = AudioObjectGetPropertyData(
            kAudioObjectSystemObject,
            &property_address,
            0,
            ptr::null(),
            &mut property_size,
            &mut device_id as *mut _ as *mut _,
        );

        if status != 0 {
            return Err(anyhow!("Failed to get default output device: {}", status));
        }

        Ok(device_id)
    }
}

fn ensure_bh_monitor_exists() -> Result<()> {
    let device_name = "BH-Monitor";

    if find_device_by_name(device_name)?.is_none() {
        println!("Creating {} aggregate device...", device_name);

        let devices = list_devices()?;
        let main_device = devices
            .iter()
            .find(|d| d.transport_type == "builtin" && d.is_output)
            .ok_or_else(|| anyhow!("No builtin output device found"))?;

        let blackhole_device = devices
            .iter()
            .find(|d| d.name == "BlackHole 2ch" && d.is_output)
            .ok_or_else(|| anyhow!("BlackHole 2ch device not found"))?;

        create_aggregate_device(device_name, main_device.id, blackhole_device.id)?;
        println!("{} created successfully", device_name);

        std::thread::sleep(std::time::Duration::from_millis(500));
    }
    Ok(())
}

fn play_audio(use_monitor: bool, audiofile: Option<String>) -> Result<()> {
    let target_device = if use_monitor {
        ensure_bh_monitor_exists()?;
        "BH-Monitor"
    } else {
        "BlackHole 2ch"
    };

    let original_device_id = get_default_output_device()?;

    let mut target_device_info = None;
    for _ in 0..3 {
        target_device_info = find_device_by_name(target_device)?;
        if target_device_info.is_some() {
            break;
        }
        std::thread::sleep(std::time::Duration::from_millis(100));
    }

    let target_device_info = target_device_info
        .ok_or_else(|| anyhow!("Device '{}' not found", target_device))?;

    set_default_output_device(target_device_info.id)?;

    let restore_device = move || {
        let _ = set_default_output_device(original_device_id);
    };

    if let Some(file_path) = audiofile {
        let file = File::open(&file_path)?;
        let source = Decoder::new(BufReader::new(file))?;

        let (_stream, stream_handle) = OutputStream::try_default()?;
        let sink = Sink::try_new(&stream_handle)?;

        sink.append(source);
        sink.sleep_until_end();

        restore_device();
    } else {
        println!("Routing system audio through {}. Press Ctrl+C to stop.", target_device);

        let original_id = Arc::new(AtomicU32::new(original_device_id));

        let original_id_signals = original_id.clone();
        thread::spawn(move || {
            let mut signals = Signals::new(&[SIGINT, SIGTERM]).unwrap();
            for _ in signals.forever() {
                let id = original_id_signals.load(Ordering::Relaxed);
                let _ = set_default_output_device(id);
                std::process::exit(0);
            }
        });

        loop {
            std::thread::sleep(std::time::Duration::from_secs(1));
        }
    }

    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    play_audio(cli.monitor, cli.audiofile)?;
    Ok(())
}
