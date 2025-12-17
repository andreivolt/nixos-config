use std::collections::BTreeMap;
use std::env;
use std::io::{self, BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;
use std::process;

// Simple bencode implementation
enum Bencode {
    String(Vec<u8>),
    Int(i64),
    List(Vec<Bencode>),
    Dict(BTreeMap<Vec<u8>, Bencode>),
}

fn encode_bencode(val: &Bencode) -> Vec<u8> {
    match val {
        Bencode::String(s) => {
            let mut out = format!("{}:", s.len()).into_bytes();
            out.extend(s);
            out
        }
        Bencode::Int(i) => format!("i{}e", i).into_bytes(),
        Bencode::List(items) => {
            let mut out = vec![b'l'];
            for item in items {
                out.extend(encode_bencode(item));
            }
            out.push(b'e');
            out
        }
        Bencode::Dict(map) => {
            let mut out = vec![b'd'];
            for (k, v) in map {
                out.extend(encode_bencode(&Bencode::String(k.clone())));
                out.extend(encode_bencode(v));
            }
            out.push(b'e');
            out
        }
    }
}

fn decode_bencode(reader: &mut BufReader<UnixStream>) -> io::Result<Bencode> {
    let buf = reader.fill_buf()?;
    if buf.is_empty() {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "unexpected eof"));
    }
    let byte = buf[0];
    reader.consume(1);

    match byte {
        b'i' => {
            let mut num_str = Vec::new();
            loop {
                let buf = reader.fill_buf()?;
                if buf.is_empty() {
                    return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "unexpected eof in int"));
                }
                let b = buf[0];
                reader.consume(1);
                if b == b'e' { break; }
                num_str.push(b);
            }
            let s = String::from_utf8_lossy(&num_str);
            Ok(Bencode::Int(s.parse().unwrap_or(0)))
        }
        b'l' => {
            let mut items = Vec::new();
            loop {
                let buf = reader.fill_buf()?;
                if buf.is_empty() {
                    return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "unexpected eof in list"));
                }
                if buf[0] == b'e' {
                    reader.consume(1);
                    break;
                }
                items.push(decode_bencode(reader)?);
            }
            Ok(Bencode::List(items))
        }
        b'd' => {
            let mut map = BTreeMap::new();
            loop {
                let buf = reader.fill_buf()?;
                if buf.is_empty() {
                    return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "unexpected eof in dict"));
                }
                if buf[0] == b'e' {
                    reader.consume(1);
                    break;
                }
                // Read key (must be string)
                let key = match decode_bencode(reader)? {
                    Bencode::String(s) => s,
                    _ => return Err(io::Error::new(io::ErrorKind::InvalidData, "dict key must be string")),
                };
                let val = decode_bencode(reader)?;
                map.insert(key, val);
            }
            Ok(Bencode::Dict(map))
        }
        b'0'..=b'9' => {
            let mut len_str = vec![byte];
            loop {
                let buf = reader.fill_buf()?;
                if buf.is_empty() {
                    return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "unexpected eof in string length"));
                }
                let b = buf[0];
                reader.consume(1);
                if b == b':' { break; }
                len_str.push(b);
            }
            let len: usize = String::from_utf8_lossy(&len_str).parse().unwrap_or(0);
            let mut data = vec![0u8; len];
            reader.read_exact(&mut data)?;
            Ok(Bencode::String(data))
        }
        _ => Err(io::Error::new(io::ErrorKind::InvalidData, format!("unexpected byte: {}", byte))),
    }
}

fn get_string(dict: &BTreeMap<Vec<u8>, Bencode>, key: &str) -> Option<String> {
    dict.get(key.as_bytes()).and_then(|v| match v {
        Bencode::String(s) => String::from_utf8(s.clone()).ok(),
        _ => None,
    })
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 3 {
        eprintln!("Usage: nrepl-cli <socket-path> <code>");
        eprintln!("Example: nrepl-cli ~/.local/share/monolith/monolith.sock '(+ 1 2)'");
        process::exit(1);
    }

    let socket_path = &args[1];
    let code = args[2..].join(" ");

    // Connect to Unix socket
    let stream = match UnixStream::connect(socket_path) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Failed to connect to {}: {}", socket_path, e);
            process::exit(1);
        }
    };

    // Clone for writing
    let mut write_stream = stream.try_clone().expect("Failed to clone stream");

    // Build nREPL eval request
    let mut request = BTreeMap::new();
    request.insert(b"op".to_vec(), Bencode::String(b"eval".to_vec()));
    request.insert(b"code".to_vec(), Bencode::String(code.as_bytes().to_vec()));

    let encoded = encode_bencode(&Bencode::Dict(request));

    // Send request
    if let Err(e) = write_stream.write_all(&encoded) {
        eprintln!("Failed to send: {}", e);
        process::exit(1);
    }

    // Read responses until we get status "done"
    let mut reader = BufReader::new(stream);
    loop {
        match decode_bencode(&mut reader) {
            Ok(Bencode::Dict(response)) => {
                // Print stdout
                if let Some(out) = get_string(&response, "out") {
                    print!("{}", out);
                }
                // Print stderr
                if let Some(err) = get_string(&response, "err") {
                    eprint!("{}", err);
                }
                // Print value
                if let Some(val) = get_string(&response, "value") {
                    println!("{}", val);
                }
                // Print exception
                if let Some(ex) = get_string(&response, "ex") {
                    eprintln!("Exception: {}", ex);
                }
                // Check if done
                if let Some(status) = response.get(b"status".as_slice()) {
                    if let Bencode::List(statuses) = status {
                        for s in statuses {
                            if let Bencode::String(st) = s {
                                if st == b"done" {
                                    return;
                                }
                            }
                        }
                    }
                }
            }
            Ok(_) => {
                eprintln!("Unexpected response type");
                process::exit(1);
            }
            Err(e) if e.kind() == io::ErrorKind::UnexpectedEof => break,
            Err(e) => {
                eprintln!("Read error: {}", e);
                process::exit(1);
            }
        }
    }
}
