#!/usr/bin/env python3
"""Minimal CRX3 packer. Requires openssl on PATH."""
import hashlib, io, os, struct, subprocess, sys, zipfile


def varint(n):
    out = b""
    while n > 0x7F:
        out += bytes([0x80 | (n & 0x7F)])
        n >>= 7
    out += bytes([n])
    return out


def pb_bytes(field, data):
    """Protobuf: length-delimited field."""
    return varint((field << 3) | 2) + varint(len(data)) + data


def make_zip(src_dir):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(src_dir):
            for f in files:
                path = os.path.join(root, f)
                arcname = os.path.relpath(path, src_dir)
                # Nix store files have epoch 0 timestamps; ZIP requires >= 1980
                info = zipfile.ZipInfo(arcname, date_time=(1980, 1, 1, 0, 0, 0))
                with open(path, "rb") as fh:
                    info.compress_type = zipfile.ZIP_DEFLATED
                    zf.writestr(info, fh.read())
    return buf.getvalue()


def main():
    ext_dir, key_pem, out_crx = sys.argv[1], sys.argv[2], sys.argv[3]

    # Read DER-encoded public key
    pub_der = subprocess.check_output(
        ["openssl", "rsa", "-in", key_pem, "-pubout", "-outform", "DER"],
        stderr=subprocess.DEVNULL,
    )

    # Extension ID = first 16 bytes of SHA-256 of public key, mapped to a-p
    crx_id = hashlib.sha256(pub_der).digest()[:16]

    # SignedData protobuf (field 1 = crx_id)
    signed_data = pb_bytes(1, crx_id)

    # ZIP the extension
    zip_data = make_zip(ext_dir)

    # Signature input: "CRX3 SignedData\x00" + uint32le(len(signed_data)) + signed_data + zip
    sig_input = (
        b"CRX3 SignedData\x00"
        + struct.pack("<I", len(signed_data))
        + signed_data
        + zip_data
    )

    # RSA-SHA256 signature
    proc = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", key_pem],
        input=sig_input,
        capture_output=True,
    )
    signature = proc.stdout

    # AsymmetricKeyProof (field 1 = public_key, field 2 = signature)
    proof = pb_bytes(1, pub_der) + pb_bytes(2, signature)

    # CrxFileHeader (field 2 = sha256_with_rsa proof, field 10000 = signed_header_data)
    header = pb_bytes(2, proof) + pb_bytes(10000, signed_data)

    # Write CRX3
    with open(out_crx, "wb") as f:
        f.write(b"Cr24")
        f.write(struct.pack("<I", 3))  # version
        f.write(struct.pack("<I", len(header)))
        f.write(header)
        f.write(zip_data)

    # Print extension ID for convenience
    ext_id = "".join(chr(ord("a") + b // 16) + chr(ord("a") + b % 16) for b in crx_id)
    print(ext_id)


if __name__ == "__main__":
    main()
