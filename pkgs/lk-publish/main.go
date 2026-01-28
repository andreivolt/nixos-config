// Minimal H264 publisher for LiveKit. Reads Annex B H264 from stdin,
// publishes to a LiveKit room via server-sdk-go.
package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/pion/webrtc/v3"
	"github.com/pion/webrtc/v3/pkg/media"
	"github.com/pion/webrtc/v3/pkg/media/h264reader"

	lksdk "github.com/livekit/server-sdk-go/v2"
)

var startCode = []byte{0x00, 0x00, 0x00, 0x01}

func isSliceNAL(t h264reader.NalUnitType) bool {
	switch t {
	case h264reader.NalUnitTypeCodedSliceDataPartitionA,
		h264reader.NalUnitTypeCodedSliceDataPartitionB,
		h264reader.NalUnitTypeCodedSliceDataPartitionC,
		h264reader.NalUnitTypeCodedSliceIdr,
		h264reader.NalUnitTypeCodedSliceNonIdr:
		return true
	}
	return false
}

func isFirstSliceOfFrame(data []byte) bool {
	return len(data) >= 2 && data[1]&0x80 != 0
}

func main() {
	url := flag.String("url", "", "LiveKit server URL")
	apiKey := flag.String("api-key", "", "API key")
	apiSecret := flag.String("api-secret", "", "API secret")
	room := flag.String("room", "", "Room name")
	identity := flag.String("identity", "publisher", "Participant identity")
	fps := flag.Float64("fps", 30, "Frame rate")
	flag.Parse()

	if *url == "" || *apiKey == "" || *apiSecret == "" || *room == "" {
		fmt.Fprintln(os.Stderr, "usage: lk-publish --url URL --api-key KEY --api-secret SECRET --room ROOM < h264_stream")
		os.Exit(1)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sig
		cancel()
	}()

	r := lksdk.NewRoom(lksdk.NewRoomCallback())
	err := r.Join(*url, lksdk.ConnectInfo{
		APIKey:              *apiKey,
		APISecret:           *apiSecret,
		RoomName:            *room,
		ParticipantIdentity: *identity,
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to join room: %v\n", err)
		os.Exit(1)
	}
	defer r.Disconnect()

	track, err := lksdk.NewLocalTrack(webrtc.RTPCodecCapability{
		MimeType:    webrtc.MimeTypeH264,
		ClockRate:   90000,
		SDPFmtpLine: "level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640029",
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create track: %v\n", err)
		os.Exit(1)
	}

	bound := make(chan struct{})
	var once sync.Once
	track.OnBind(func() { once.Do(func() { close(bound) }) })

	_, err = r.LocalParticipant.PublishTrack(track, &lksdk.TrackPublicationOptions{})
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to publish track: %v\n", err)
		os.Exit(1)
	}

	select {
	case <-bound:
	case <-ctx.Done():
		return
	}

	fmt.Fprintln(os.Stderr, "publishing H264 stream...")

	reader, err := h264reader.NewReader(os.Stdin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create h264 reader: %v\n", err)
		os.Exit(1)
	}

	defaultDur := time.Second / time.Duration(*fps)
	var lastSend time.Time

	var frameBuf []byte
	var hasSlice bool

	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		nal, err := reader.NextNAL()
		if err == io.EOF {
			return
		}
		if err != nil {
			fmt.Fprintf(os.Stderr, "h264 read error: %v\n", err)
			return
		}

		isSlice := isSliceNAL(nal.UnitType)

		if hasSlice && (!isSlice || (isSlice && isFirstSliceOfFrame(nal.Data))) {
			now := time.Now()
			dur := defaultDur
			if !lastSend.IsZero() {
				dur = now.Sub(lastSend)
			}
			lastSend = now

			if err := track.WriteSample(media.Sample{
				Data:     frameBuf,
				Duration: dur,
			}, nil); err != nil {
				fmt.Fprintf(os.Stderr, "write sample error: %v\n", err)
				return
			}
			frameBuf = frameBuf[:0]
			hasSlice = false
		}

		frameBuf = append(frameBuf, startCode...)
		frameBuf = append(frameBuf, nal.Data...)

		if isSlice {
			hasSlice = true
		}
	}
}
