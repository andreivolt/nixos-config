# Record system audio via PipeWire
# Usage: sysrec [output.flac]

output="${1:-recording-$(date +%Y%m%d-%H%M%S).flac}"

sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep -oP 'node.name = "\K[^"]+')

echo "Recording from: $sink"
echo "Output: $output"
echo "Press Ctrl+C to stop..."

pw-record --format s24 --target "$sink.monitor" "$output"
