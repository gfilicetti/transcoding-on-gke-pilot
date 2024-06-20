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



