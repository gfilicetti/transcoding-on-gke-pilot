# transcoding-on-gke-pilot
Example implementation of video transcoding on GKE infrastructure

## Creating VMs

### Small VM
- 2 vCPUs (`ns-standard-2`)
- Region: us-east4
- 100GB attached persistent SSD disk (delete on VM delete)

```bash
gcloud compute instances create transcode-vm-small \
    --zone=us-east4-c \
    --machine-type=n2-standard-2 \
    --metadata=enable-oslogin=true \
    --create-disk=auto-delete=yes,boot=yes,device-name=transcode-vm-small,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240617,mode=rw,size=10,type=projects/transcoding-on-gke-pilot/zones/us-east4-c/diskTypes/pd-balanced \
    --create-disk=auto-delete=yes,device-name=ssd,mode=rw,name=transcode-vm-small-disk,size=100,type=projects/transcoding-on-gke-pilot/zones/us-east4-c/diskTypes/pd-ssd 
```

### Large VM (16 vCPU)
- 16 vCPUs (`ns-standard-16`)
- Region: us-east4
- 100GB attached persistent SSD disk (delete on VM delete)

```bash
gcloud compute instances create transcode-vm-large \
    --zone=us-east4-c \
    --machine-type=n2-standard-16 \
    --metadata=enable-oslogin=true \
    --create-disk=auto-delete=yes,boot=yes,device-name=transcode-vm-large,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240617,mode=rw,size=10,type=projects/transcoding-on-gke-pilot/zones/us-east4-c/diskTypes/pd-balanced \
    --create-disk=auto-delete=yes,device-name=ssd,mode=rw,name=transcode-vm-large-disk,size=100,type=projects/transcoding-on-gke-pilot/zones/us-east4-c/diskTypes/pd-ssd
```

## Creating More Disks

If you need to create even more SSD persistent data disks after you create your VMs you can do so with a command similar to:

```bash
gcloud compute disks create transcode-vm-xlarge-disk \
    --type=pd-ssd \
    --size=1000GB \
    --zone=us-east4-c
```

### Attach a New Disk to an Existing VM

To attach pre-existing disks to an existing VM, use this command:

```bash
gcloud compute instances attach-disk transcode-vm-large --disk transcode-vm-xlarge-disk --zone us-east4-c
```

## Preparing Disks
Run these commands from inside the VMs

### Format Disk
```bash
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-ssd
```

### Mount Disk
```bash
sudo mkdir -p /mnt/ssd
sudo mount -o discard,defaults /dev/disk/by-id/google-ssd /mnt/ssd
```

## ffmpeg Examples

- Overwrite output if it exists
- Don't show preample output
- Show benchmark times (we want the 'r' time that shows up at the end)

```bash
ffmpeg -y -i input.ts -c:v libx264 -b:v 20M -vf scale=1280:720 -threads 0 -x264-params threads=auto -benchmark output.mp4
```

### Running The Script

Our script will output only the time it took to run the transcode (in seconds).

```bash
transcode.sh -i input.ts -o output.mp4 [-p optional parameter string]
```
> **Note**: The default parameter string is: `-c:v libx264 -b:v 20M -vf scale=1280:720 -threads 0 -x264-params threads=auto`

## Example Source Material

You can use the files made available for the *Tears of Steel* movie as inputs to transcoding with ffmpeg.

Just go to the [download page](https://mango.blender.org/download) on the Tears of Steel site to download different versions of the file.

## Examples

Here are some examples for different formats, etc.

### Transcode to H.264

Command:
```bash
ffmpeg
    -y
    -xerror
    -err_detect explode
    -i pack-request-999999.mov
    -r 30000/1001
    -frames 12317
    -vf zscale=threads=1:f=lanczos:d=error_diffusion:primariesin=709:transferin=709:matrixin=709:primaries=709:matrix=709:transfer=709:range=tv:w=640:h=360,setsar=1
    -c:v libx264
    -pix_fmt yuv420p
    -preset:v veryslow
    -profile:v high
    -f h264
    -x264-params annexb=1:aud=1:nal-hrd=vbr:stitchable=1:force-cfr=1:colorprim=bt709:transfer=bt709:colormatrix=bt709:sar=1/1:open-gop=0:scenecut=0:bframes=3:crf=22:vbv-maxrate=1100:vbv-bufsize=4400:keyint=120:min-keyint=120:rc-lookahead=120:ref=4
    -an /tmp/tx1310421995/merged.h264.temp.pass-0
```

Params:
```
-threads 0 -xerror -r 30000/1001 -frames 12317 -vf zscale=threads=1:f=lanczos:d=error_diffusion:primariesin=709:transferin=709:matrixin=709:primaries=709:matrix=709:transfer=709:range=tv:w=640:h=360,setsar=1 -c:v libx264 -pix_fmt yuv420p -preset:v veryslow -profile:v high -f h264 -x264-params annexb=1:aud=1:nal-hrd=vbr:stitchable=1:force-cfr=1:colorprim=bt709:transfer=bt709:colormatrix=bt709:sar=1/1:open-gop=0:scenecut=0:bframes=3:crf=22:vbv-maxrate=1100:vbv-bufsize=4400:keyint=120:min-keyint=120:rc-lookahead=120:ref=4
```

### Transcode to H.265

Command: 
```bash
ffmpeg
    -y
    -xerror
    -err_detect explode
    -i pack-request-999999.mov
    -r 30000/1001
    -frames 12317
    -vf zscale=threads=1:f=lanczos:d=error_diffusion:primariesin=709:transferin=709:matrixin=709:primaries=709:matrix=709:transfer=709:range=tv:w=576:h=324,setsar=1
    -c:v libx265
    -pix_fmt yuv420p10le
    -preset:v medium
    -profile:v main10
    -f hevc
    -x265-params info=1:annexb=1:aud=1:repeat-headers=1:hrd=1:asm=avx512:sar=1:no-high-tier=1:open-gop=0:b-intra=1:weightb=1:crf=27:vbv-maxrate=650:vbv-bufsize=2600:keyint=120:min-keyint=120:rc-lookahead=120:colorprim=bt709:transfer=bt709:colormatrix=bt709
    -an /tmp/tx4162365502/merged.hevc.temp.pass-0
```

Params:
```
-threads 0 -xerror -c:v libx265 -r 30000/1001 -frames 12317 -vf zscale=threads=1:f=lanczos:d=error_diffusion:primariesin=709:transferin=709:matrixin=709:primaries=709:matrix=709:transfer=709:range=tv:w=576:h=324,setsar=1 -pix_fmt yuv420p10le -preset:v medium -profile:v main10 -f hevc -x265-params info=1:annexb=1:aud=1:repeat-headers=1:hrd=1:asm=avx512:sar=1:no-high-tier=1:open-gop=0:b-intra=1:weightb=1:crf=27:vbv-maxrate=650:vbv-bufsize=2600:keyint=120:min-keyint=120:rc-lookahead=120:colorprim=bt709:transfer=bt709:colormatrix=bt709
```

### Mezzanine File Characteristics

```bash
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'pack-request-999999.mov':
  Metadata:
    major_brand     : qt  
    minor_version   : 537199360
    compatible_brands: qt  
    creation_time   : 2024-06-24T20:56:35.000000Z
    encoder         : Dalet 11.9.9.7.405769
    encoder-eng     : Dalet 11.9.9.7.405769

  Duration: 00:06:50.98, start: 0.000000, bitrate: 207749 kb/s

  Stream #0:0[0x1](eng): Video: prores (HQ) (apch / 0x68637061), yuv422p10le(bt709, progressive), 1920x1080, 207748 kb/s, SAR 1:1 DAR 16:9, 29.97 fps, 29.97 tbr, 30k tbn (default)
    Metadata:
      creation_time   : 2024-06-24T20:56:35.000000Z
      handler_name    : VideoHandler
      vendor_id       : appl
      encoder         : Apple ProRes 422 HQ
      timecode        : 00:00:00;00
  Stream #0:1[0x2](eng): Data: none (tmcd / 0x64636D74) (default)
    Metadata:
      creation_time   : 2024-06-24T20:56:35.000000Z
      handler_name    : TimeCodeHandler
      timecode        : 00:00:00;00

Stream mapping:
  Stream #0:0 -> #0:0 (prores (native) -> hevc (libx265))
```

### Supported Formats

#### Codecs
- AVC Intra (MXF)
- J2K (MXF)
- ProRes (mov)

#### Bitrates
- Bitrates vary by upstream source 
    - Can be 135 mpbs for a 1080p source
    - Can be 750+ mbps for a UHD PQ master


